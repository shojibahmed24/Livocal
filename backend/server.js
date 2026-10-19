import http from 'http';
import express from 'express';
import { WebSocketServer, WebSocket } from 'ws';
import dotenv from 'dotenv';
import cors from 'cors';
import { z } from 'zod';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import crypto from 'crypto';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { initializeApp, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { getStorage } from 'firebase-admin/storage';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config();

let firebaseApp = null;
let messagingService = null;
let firestoreDb = null;
let authService = null;
let storageService = null;

let serviceAccount = null;

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } catch (e) {
    console.error('[Firebase Admin] Error parsing FIREBASE_SERVICE_ACCOUNT env:', e.message);
  }
} else {
  const localKeyPath = path.join(__dirname, 'serviceAccountKey.json');
  if (fs.existsSync(localKeyPath)) {
    try {
      serviceAccount = JSON.parse(fs.readFileSync(localKeyPath, 'utf8'));
      console.log('[Firebase Admin] Successfully loaded credentials from local serviceAccountKey.json');
    } catch (e) {
      console.error('[Firebase Admin] Error reading local serviceAccountKey.json:', e.message);
    }
  } else {
    console.warn('[Firebase Admin] Warning: Neither FIREBASE_SERVICE_ACCOUNT env nor serviceAccountKey.json found.');
  }
}

// Whitelist of valid Gemini 3.5 Live Translation voices
const ALLOWED_VOICES = new Set(['Puck', 'Charon', 'Kore', 'Fenrir', 'Aoede']);

// Concurrent WebSocket session tracking per user UID & per IP (Rate Limiting)
const activeUserSessions = new Map();
const ipWsConnections = new Map();
const MAX_WS_PER_IP = 8;

if (serviceAccount) {
  try {
    firebaseApp = initializeApp({
      credential: cert(serviceAccount),
      projectId: serviceAccount.project_id || 'livocal24',
    });
    messagingService = getMessaging(firebaseApp);
    firestoreDb = getFirestore(firebaseApp);
    authService = getAuth(firebaseApp);
    storageService = getStorage(firebaseApp);
    console.log('[Firebase Admin] Successfully initialized with project:', serviceAccount.project_id);
  } catch (err) {
    console.error('[Firebase Admin] Error initializing:', err.message);
  }
}

const PORT = parseInt(process.env.PORT || '8080', 10);
const GEMINI_API_KEY = process.env.GEMINI_API_KEY?.trim() || '';
const DEFAULT_MODEL =
    process.env.GEMINI_LIVE_MODEL?.trim() || 'models/gemini-3.5-live-translate-preview';
const DEFAULT_VOICE = process.env.DEFAULT_VOICE?.trim() || 'Aoede';

const app = express();
app.set('trust proxy', 1); // Trust first-hop reverse proxy (Render / Cloud Run)
app.use(helmet({
  contentSecurityPolicy: false,
}));

// Admin Control Room Web Dashboard static files
app.use('/admin', express.static(path.join(__dirname, 'public/admin')));

// Secure CORS configuration: Restrict origins, allow mobile apps without Origin header
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map((o) => o.trim())
  : ['https://livocal.web.app', 'https://livocal.firebaseapp.com'];

app.use(cors({
  origin: (origin, callback) => {
    if (!origin) return callback(null, true);
    if (allowedOrigins.includes(origin) || process.env.NODE_ENV !== 'production') {
      return callback(null, true);
    }
    return callback(new Error('CORS policy: Access denied'));
  },
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));

app.use(express.json({ limit: '1mb' }));

// Input Validation Schemas with Zod
const CallNotifySchema = z.object({
  targetUserId: z.string().min(1, 'targetUserId is required').max(128),
  callId: z.string().min(1, 'callId is required').max(128),
});

const ChatMessageNotifySchema = z.object({
  receiverId: z.string().min(1, 'receiverId is required').max(128),
  messageId: z.string().min(1, 'messageId is required').max(128),
  messageContent: z.string().max(5000).optional(),
  authorId: z.string().max(128).optional(),
});

const MatchContactsSchema = z.object({
  phoneNumbers: z.array(z.string().min(1).max(32)).min(1, 'At least 1 phone number required').max(500),
});

const TranslateSchema = z.object({
  text: z.string().min(1, 'text is required').max(5000),
  targetLang: z.string().min(2, 'targetLang is required').max(16),
  sourceLang: z.string().max(16).optional(),
});

function validateBody(schema) {
  return (req, res, next) => {
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        error: 'Validation failed',
        details: parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`),
      });
    }
    req.body = parsed.data;
    next();
  };
}

// Rate limit: 300 requests per 15 min per IP on API endpoints
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests from this IP, please try again later.' },
});
app.use('/api/', apiLimiter);

// Specific rate limiter for push notification endpoints (prevent notification flooding)
// Per-user rate limiting using authenticated UID (prevents collateral blocking behind reverse proxy)
const pushLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30, // max 30 push notifications per minute per authenticated user
  keyGenerator: (req) => req.user?.uid || req.ip,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many push notification requests. Please slow down.' },
});

/**
 * Strict Zero-Trust Firebase ID Token Authentication Middleware.
 * No hardcoded secrets, no x-api-secret fallback, no environment bypass.
 */
async function authenticateRequest(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Missing or malformed Authorization header. Bearer Firebase ID token is required.',
    });
  }

  const token = authHeader.substring(7).trim();
  if (!token) {
    return res.status(401).json({ error: 'Empty Bearer token provided.' });
  }

  if (!authService) {
    console.error('[Auth] Cannot verify ID token: Firebase Auth service is not initialized.');
    return res.status(503).json({ error: 'Firebase Auth service is unavailable on the server.' });
  }

  try {
    const decoded = await authService.verifyIdToken(token);
    req.user = decoded; // { uid: string, phone_number?: string, email?: string, ... }
    return next();
  } catch (err) {
    console.warn('[Auth] Firebase ID Token invalid or expired:', err.message);
    return res.status(401).json({ error: 'Unauthorized: Invalid or expired Firebase ID token.' });
  }
}

// Health & Status endpoint (Sanitized)
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'Livocal Live Relay Gateway',
    uptime: Math.round(process.uptime()),
    timestamp: new Date().toISOString(),
  });
});

app.get('/', (req, res) => {
  res.json({
    service: 'Livocal Live Relay Gateway',
    version: '1.0.0',
    status: 'online',
    privacyPolicy: '/privacy-policy',
  });
});

// Hosted Public Privacy Policy Page for Google Play & App Store Compliance
app.get(['/privacy-policy', '/privacy'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Livocal - Privacy Policy | গোপনীয়তা নীতি</title>
  <style>
    :root {
      --primary: #00B386;
      --bg: #0b141a;
      --surface: #111b21;
      --card: #202c33;
      --text: #e9edef;
      --text-muted: #8696a0;
      --border: #222e35;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      line-height: 1.6;
      padding: 24px 16px;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 32px 24px;
    }
    .top-bar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
      flex-wrap: wrap;
      gap: 12px;
    }
    .lang-switch {
      display: flex;
      gap: 8px;
    }
    .lang-btn {
      background: var(--card);
      border: 1px solid var(--border);
      color: var(--text-muted);
      padding: 6px 14px;
      border-radius: 20px;
      font-size: 13px;
      cursor: pointer;
      font-weight: 600;
      transition: all 0.2s ease;
    }
    .lang-btn.active {
      background: var(--primary);
      color: #0b141a;
      border-color: var(--primary);
    }
    h1 { color: var(--primary); font-size: 28px; margin-bottom: 8px; }
    .updated { color: var(--text-muted); font-size: 14px; margin-bottom: 24px; }
    h2 { font-size: 20px; color: #00d7a7; margin-top: 28px; margin-bottom: 12px; border-bottom: 1px solid var(--border); padding-bottom: 6px; }
    p, li { font-size: 15px; color: var(--text); margin-bottom: 12px; }
    ul { padding-left: 20px; margin-bottom: 16px; }
    li { margin-bottom: 6px; }
    .badge {
      display: inline-block;
      background: rgba(0, 179, 134, 0.15);
      color: var(--primary);
      padding: 4px 10px;
      border-radius: 6px;
      font-size: 12px;
      font-weight: 600;
    }
    .card {
      background: var(--card);
      border-radius: 8px;
      padding: 16px;
      margin: 16px 0;
      border-left: 4px solid var(--primary);
    }
    a { color: var(--primary); text-decoration: none; }
    a:hover { text-decoration: underline; }
    footer { margin-top: 36px; padding-top: 16px; border-top: 1px solid var(--border); text-align: center; color: var(--text-muted); font-size: 13px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="top-bar">
      <div class="badge">Official Compliance Document</div>
      <div class="lang-switch">
        <button id="btn-en" class="lang-btn active" onclick="setLang('en')">English</button>
        <button id="btn-bn" class="lang-btn" onclick="setLang('bn')">বাংলা</button>
      </div>
    </div>

    <!-- English Content -->
    <div id="content-en">
      <h1>Livocal Privacy Policy</h1>
      <div class="updated">Last updated: October 2026 | Effective immediately</div>

      <p>Welcome to <strong>Livocal</strong> ("we", "our", or "the App"). We are committed to safeguarding your privacy and ensuring your communications remain secure, private, and confidential.</p>

      <h2>1. Zero-Retention Real-Time Voice Translation</h2>
      <div class="card">
        <p><strong>Strict Ephemeral Processing:</strong> During live cross-lingual calls, spoken audio is streamed ephemerally in-memory through our secure gateway to Google Gemini Live API for instant speech translation.</p>
        <ul>
          <li>Audio frames are processed entirely in volatile RAM and are <strong>never written to persistent disk storage</strong>.</li>
          <li>Voice data is <strong>never used for AI model training</strong> or profiling.</li>
          <li>When both participants speak the same language, the AI interpreter is automatically bypassed for 100% direct peer-to-peer WebRTC audio.</li>
        </ul>
      </div>

      <h2>2. Information We Collect and Process</h2>
      <ul>
        <li><strong>Account Credentials:</strong> Your verified phone number, processed via Firebase Authentication for secure SMS OTP login.</li>
        <li><strong>Profile Information:</strong> Optional display name, about text, and avatar photo stored securely in Cloud Firestore and Firebase Storage.</li>
        <li><strong>Contacts (Zero Harvesting):</strong> When you look up friends on Livocal, contact phone numbers are normalized and hashed on-device. We <em>do not</em> store, upload, or sell your personal address book.</li>
        <li><strong>Messages & Media:</strong> Messages and attachments are strictly scoped to the chat participants. Legacy media and ephemeral statuses are access-restricted.</li>
        <li><strong>Ephemeral Status Updates:</strong> Status stories are automatically purged and deleted after 24 hours.</li>
      </ul>

      <h2>3. Device Permissions & Purpose</h2>
      <ul>
        <li><strong>Microphone:</strong> Required to capture voice for live calls and audio voice notes.</li>
        <li><strong>Camera & Photo Library:</strong> Required for capturing and sharing photos, videos, and updating your profile picture.</li>
        <li><strong>Contacts:</strong> Optional permission used solely to identify which of your contacts are already registered on Livocal.</li>
        <li><strong>Notifications:</strong> Required to alert you of incoming voice calls and chat messages when the app is in the background or device is locked.</li>
      </ul>

      <h2>4. Security Standards</h2>
      <p>All network traffic between Livocal and backend services is encrypted using <strong>TLS 1.3</strong>. Peer-to-peer audio streams use <strong>DTLS-SRTP</strong> encryption. App security PINs are protected using hardware-backed keychains (Android Keystore / iOS Keychain).</p>

      <h2>5. Data Deletion and Account Removal</h2>
      <p>You have full ownership of your data. You may delete individual messages, clear chat histories, or permanently delete your account at any time via <strong>Settings &gt; Account &gt; Delete my account</strong>. Deleting your account irreversibly erases your profile, messages, attachments, and authentication records.</p>

      <h2>6. Contact Us</h2>
      <p>If you have any questions or privacy inquiries regarding Livocal, please contact our Data Protection Officer at:</p>
      <p><strong>Email:</strong> <a href="mailto:support@livocal.app">support@livocal.app</a></p>
    </div>

    <!-- Bengali Content -->
    <div id="content-bn" style="display: none;">
      <h1>Livocal গোপনীয়তা নীতি</h1>
      <div class="updated">সর্বশেষ আপডেট: অক্টোবর ২০২৬ | অবিলম্বে কার্যকর</div>

      <p><strong>Livocal</strong> ("আমরা", "আমাদের", বা "অ্যাপ") এ আপনাকে স্বাগতম। আমরা আপনার ব্যক্তিগত তথ্যের গোপনীয়তা রক্ষা করতে এবং আপনার প্রতিটি যোগাযোগ সম্পূর্ণরূপে সুরক্ষিত, ব্যক্তিগত এবং গোপনীয় রাখতে প্রতিশ্রুতিবদ্ধ।</p>

      <h2>১. ক্ষণস্থায়ী লাইভ ভয়েস অনুবাদ (জিরো-ডাটা রিটেনশন)</h2>
      <div class="card">
        <p><strong>সম্পূর্ণ ক্ষণস্থায়ী প্রসেসিং:</strong> লাইভ দ্বিভাষিক কলের সময়, ব্যবহারকারীর কথ্য অডিও তাৎক্ষণিক অনুবাদের জন্য Google Gemini Multimodal Live API-এর মাধ্যমে শুধুমাত্র ক্ষণস্থায়ী সুরক্ষিত র‍্যামে (RAM) প্রক্রিয়া করা হয়।</p>
        <ul>
          <li>কথোপকথনের অডিও ফ্রেম কখনোই <strong>কোনো স্থায়ী ডিস্ক স্টোরেজে সংরক্ষণ বা রেকর্ড করা হয় না</strong>।</li>
          <li>আপনার ভয়েস ডেটা কখনোই <strong>এআই মডেল প্রশিক্ষণ বা প্রোফাইলিং-এ ব্যবহার করা হয় না</strong>।</li>
          <li>কলের উভয় পক্ষ একই ভাষায় কথা বললে, এআই অনুবাদক স্বয়ংক্রিয়ভাবে বাইপাস হয়ে ১০০% সরাসরি P2P WebRTC সংযোগে চলে।</li>
        </ul>
      </div>

      <h2>২. যে সকল তথ্য আমরা সংগ্রহ ও প্রক্রিয়া করি</h2>
      <ul>
        <li><strong>অ্যাকাউন্ট প্রমাণীকরণ:</strong> আপনার যাচাইকৃত ফোন নম্বর, যা Firebase Authentication-এর মাধ্যমে সুরক্ষিত SMS OTP লগইনে ব্যবহৃত হয়।</li>
        <li><strong>প্রোফাইল তথ্য:</strong> আপনার ডিসপ্লে নাম, স্ট্যাটাস বায়ো এবং প্রোফাইল ছবি যা Cloud Firestore ও Firebase Storage-এ সুরক্ষিত থাকে।</li>
        <li><strong>কন্টাক্ট তালিকা (জিরো হার্ভেস্টিং):</strong> বন্ধুদের খুঁজে পেতে ফোনের কন্টাক্ট নম্বর ডিভাইসে হ্যাশ করে যাচাই করা হয়। আপনার সম্পূর্ণ অ্যাড্রেস বুক সার্ভারে আপলোড বা কারো কাছে বিক্রি করা হয় না।</li>
        <li><strong>মেসেজ ও মিডিয়া:</strong> চ্যাট মেসেজ এবং ফাইল শুধুমাত্র চ্যাট অংশগ্রহণকারীদের মধ্যেই সীমাবদ্ধ থাকে।</li>
        <li><strong>২৪-ঘণ্টার স্ট্যাটাস:</strong> যেকোনো স্ট্যাটাস পোস্ট প্রকাশের ২৪ ঘণ্টা পর স্বয়ংক্রিয়ভাবে স্থায়ীভাবে মুছে ফেলা হয়।</li>
      </ul>

      <h2>৩. ডিভাইসের অনুমতিসমূহ ও ব্যবহারের উদ্দেশ্য</h2>
      <ul>
        <li><strong>মাইক্রোফোন:</strong> লাইভ ভয়েস কল এবং অডিও ভয়েস নোট রেকর্ডিংয়ের জন্য প্রয়োজন।</li>
        <li><strong>ক্যামেরা ও গ্যালারি:</strong> ছবি তোলা, ভিডিও পাঠানো এবং প্রোফাইল ছবি পরিবর্তনের জন্য প্রয়োজন।</li>
        <li><strong>কন্টাক্টস:</strong> আপনার পরিচিতদের মধ্যে কারা Livocal ব্যবহার করছেন তা শনাক্ত করতে ঐচ্ছিক অনুমতি।</li>
        <li><strong>নোটিফিকেশন:</strong> অ্যাপ বন্ধ থাকলে বা স্ক্রিন লক থাকলে ইনকামিং কল ও বার্তার অ্যালার্ট প্রদানের জন্য প্রয়োজন।</li>
      </ul>

      <h2>৪. নিরাপত্তা মানদণ্ড</h2>
      <p>অ্যাপ এবং সার্ভারের মধ্যকার সমস্ত যোগাযোগ <strong>TLS 1.3</strong> দ্বারা এনক্রিপ্ট করা। সরাসরি অডিও স্ট্রিমগুলো <strong>DTLS-SRTP</strong> এনক্রিপশন ব্যবহার করে। অ্যাপ সিকিউরিটি পিন ডিভাইসের হার্ডওয়্যার-সমর্থিত Keystore/Keychain দ্বারা সুরক্ষিত।</p>

      <h2>৫. অ্যাকাউন্ট ও ডেটা অপসারণ</h2>
      <p>আপনার তথ্যের সম্পূর্ণ নিয়ন্ত্রণ আপনার হাতে। আপনি যেকোনো সময় নির্দিষ্ট বার্তা মুছতে, চ্যাট হিস্ট্রি পরিষ্কার করতে বা <strong>Settings &gt; Account &gt; Delete my account</strong> থেকে আপনার অ্যাকাউন্ট স্থায়ীভাবে মুছে ফেলতে পারেন।</p>

      <h2>৬. যোগাযোগ</h2>
      <p>গোপনীয়তা সংক্রান্ত যেকোনো জিজ্ঞাসা বা প্রশ্নের জন্য আমাদের ডেটা সুরক্ষা কর্মকর্তার সাথে যোগাযোগ করুন:</p>
      <p><strong>ইমেইল:</strong> <a href="mailto:support@livocal.app">support@livocal.app</a></p>
    </div>

    <footer>
      &copy; 2026 Livocal. All rights reserved. সুরক্ষিত বৈশ্বিক যোগাযোগের জন্য নিবেদিত।
    </footer>
  </div>

  <script>
    function setLang(lang) {
      document.getElementById('content-en').style.display = lang === 'en' ? 'block' : 'none';
      document.getElementById('content-bn').style.display = lang === 'bn' ? 'block' : 'none';
      document.getElementById('btn-en').className = 'lang-btn ' + (lang === 'en' ? 'active' : '');
      document.getElementById('btn-bn').className = 'lang-btn ' + (lang === 'bn' ? 'active' : '');
    }
  </script>
</body>
</html>`);
});

// Send Full-Screen Incoming Call Wakeup Push via FCM
// Anti-Phishing: Enforces callerId = req.user.uid and pulls verified name/phone from Firestore
app.post(
  '/api/call/notify-incoming',
  authenticateRequest,
  pushLimiter,
  validateBody(CallNotifySchema),
  async (req, res) => {
    if (!firebaseApp || !messagingService) {
      return res.status(503).json({ error: 'Firebase Admin not initialized on server' });
    }

    const { targetUserId, callId } = req.body;

    const callerUid = req.user.uid;
    if (targetUserId === callerUid) {
      return res.status(400).json({ error: 'Cannot send call notification to oneself' });
    }

    try {
      // 0. Anti-Spam Relationship Check: Verify valid, active call session in Firestore (Fail-Closed)
      if (!firestoreDb) {
        return res.status(503).json({ error: 'Firestore database service is currently unavailable' });
      }
      const callDoc = await firestoreDb.collection('calls').doc(String(callId)).get();
      if (!callDoc.exists) {
        return res.status(403).json({ error: 'Forbidden: No active call record found for callId' });
      }
      const callData = callDoc.data();
      if (callData.callerId !== callerUid || callData.calleeId !== targetUserId) {
        return res.status(403).json({ error: 'Forbidden: Caller/callee mismatch with call session' });
      }

      // 1. Authoritative caller identification: Lock caller to req.user.uid
      let verifiedCallerName = 'Livocal User';
      let verifiedCallerNumber = req.user.phone_number || '';

      if (firestoreDb) {
        try {
          const callerDoc = await firestoreDb.collection('users').doc(callerUid).get();
          if (callerDoc.exists) {
            const data = callerDoc.data();
            if (data.name && typeof data.name === 'string' && data.name.trim().length > 0) {
              verifiedCallerName = data.name.trim();
            }
            if (data.phone && data.phone.formattedNumber) {
              verifiedCallerNumber = data.phone.formattedNumber;
            } else if (data.phone && data.phone.number) {
              verifiedCallerNumber = `${data.phone.code || ''}${data.phone.number}`;
            }
          }
        } catch (profileErr) {
          console.warn(`[CallNotify] Could not fetch caller profile for ${callerUid}:`, profileErr.message);
        }
      }

      // 2. Authoritative target lookup: Server fetches recipient's FCM token from fcmTokens collection
      let token = null;
      if (firestoreDb) {
        const tokenDoc = await firestoreDb.collection('fcmTokens').doc(targetUserId).get();
        if (tokenDoc.exists) {
          token = tokenDoc.data().token;
        }
      }

      if (!token) {
        return res.status(404).json({ error: 'Target user has no registered FCM push token' });
      }

      // High Priority Data Message for waking up Android / CallKit
      const message = {
        token,
        data: {
          type: 'INCOMING_CALL',
          callId: String(callId),
          callerId: String(callerUid),
          callerName: String(verifiedCallerName),
          callerNumber: String(verifiedCallerNumber),
          timestamp: String(Date.now()),
        },
        android: {
          priority: 'high',
        },
      };

      const response = await messagingService.send(message);
      res.json({ success: true, messageId: response });
    } catch (err) {
      console.error('FCM Call Notify Send Error:', err.message);
      res.status(500).json({ error: 'Failed to send incoming call notification' });
    }
  }
);

// Send Chat Message Push via FCM
// Anti-Impersonation: Enforces authorId = req.user.uid and pulls verified name/avatar from Firestore
app.post(
  '/api/notify/chat-message',
  authenticateRequest,
  pushLimiter,
  validateBody(ChatMessageNotifySchema),
  async (req, res) => {
    if (!firebaseApp || !messagingService) {
      return res.status(503).json({ error: 'Firebase Admin not initialized on server' });
    }

    const { receiverId, messageContent, messageId, authorId } = req.body;

    const callerUid = req.user.uid;
    if (authorId && authorId !== callerUid) {
      return res.status(403).json({ error: 'Forbidden: Cannot send push notifications impersonating another user' });
    }

    try {
      // 0. Anti-Spam Relationship Check: Verify verifiable message in Firestore sent by callerUid (Fail-Closed)
      if (!firestoreDb) {
        return res.status(503).json({ error: 'Firestore database service is currently unavailable' });
      }
      const msgDoc = await firestoreDb
        .collection('chats')
        .doc(receiverId)
        .collection('messages')
        .doc(String(messageId))
        .get();
      if (!msgDoc.exists) {
        return res.status(403).json({ error: 'Forbidden: No verifiable message found in recipient inbox' });
      }
      const msgData = msgDoc.data();
      if (msgData.senderId !== callerUid) {
        return res.status(403).json({ error: 'Forbidden: Sender identity does not match message record' });
      }

      // 1. Authoritative author identification
      let verifiedAuthorName = 'Livocal User';
      let verifiedAuthorAvatar = '';

      if (firestoreDb) {
        try {
          const authorDoc = await firestoreDb.collection('users').doc(callerUid).get();
          if (authorDoc.exists) {
            const data = authorDoc.data();
            if (data.name && typeof data.name === 'string' && data.name.trim().length > 0) {
              verifiedAuthorName = data.name.trim();
            }
            if (data.avatarUrl && typeof data.avatarUrl === 'string') {
              verifiedAuthorAvatar = data.avatarUrl;
            }
          }
        } catch (authorErr) {
          console.warn(`[ChatNotify] Could not fetch author profile for ${callerUid}:`, authorErr.message);
        }
      }

      // 2. Authoritative target lookup: Server fetches recipient's FCM token from fcmTokens collection
      let targetToken = null;
      if (firestoreDb) {
        const doc = await firestoreDb.collection('fcmTokens').doc(receiverId).get();
        if (doc.exists) {
          targetToken = doc.data().token;
        }
      }

      if (!targetToken) {
        return res.status(404).json({ error: 'Recipient has no registered FCM push token' });
      }

      const payload = {
        token: targetToken,
        notification: {
          title: verifiedAuthorName,
          body: String(messageContent || 'Sent a message').substring(0, 500),
          imageUrl: verifiedAuthorAvatar || undefined,
        },
        data: {
          type: 'CHAT_MESSAGE',
          messageId: String(messageId),
          authorName: String(verifiedAuthorName),
          authorId: String(callerUid),
          authorAvatar: String(verifiedAuthorAvatar),
        },
        android: {
          priority: 'high',
        },
      };

      const result = await messagingService.send(payload);
      res.json({ success: true, messageId: result });
    } catch (err) {
      console.error('Chat FCM Error:', err.message);
      res.status(500).json({ error: 'Failed to send chat notification' });
    }
  }
);

// Secure ICE Servers endpoint (Provides STUN / TURN servers with Ephemeral HMAC-SHA1 support)
app.get(['/api/webrtc/ice-servers', '/api/turn-credentials'], authenticateRequest, (req, res) => {
  const iceServers = [
    { urls: 'stun:stun.l.google.com:19302' },
    { urls: 'stun:stun1.l.google.com:19302' },
    { urls: 'stun:stun2.l.google.com:19302' },
  ];

  if (process.env.TURN_URL && process.env.TURN_SECRET) {
    // RFC 5766 / Coturn REST API Ephemeral Time-Limited TURN Credentials (HMAC-SHA1, 2-hour TTL)
    const ttlSeconds = parseInt(process.env.TURN_TTL_SECONDS || '7200', 10);
    const expiry = Math.floor(Date.now() / 1000) + ttlSeconds;
    const username = `${expiry}:${req.user.uid}`;
    const hmac = crypto.createHmac('sha1', process.env.TURN_SECRET);
    hmac.update(username);
    const credential = hmac.digest('base64');

    const turnUrls = process.env.TURN_URL.includes(',')
      ? process.env.TURN_URL.split(',').map((u) => u.trim()).filter((u) => u.length > 0)
      : process.env.TURN_URL.trim();

    iceServers.push({
      urls: turnUrls,
      username,
      credential,
    });
  } else if (process.env.TURN_URL && process.env.TURN_USERNAME && process.env.TURN_CREDENTIAL) {
    const turnUrls = process.env.TURN_URL.includes(',')
      ? process.env.TURN_URL.split(',').map((u) => u.trim()).filter((u) => u.length > 0)
      : process.env.TURN_URL.trim();

    iceServers.push({
      urls: turnUrls,
      username: process.env.TURN_USERNAME.trim(),
      credential: process.env.TURN_CREDENTIAL.trim(),
    });
  }
  res.json({ iceServers });
});

// ==========================================
// SaaS Freelancer Wallet & Trial Management
// ==========================================

// Initializes user wallet with 14-day 20-min trial if device is clean, or returns existing wallet
app.post('/api/wallet/init-or-get', authenticateRequest, async (req, res) => {
  const userId = req.user.uid;
  const { deviceId, phone } = req.body || {};

  if (!firestoreDb) {
    return res.status(503).json({ error: 'Firestore database service is currently unavailable' });
  }

  try {
    const walletDocRef = firestoreDb.collection('users').doc(userId).collection('wallet').doc('current');
    const walletSnap = await walletDocRef.get();

    if (walletSnap.exists) {
      return res.json({ success: true, wallet: walletSnap.data() });
    }

    // New wallet required: Check hardware device fingerprint to prevent trial fraud
    let grantTrial = true;
    const cleanDeviceId = deviceId && String(deviceId).trim();

    if (cleanDeviceId) {
      const fingerprintRef = firestoreDb.collection('device_fingerprints').doc(cleanDeviceId);
      const fingerprintSnap = await fingerprintRef.get();

      if (fingerprintSnap.exists) {
        // Device has already claimed trial on this or another phone number
        grantTrial = false;
        console.log(`[SaaS Billing] Device ${cleanDeviceId} already claimed trial. Denying trial minutes for uid ${userId}.`);
      } else {
        // Mark device fingerprint as claimed
        await fingerprintRef.set({
          firstUid: userId,
          firstPhone: phone || req.user.phone_number || '',
          trialGrantedAt: new Date().toISOString(),
          isBlacklisted: false,
        });
      }
    }

    const now = new Date();
    const trialDays = 14;
    const trialMinutes = grantTrial ? 20 : 0;
    const expiresAt = new Date(now.getTime() + (grantTrial ? trialDays * 86400000 : 0));

    const newWallet = {
      balanceMinutes: 0,
      trialMinutes,
      trialActive: grantTrial,
      trialExpiresAt: expiresAt.toISOString(),
      totalMinutesUsed: 0,
      totalMinutesPurchased: 0,
      currency: 'BDT',
      createdAt: now.toISOString(),
      updatedAt: now.toISOString(),
    };

    await walletDocRef.set(newWallet);
    console.log(`[SaaS Billing] Initialized wallet for uid ${userId}: grantTrial=${grantTrial}, trialMinutes=${trialMinutes}`);

    return res.json({ success: true, wallet: newWallet });
  } catch (err) {
    console.error('[SaaS Billing] Error initializing wallet:', err.message);
    return res.status(500).json({ error: 'Failed to initialize wallet', message: err.message });
  }
});

// Retrieves current wallet balance
app.get('/api/wallet/balance', authenticateRequest, async (req, res) => {
  const userId = req.user.uid;

  if (!firestoreDb) {
    return res.status(503).json({ error: 'Firestore database service is currently unavailable' });
  }

  try {
    const walletSnap = await firestoreDb.collection('users').doc(userId).collection('wallet').doc('current').get();

    if (!walletSnap.exists) {
      return res.status(404).json({ error: 'Wallet not found' });
    }

    return res.json({ success: true, wallet: walletSnap.data() });
  } catch (err) {
    console.error('[SaaS Billing] Error fetching wallet balance:', err.message);
    return res.status(500).json({ error: 'Failed to fetch wallet balance', message: err.message });
  }
});

// In-call 60s Heartbeat Minute Metering endpoint (Authoritative atomic transaction)
app.post('/api/wallet/deduct-minute', authenticateRequest, async (req, res) => {
  const callerUid = req.user.uid;
  const { callId, callerId, calleeId, isTranslatedCall, durationSeconds, minuteIndex } = req.body || {};

  // Security: only authenticated caller can deduct from their own wallet
  if (callerId && callerId !== callerUid) {
    return res.status(403).json({ error: 'Forbidden: Caller ID mismatch' });
  }

  // Free local call bypass: Same-language or non-translated calls are 100% free!
  if (!isTranslatedCall) {
    return res.json({
      success: true,
      deducted: 0,
      isTranslatedCall: false,
      remainingMinutes: null,
      message: 'FREE_LOCAL_CALL',
    });
  }

  if (!firestoreDb) {
    return res.status(503).json({ error: 'Firestore database service is currently unavailable' });
  }

  try {
    const walletRef = firestoreDb.collection('users').doc(callerUid).collection('wallet').doc('current');

    const result = await firestoreDb.runTransaction(async (t) => {
      const snap = await t.get(walletRef);
      if (!snap.exists) {
        return { status: 404, error: 'Wallet not found' };
      }

      const data = snap.data();
      const now = new Date();
      const trialActive = data.trialActive && (!data.trialExpiresAt || new Date(data.trialExpiresAt) > now);
      const usableTrial = trialActive ? (data.trialMinutes || 0) : 0;
      const usableBalance = data.balanceMinutes || 0;
      const totalEffective = usableTrial + usableBalance;

      if (totalEffective <= 0) {
        return {
          status: 402,
          success: false,
          exhausted: true,
          remainingMinutes: 0,
          message: 'Minutes exhausted. Call disconnected.',
        };
      }

      let newTrial = data.trialMinutes || 0;
      let newBalance = data.balanceMinutes || 0;

      // Deduct from trial minutes first; if depleted, deduct from purchased balance
      if (trialActive && newTrial > 0) {
        newTrial -= 1;
      } else if (newBalance > 0) {
        newBalance -= 1;
      }

      const newTotalUsed = (data.totalMinutesUsed || 0) + 1;
      const remainingMinutes = (trialActive ? newTrial : 0) + newBalance;

      t.update(walletRef, {
        trialMinutes: newTrial,
        balanceMinutes: newBalance,
        totalMinutesUsed: newTotalUsed,
        updatedAt: now.toISOString(),
      });

      // Audit ledger record in call_billing_records
      const billingRef = firestoreDb.collection('call_billing_records').doc();
      const geminiCostUsd = 0.035; // Gemini 3.5 Live audio cost per minute (~$0.035)
      const retailBdt = 20.0;     // Freelancer retail price per minute (~৳20)
      const usdToBdt = 120.0;
      const costBdt = geminiCostUsd * usdToBdt; // ~4.2 BDT
      const netProfitBdt = retailBdt - costBdt; // ~15.8 BDT per minute (~79% profit margin)

      t.set(billingRef, {
        recordId: billingRef.id,
        callId: callId || 'unknown',
        callerId: callerUid,
        calleeId: calleeId || '',
        isTranslatedCall: true,
        durationSeconds: durationSeconds || 60,
        minuteIndex: minuteIndex || newTotalUsed,
        geminiCostUsd,
        retailBdt,
        costBdt,
        netProfitBdt,
        remainingMinutesAfter: remainingMinutes,
        timestamp: now.toISOString(),
      });

      return {
        status: 200,
        success: true,
        deducted: 1,
        remainingMinutes,
        lowBalanceWarning: remainingMinutes === 2 || remainingMinutes === 1,
        exhausted: remainingMinutes <= 0,
      };
    });

    if (result.status !== 200) {
      return res.status(result.status).json(result);
    }

    console.log(`[SaaS Billing] Deducted 1 min from ${callerUid} for call ${callId}. Remaining: ${result.remainingMinutes}`);
    return res.json(result);
  } catch (err) {
    console.error('[SaaS Billing] Error deducting minute:', err.message);
    return res.status(500).json({ error: 'Failed to process minute deduction', message: err.message });
  }
});

// Finalize call billing record on hang-up with strict reconciliation
app.post('/api/wallet/call-end', authenticateRequest, async (req, res) => {
  const callerUid = req.user.uid;
  const { callId, totalDurationSeconds, totalMinutesBilled, isTranslatedCall } = req.body || {};

  if (!firestoreDb) {
    return res.status(503).json({ error: 'Firestore service unavailable' });
  }

  try {
    const summaryRef = firestoreDb.collection('call_summaries').doc(callId || `call_${Date.now()}`);
    let finalBilledMinutes = totalMinutesBilled || 0;

    // Strict Reconciliation: Charge remaining unbilled seconds rounded up
    if (isTranslatedCall && (totalDurationSeconds || 0) > 0) {
      const expectedMinutes = Math.ceil(totalDurationSeconds / 60);
      if (finalBilledMinutes < expectedMinutes) {
        const unbilled = expectedMinutes - finalBilledMinutes;
        const walletRef = firestoreDb.collection('users').doc(callerUid).collection('wallet').doc('current');

        try {
          await firestoreDb.runTransaction(async (t) => {
            const snap = await t.get(walletRef);
            if (!snap.exists) return;
            const data = snap.data() || {};
            const now = new Date();
            const trialActive = data.trialActive && (!data.trialExpiresAt || new Date(data.trialExpiresAt) > now);
            let newTrial = data.trialMinutes || 0;
            let newBalance = data.balanceMinutes || 0;

            let toDeduct = unbilled;
            if (trialActive && newTrial > 0) {
              const fromTrial = Math.min(newTrial, toDeduct);
              newTrial -= fromTrial;
              toDeduct -= fromTrial;
            }
            if (toDeduct > 0 && newBalance > 0) {
              const fromBal = Math.min(newBalance, toDeduct);
              newBalance -= fromBal;
              toDeduct -= fromBal;
            }

            t.update(walletRef, {
              trialMinutes: newTrial,
              balanceMinutes: newBalance,
              totalMinutesUsed: (data.totalMinutesUsed || 0) + (unbilled - toDeduct),
              updatedAt: now.toISOString(),
            });

            // Ledger record
            const billingRef = firestoreDb.collection('call_billing_records').doc();
            t.set(billingRef, {
              recordId: billingRef.id,
              callId: callId || 'unknown',
              callerId: callerUid,
              isTranslatedCall: true,
              durationSeconds: totalDurationSeconds,
              minuteIndex: (data.totalMinutesUsed || 0) + (unbilled - toDeduct),
              deductedAtEnd: unbilled,
              timestamp: now.toISOString(),
            });
          });
          finalBilledMinutes = expectedMinutes;
          console.log(`[SaaS Billing] Reconciled and deducted ${unbilled} remaining minute(s) at call-end for ${callerUid}`);
        } catch (recErr) {
          console.error('[SaaS Billing] Error during call-end minute reconciliation:', recErr.message);
        }
      }
    }

    const geminiCostUsd = isTranslatedCall ? finalBilledMinutes * 0.035 : 0;
    const retailBdt = isTranslatedCall ? finalBilledMinutes * 20.0 : 0;
    const netProfitBdt = isTranslatedCall ? retailBdt - (geminiCostUsd * 120.0) : 0;

    await summaryRef.set({
      callId,
      callerId: callerUid,
      totalDurationSeconds: totalDurationSeconds || 0,
      totalMinutesBilled: finalBilledMinutes,
      isTranslatedCall: !!isTranslatedCall,
      geminiCostUsd,
      retailBdt,
      netProfitBdt,
      endedAt: new Date().toISOString(),
    }, { merge: true });

    return res.json({ success: true, finalBilledMinutes });
  } catch (err) {
    console.warn('[SaaS Billing] Error saving call summary:', err.message);
    return res.json({ success: false, error: err.message });
  }
});

// Official SaaS Minute Packs & Server-Side Pricing (Source of Truth)
const OFFICIAL_PACKS = {
  'starter_60': {
    id: 'starter_60',
    name: 'স্টার্টার প্যাক (Starter Pack)',
    baseMinutes: 60,
    priceBdt: 1200,
    priceUsdt: 10,
  },
  'pro_180': {
    id: 'pro_180',
    name: 'ফ্রিল্যান্সার প্রো (Freelancer Pro)',
    baseMinutes: 180,
    priceBdt: 3000,
    priceUsdt: 25,
  },
  'agency_500': {
    id: 'agency_500',
    name: 'এজেন্সি প্যাক (Agency / Heavy Pack)',
    baseMinutes: 500,
    priceBdt: 7200,
    priceUsdt: 60,
  },
};

// Official Promo Codes & Bonuses (Server-side single-use verification)
const OFFICIAL_PROMOS = {
  'LIVOCAL2026': { bonusMinutes: 20, description: 'New Year 2026 Promo' },
  'FREELANCERPRO': { bonusMinutes: 30, description: 'Freelancer Community Bonus' },
};

// Fail-Fast Admin Secret Configuration (Strict: No ephemeral secrets, No log leaks)
const effectiveAdminSecret = process.env.ADMIN_SECRET;
if (!effectiveAdminSecret || effectiveAdminSecret.trim().length < 16) {
  console.error('❌ [FATAL SECURITY ERROR] process.env.ADMIN_SECRET is missing or less than 16 characters in backend/.env!');
  console.error('👉 Please configure a strong ADMIN_SECRET in backend/.env before running the server.');
  process.exit(1);
}
console.log('[Security] Admin Secret initialized and secured via environment.');

// Cryptographic Tron TRC-20 Address Validation (Base58Check with 0x41 prefix and double SHA256 checksum)
function validateTronAddress(addr) {
  if (!addr || typeof addr !== 'string' || addr.length !== 34 || !addr.startsWith('T')) return false;
  const bs58Alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  let num = 0n;
  for (const char of addr) {
    const idx = bs58Alphabet.indexOf(char);
    if (idx === -1) return false;
    num = num * 58n + BigInt(idx);
  }
  let hex = num.toString(16);
  if (hex.length % 2 !== 0) hex = '0' + hex;
  const buf = Buffer.from(hex, 'hex');
  if (buf.length !== 25 || buf[0] !== 0x41) return false;
  const payload = buf.slice(0, 21);
  const check = buf.slice(21);
  const h1 = crypto.createHash('sha256').update(payload).digest();
  const h2 = crypto.createHash('sha256').update(h1).digest();
  return h2.slice(0, 4).equals(check);
}

// EVM / BSC BEP-20 Address Validation
function validateBscAddress(addr) {
  return typeof addr === 'string' && /^0x[a-fA-F0-9]{40}$/.test(addr.trim());
}

// Binance Pay ID / Email Validation
function validateBinancePayId(id) {
  if (!id || typeof id !== 'string') return false;
  const trimmed = id.trim();
  return /^\d{8,12}$/.test(trimmed) || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed);
}

const safeCompareSecrets = (provided, target) => {
  if (typeof provided !== 'string' || typeof target !== 'string') return false;
  const providedBuf = Buffer.from(provided, 'utf8');
  const targetBuf = Buffer.from(target, 'utf8');
  if (providedBuf.length !== targetBuf.length) return false;
  return crypto.timingSafeEqual(providedBuf, targetBuf);
};

// Admin Authorization Middleware (Strict: Headers only, No query params, Timing-safe)
const authenticateAdmin = async (req, res, next) => {
  const providedSecret = req.headers['x-admin-secret'];

  if (providedSecret && safeCompareSecrets(providedSecret, effectiveAdminSecret)) {
    return next();
  }

  const authHeader = req.headers['authorization'];
  if (authHeader && authHeader.startsWith('Bearer ') && authService) {
    const token = authHeader.substring(7).trim();
    try {
      const decoded = await authService.verifyIdToken(token);
      if (decoded.admin === true || decoded.uid === process.env.SUPER_ADMIN_UID) {
        req.adminUser = decoded;
        return next();
      }
    } catch (err) {
      console.warn('[AdminAuth] Bearer token verification failed:', err.message);
    }
  }

  return res.status(403).json({ error: 'Forbidden: Valid Admin credentials or x-admin-secret header required' });
};

// User (Firebase ID token) OR Admin (x-admin-secret / admin claim) Authentication Middleware
const authenticateUserOrAdmin = async (req, res, next) => {
  const providedSecret = req.headers['x-admin-secret'];
  if (providedSecret && safeCompareSecrets(providedSecret, effectiveAdminSecret)) {
    return next();
  }
  return authenticateRequest(req, res, next);
};

// Direct client wallet crediting is STRICTLY BLOCKED for P0 security.
// Only authenticated Admin or verified payment callback can invoke this endpoint directly.
app.post('/api/wallet/recharge', authenticateAdmin, async (req, res) => {
  const targetUid = req.body.userId || req.body.uid;
  const { packId, minutes, amount, currency, paymentMethod, transactionId, promoCode } = req.body || {};

  if (!targetUid) {
    return res.status(400).json({ error: 'target userId is required' });
  }

  if (!firestoreDb) {
    return res.status(503).json({ error: 'Firestore service unavailable' });
  }

  // Server-side pack validation
  let minutesToAdd = 0;
  let amountPaid = Number(amount) || 0;
  let packName = 'custom';
  if (packId && OFFICIAL_PACKS[packId]) {
    minutesToAdd = OFFICIAL_PACKS[packId].baseMinutes;
    packName = OFFICIAL_PACKS[packId].name;
    if (!amountPaid) amountPaid = OFFICIAL_PACKS[packId].priceBdt;
  } else {
    minutesToAdd = parseInt(minutes, 10);
  }

  if (isNaN(minutesToAdd) || minutesToAdd <= 0) {
    return res.status(400).json({ error: 'Invalid minutes amount' });
  }

  try {
    const walletRef = firestoreDb.collection('users').doc(targetUid).collection('wallet').doc('current');
    const txId = transactionId || `adm_tx_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    const txRef = firestoreDb.collection('recharge_transactions').doc(txId);

    const updatedWallet = await firestoreDb.runTransaction(async (transaction) => {
      const walletDoc = await transaction.get(walletRef);
      const nowIso = new Date().toISOString();

      let currentData = walletDoc.exists ? walletDoc.data() : {
        balanceMinutes: 0,
        trialMinutes: 0,
        trialActive: false,
        trialExpiresAt: nowIso,
        totalMinutesUsed: 0,
        totalMinutesPurchased: 0,
        currency: currency || 'BDT',
        createdAt: nowIso,
      };

      const newBalance = (currentData.balanceMinutes || 0) + minutesToAdd;
      const newPurchased = (currentData.totalMinutesPurchased || 0) + minutesToAdd;

      const walletUpdate = {
        ...currentData,
        balanceMinutes: newBalance,
        totalMinutesPurchased: newPurchased,
        updatedAt: nowIso,
      };

      transaction.set(walletRef, walletUpdate, { merge: true });

      transaction.set(txRef, {
        transactionId: txId,
        userId: targetUid,
        userPhone: currentData.phone || '',
        packId: packId || 'custom',
        minutesAdded: minutesToAdd,
        amountPaid,
        currency: currency || 'BDT',
        paymentMethod: paymentMethod || 'Admin Direct Credit',
        promoCode: promoCode || null,
        status: 'completed',
        createdAt: nowIso,
      });

      return walletUpdate;
    });

    console.log(`[SaaS Billing] Admin recharged ${minutesToAdd} minutes for user ${targetUid}. New balance: ${updatedWallet.balanceMinutes} mins.`);
    return res.json({ success: true, wallet: updatedWallet, transactionId: txId });
  } catch (err) {
    console.error('[SaaS Billing] Error processing wallet recharge:', err.message);
    return res.status(500).json({ error: 'Failed to process recharge', message: err.message });
  }
});

// Admin metrics overview endpoint
app.get('/api/admin/metrics', authenticateAdmin, async (req, res) => {
  if (!firestoreDb) {
    return res.status(503).json({ error: 'Firestore database service is currently unavailable' });
  }

  try {
    // 1. Aggregate call billing records
    const billingSnap = await firestoreDb.collection('call_billing_records').limit(1000).get();
    let totalBilledMinutes = 0;
    let totalRetailBdt = 0;
    let totalGeminiCostUsd = 0;

    billingSnap.forEach((doc) => {
      const data = doc.data();
      totalBilledMinutes += 1;
      totalRetailBdt += (Number(data.retailRateBdt) || 20.0);
      totalGeminiCostUsd += (Number(data.geminiCostUsd) || 0.035);
    });

    const totalGeminiCostBdt = totalGeminiCostUsd * 120.0;
    const netProfitBdt = totalRetailBdt - totalGeminiCostBdt;
    const profitMarginPercent = totalRetailBdt > 0 ? ((netProfitBdt / totalRetailBdt) * 100).toFixed(1) : '0.0';

    // 2. Aggregate recharge transactions
    const rechargesSnap = await firestoreDb.collection('recharge_transactions').limit(1000).get();
    let totalRechargeRevenueBdt = 0;
    let totalPaidMinutesPurchased = 0;

    rechargesSnap.forEach((doc) => {
      const data = doc.data();
      totalRechargeRevenueBdt += (Number(data.amountPaid) || 0);
      totalPaidMinutesPurchased += (Number(data.minutesAdded) || 0);
    });

    // 3. User count
    const usersSnap = await firestoreDb.collection('users').limit(1000).get();
    const totalUsers = usersSnap.size;

    return res.json({
      success: true,
      metrics: {
        totalUsers,
        totalBilledMinutes,
        totalRetailBdt,
        totalGeminiCostUsd: Number(totalGeminiCostUsd.toFixed(4)),
        totalGeminiCostBdt: Math.round(totalGeminiCostBdt),
        netProfitBdt: Math.round(netProfitBdt),
        profitMarginPercent: `${profitMarginPercent}%`,
        totalRechargeRevenueBdt,
        totalPaidMinutesPurchased,
        activeRatePerMinuteBdt: 20.0,
        geminiCostPerMinuteUsd: 0.035,
      },
      updatedAt: new Date().toISOString(),
    });
  } catch (err) {
    console.error('[Admin] Error calculating metrics:', err.message);
    return res.status(500).json({ error: 'Failed to compute admin metrics', message: err.message });
  }
});

// Admin list wallets
app.get('/api/admin/wallets', authenticateAdmin, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'Firestore service unavailable' });

  try {
    const search = (req.query.search || '').trim().toLowerCase();
    const usersSnap = await firestoreDb.collection('users').limit(100).get();
    const walletsList = [];

    for (const userDoc of usersSnap.docs) {
      const uData = userDoc.data();
      const phone = uData.phone?.formattedNumber || uData.phone?.number || '';
      const name = uData.name || 'Anonymous';

      if (search && !phone.toLowerCase().includes(search) && !name.toLowerCase().includes(search) && !userDoc.id.includes(search)) {
        continue;
      }

      const walletDoc = await firestoreDb.collection('users').doc(userDoc.id).collection('wallet').doc('current').get();
      const wData = walletDoc.exists ? walletDoc.data() : null;

      walletsList.push({
        userId: userDoc.id,
        name,
        phone,
        balanceMinutes: wData ? (wData.balanceMinutes || 0) : 0,
        trialMinutes: wData ? (wData.trialMinutes || 0) : 20,
        trialActive: wData ? (wData.trialActive ?? true) : true,
        trialExpiresAt: wData?.trialExpiresAt || null,
        totalMinutesUsed: wData ? (wData.totalMinutesUsed || 0) : 0,
        updatedAt: wData?.updatedAt || null,
      });
    }

    return res.json({ success: true, count: walletsList.length, wallets: walletsList });
  } catch (err) {
    console.error('[Admin] Error fetching wallets:', err.message);
    return res.status(500).json({ error: 'Failed to fetch wallets' });
  }
});

// Admin Call Billing Ledger
app.get('/api/admin/billing-ledger', authenticateAdmin, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'Firestore service unavailable' });

  try {
    const ledgerSnap = await firestoreDb.collection('call_billing_records')
      .orderBy('timestamp', 'desc')
      .limit(100)
      .get();

    const records = [];
    ledgerSnap.forEach((doc) => {
      records.push({ id: doc.id, ...doc.data() });
    });

    return res.json({ success: true, count: records.length, records });
  } catch (err) {
    console.error('[Admin] Error fetching billing ledger:', err.message);
    return res.status(500).json({ error: 'Failed to fetch ledger' });
  }
});

// Admin Recharge History
app.get('/api/admin/recharges', authenticateAdmin, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'Firestore service unavailable' });

  try {
    const snap = await firestoreDb.collection('recharge_transactions')
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get();

    const recharges = [];
    snap.forEach((doc) => {
      recharges.push({ id: doc.id, ...doc.data() });
    });

    return res.json({ success: true, count: recharges.length, recharges });
  } catch (err) {
    console.error('[Admin] Error fetching recharges:', err.message);
    return res.status(500).json({ error: 'Failed to fetch recharges' });
  }
});

// P2P In-Chat Minute Transfer (Atomic User A -> User B)
app.post('/api/wallet/p2p-transfer', authenticateRequest, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'Firestore service unavailable' });

  const fromUserId = req.user?.uid;
  const { toUserId, minutes, note } = req.body || {};

  if (!fromUserId) {
    return res.status(401).json({ error: 'Unauthorized: missing sender UID' });
  }
  if (!toUserId || typeof toUserId !== 'string' || toUserId.trim() === '') {
    return res.status(400).json({ error: 'Valid recipient toUserId is required' });
  }
  if (fromUserId === toUserId) {
    return res.status(400).json({ error: 'Cannot transfer minutes to yourself' });
  }

  const mins = parseInt(minutes, 10);
  if (isNaN(mins) || mins <= 0) {
    return res.status(400).json({ error: 'Minutes to transfer must be a positive integer' });
  }

  try {
    const senderRef = firestoreDb.collection('users').doc(fromUserId).collection('wallet').doc('current');
    const receiverRef = firestoreDb.collection('users').doc(toUserId).collection('wallet').doc('current');
    const transferId = `p2p_min_${Date.now()}_${fromUserId.length > 5 ? fromUserId.substring(0, 5) : fromUserId}`;
    const transferRef = firestoreDb.collection('p2p_transfers').doc(transferId);

    const result = await firestoreDb.runTransaction(async (tx) => {
      const senderSnap = await tx.get(senderRef);
      if (!senderSnap.exists) {
        throw new Error('Sender wallet does not exist');
      }

      const senderData = senderSnap.data() || {};
      const senderBalance = Number(senderData.balanceMinutes || 0);
      if (senderBalance < mins) {
        throw new Error(`Insufficient minute balance. Current: ${senderBalance}, Requested: ${mins}`);
      }

      const receiverSnap = await tx.get(receiverRef);
      let receiverBalance = 0;
      let receiverPurchased = 0;
      if (receiverSnap.exists) {
        const rData = receiverSnap.data() || {};
        receiverBalance = Number(rData.balanceMinutes || 0);
        receiverPurchased = Number(rData.totalMinutesPurchased || 0);
      }

      const nowIso = new Date().toISOString();

      // Deduct from sender
      tx.set(senderRef, {
        balanceMinutes: senderBalance - mins,
        updatedAt: nowIso,
      }, { merge: true });

      // Credit to receiver
      tx.set(receiverRef, {
        balanceMinutes: receiverBalance + mins,
        totalMinutesPurchased: receiverPurchased + mins,
        updatedAt: nowIso,
      }, { merge: true });

      // Immutable central audit record for Admin Panel
      tx.set(transferRef, {
        id: transferId,
        type: 'minute_transfer',
        fromUserId,
        toUserId,
        minutes: mins,
        note: (note || '').toString().trim(),
        status: 'completed',
        method: 'Livocal Wallet',
        createdAt: nowIso,
      });

      return {
        transferId,
        remainingMinutes: senderBalance - mins,
      };
    });

    return res.json({
      success: true,
      message: `Successfully transferred ${mins} minutes`,
      ...result,
    });
  } catch (err) {
    console.error('[P2P Transfer] Error transferring minutes:', err.message);
    const statusCode = err.message.includes('Insufficient') ? 400 : 500;
    return res.status(statusCode).json({ error: err.message || 'Failed to transfer minutes' });
  }
});

// Admin In-Chat P2P Transfers & Payments Tracking
app.get('/api/admin/p2p-transfers', authenticateAdmin, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'Firestore service unavailable' });

  try {
    let transfers = [];
    let payments = [];

    try {
      const snapTransfers = await firestoreDb.collection('p2p_transfers')
        .orderBy('createdAt', 'desc')
        .limit(100)
        .get();
      snapTransfers.forEach(doc => transfers.push({ id: doc.id, ...doc.data() }));
    } catch (e) {
      console.warn('[Admin] Fallback fetch p2p_transfers without order:', e.message);
      const snapTransfers = await firestoreDb.collection('p2p_transfers').limit(100).get();
      snapTransfers.forEach(doc => transfers.push({ id: doc.id, ...doc.data() }));
    }

    try {
      const snapPayments = await firestoreDb.collection('p2p_payments')
        .orderBy('createdAt', 'desc')
        .limit(100)
        .get();
      snapPayments.forEach(doc => payments.push({ id: doc.id, ...doc.data() }));
    } catch (e) {
      console.warn('[Admin] Fallback fetch p2p_payments without order:', e.message);
      const snapPayments = await firestoreDb.collection('p2p_payments').limit(100).get();
      snapPayments.forEach(doc => payments.push({ id: doc.id, ...doc.data() }));
    }

    let totalMinutes = 0;
    transfers.forEach(t => {
      if (t.status === 'completed' && Number(t.minutes)) {
        totalMinutes += Number(t.minutes);
      }
    });

    let totalBdt = 0;
    let totalCryptoUsdt = 0;
    payments.forEach(p => {
      const rawAmt = typeof p.amount === 'string' ? p.amount.replace(/[^0-9.]/g, '') : Number(p.amount);
      const numAmt = parseFloat(rawAmt) || 0;
      const method = (p.type || p.methodDisplay || '').toLowerCase();
      if (method.includes('bkash') || method.includes('nagad') || (p.currency || '').toUpperCase() === 'BDT') {
        totalBdt += numAmt;
      } else if (method.includes('crypto') || method.includes('usdt') || method.includes('binance') || (p.currency || '').toUpperCase() === 'USDT') {
        totalCryptoUsdt += numAmt;
      }
    });

    return res.json({
      success: true,
      transfers,
      payments,
      stats: {
        totalMinutesTransferred: totalMinutes,
        totalBdtAmount: totalBdt,
        totalCryptoUsdtAmount: totalCryptoUsdt,
        totalTransfersCount: transfers.length,
        totalPaymentsCount: payments.length,
      },
    });
  } catch (err) {
    console.error('[Admin] Error fetching p2p records:', err.message);
    return res.status(500).json({ error: 'Failed to fetch p2p records' });
  }
});

// Admin update / verify P2P payment record status
app.post('/api/admin/p2p-payment/action', authenticateAdmin, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'Firestore service unavailable' });

  const { paymentId, action, note } = req.body || {};
  if (!paymentId) {
    return res.status(400).json({ error: 'paymentId is required' });
  }

  const validActions = ['verify', 'flag', 'resolve'];
  if (!validActions.includes(action)) {
    return res.status(400).json({ error: `Invalid action. Must be one of: ${validActions.join(', ')}` });
  }

  const targetStatus = action === 'verify' ? 'verified' : (action === 'flag' ? 'flagged' : 'resolved');

  try {
    const payRef = firestoreDb.collection('p2p_payments').doc(paymentId);
    const snap = await payRef.get();
    if (!snap.exists) {
      return res.status(404).json({ error: 'P2P Payment record not found' });
    }

    await payRef.set({
      status: targetStatus,
      adminNote: (note || '').toString().trim(),
      updatedAt: new Date().toISOString(),
    }, { merge: true });

    return res.json({
      success: true,
      paymentId,
      status: targetStatus,
      message: `P2P payment status updated to ${targetStatus}`,
    });
  } catch (err) {
    console.error('[Admin] Error updating p2p payment status:', err.message);
    return res.status(500).json({ error: 'Failed to update p2p payment status' });
  }
});

// Helper to read active deposit gateway configurations (with Firestore fallback for cloud permanence)
async function getDepositGateways() {
  let docData = null;
  if (firestoreDb) {
    try {
      const doc = await firestoreDb.collection('system_config').doc('deposit_gateways').get();
      if (doc.exists) {
        docData = doc.data();
      }
    } catch (e) {
      // Non-blocking fallback
    }
  }

  const bkashNum = (docData?.bkashNumber || process.env.BKASH_NUMBER || '01721013902').trim();
  const nagadNum = (docData?.nagadNumber || process.env.NAGAD_NUMBER || '01721013902').trim();
  const binancePayId = (docData?.binancePayId || process.env.BINANCE_PAY_ID || '849201842').trim();
  const trc20Addr = (docData?.cryptoUsdtTrc20 || process.env.CRYPTO_USDT_TRC20 || 'TXztYG8zHPCZNdZqK5oodVWQVL2322mgpf').trim();
  const bep20Addr = (docData?.cryptoUsdtBep20 || process.env.CRYPTO_USDT_BEP20 || '0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97').trim();

  return { bkashNum, nagadNum, binancePayId, trc20Addr, bep20Addr };
}

// Public / authenticated endpoint for clients to get active deposit accounts & addresses dynamically
app.get('/api/wallet/deposit-info', authenticateUserOrAdmin, async (req, res) => {
  const { bkashNum, nagadNum, binancePayId, trc20Addr, bep20Addr } = await getDepositGateways();

  res.json({
    success: true,
    depositInfo: {
      bkash: {
        number: bkashNum,
        type: 'Personal / Send Money',
      },
      nagad: {
        number: nagadNum,
        type: 'Personal / Send Money',
      },
      binancePay: {
        payId: binancePayId,
        name: 'Livocal Global',
      },
      cryptoUsdt: {
        trc20: {
          network: 'TRC-20',
          networkName: 'Tron (TRC-20)',
          address: trc20Addr,
          explorerUrl: 'https://tronscan.org/#/transaction/',
        },
        bep20: {
          network: 'BEP-20',
          networkName: 'BNB Smart Chain (BEP-20)',
          address: bep20Addr,
          explorerUrl: 'https://bscscan.com/tx/',
        },
      },
    },
    packs: OFFICIAL_PACKS,
  });
});

// Admin update deposit gateway configuration endpoint
app.post('/api/admin/deposit-gateways', authenticateAdmin, async (req, res) => {
  const {
    bkashNumber,
    nagadNumber,
    binancePayId,
    cryptoUsdtTrc20,
    cryptoUsdtBep20,
  } = req.body || {};

  // Validation
  const cleanBkash = (bkashNumber || '').trim();
  const cleanNagad = (nagadNumber || '').trim();
  const cleanBinance = (binancePayId || '').trim();
  const cleanTrc20 = (cryptoUsdtTrc20 || '').trim();
  const cleanBep20 = (cryptoUsdtBep20 || '').trim();

  if (cleanBkash && !/^[0-9+ ]{8,20}$/.test(cleanBkash)) {
    return res.status(400).json({ error: 'Invalid bKash phone number format' });
  }
  if (cleanNagad && !/^[0-9+ ]{8,20}$/.test(cleanNagad)) {
    return res.status(400).json({ error: 'Invalid Nagad phone number format' });
  }
  if (cleanBinance && !validateBinancePayId(cleanBinance)) {
    return res.status(400).json({ error: 'Invalid Binance Pay ID (8-12 digits or email)' });
  }
  if (cleanTrc20 && !validateTronAddress(cleanTrc20)) {
    return res.status(400).json({ error: 'Invalid Tron (TRC-20) address (Must start with T and have 34 Base58 characters)' });
  }
  if (cleanBep20 && !validateBscAddress(cleanBep20)) {
    return res.status(400).json({ error: 'Invalid BSC (BEP-20) address (Must start with 0x and have 42 hex characters)' });
  }

  const updates = {};
  if (cleanBkash) updates.bkashNumber = cleanBkash;
  if (cleanNagad) updates.nagadNumber = cleanNagad;
  if (cleanBinance) updates.binancePayId = cleanBinance;
  if (cleanTrc20) updates.cryptoUsdtTrc20 = cleanTrc20;
  if (cleanBep20) updates.cryptoUsdtBep20 = cleanBep20;

  if (Object.keys(updates).length === 0) {
    return res.status(400).json({ error: 'No valid non-empty gateway parameters provided to update' });
  }

  // 1. Persist to Firestore system_config for cloud permanence across container restarts
  if (firestoreDb) {
    try {
      await firestoreDb.collection('system_config').doc('deposit_gateways').set({
        ...updates,
        updatedAt: new Date().toISOString(),
      }, { merge: true });
      console.log('[DepositGateways] Successfully persisted gateways to Firestore system_config/deposit_gateways');
    } catch (err) {
      console.warn('[DepositGateways] Could not persist to Firestore:', err.message);
    }
  }

  // 2. Update memory runtime
  if (cleanBkash) process.env.BKASH_NUMBER = cleanBkash;
  if (cleanNagad) process.env.NAGAD_NUMBER = cleanNagad;
  if (cleanBinance) process.env.BINANCE_PAY_ID = cleanBinance;
  if (cleanTrc20) process.env.CRYPTO_USDT_TRC20 = cleanTrc20;
  if (cleanBep20) process.env.CRYPTO_USDT_BEP20 = cleanBep20;

  console.log('[DepositGateways] Admin updated gateway configuration fields:', Object.keys(updates));
  const current = await getDepositGateways();
  return res.json({
    success: true,
    message: 'Deposit gateway configuration updated successfully',
    depositInfo: {
      bkash: { number: current.bkashNum, type: 'Personal / Send Money' },
      nagad: { number: current.nagadNum, type: 'Personal / Send Money' },
      binancePay: { payId: current.binancePayId, name: 'Livocal Global' },
      cryptoUsdt: {
        trc20: { network: 'TRC-20', networkName: 'Tron (TRC-20)', address: current.trc20Addr },
        bep20: { network: 'BEP-20', networkName: 'BNB Smart Chain (BEP-20)', address: current.bep20Addr },
      },
    },
  });
});

// Freelancer submits payment verification request (bKash, Nagad, Binance Pay, USDT TRC20/BEP20)
app.post('/api/wallet/payment-request', authenticateRequest, async (req, res) => {
  const userId = req.user.uid;
  const {
    packId,
    senderIdentifier, // phone number OR Binance ID OR USDT wallet address
    senderPhone,      // backward compatibility for bKash/Nagad
    trxId,            // TrxID, TxHash, or Binance Order ID
    paymentMethod,    // 'bKash', 'Nagad', 'Binance_Pay', 'Crypto_USDT_TRC20', 'Crypto_USDT_BEP20'
    promoCode,
  } = req.body || {};

  if (!firestoreDb) return res.status(503).json({ error: 'Firestore service unavailable' });

  // 1. Server-side pack validation (Never trust client minutes/amount)
  const selectedPack = OFFICIAL_PACKS[packId];
  if (!selectedPack) {
    return res.status(400).json({ error: 'Invalid packId. Must be starter_60, pro_180, or agency_500' });
  }

  // 2. Validate TrxID / TxHash against strict regex to prevent stored XSS and injection
  if (!trxId || typeof trxId !== 'string' || !trxId.trim()) {
    return res.status(400).json({ error: 'Transaction ID / TxHash is required' });
  }
  const cleanTrx = trxId.trim().replace(/\s+/g, '');
  if (!/^[a-zA-Z0-9_\-]{6,128}$/.test(cleanTrx)) {
    return res.status(400).json({ error: 'Invalid Transaction ID / TxHash format. Must contain 6-128 alphanumeric characters.' });
  }

  // 3. Validate sender identifier
  const rawIdentifier = (senderIdentifier || senderPhone || '').trim();
  if (!rawIdentifier) {
    return res.status(400).json({ error: 'Sender phone number, Binance ID, or crypto wallet address is required' });
  }
  // Strip whitespace so formatted phone numbers (e.g. "+880 1721 013902" or "01721 013 902")
  // and spaced crypto/Binance inputs pass cleanly without rejecting user
  const cleanIdentifier = rawIdentifier.replace(/\s+/g, '');
  if (!/^[a-zA-Z0-9@.+_\-]{1,64}$/.test(cleanIdentifier)) {
    return res.status(400).json({ error: 'Invalid sender identifier format.' });
  }
  const identifier = cleanIdentifier;

  // 4. Validate payment method & determine currency and amount
  const validMethods = ['bKash', 'Nagad', 'Binance_Pay', 'Crypto_USDT_TRC20', 'Crypto_USDT_BEP20'];
  const method = validMethods.includes(paymentMethod) ? paymentMethod : 'bKash';

  // Format checks for blockchain/crypto payments to stop fraudulent inputs immediately
  if (method === 'Crypto_USDT_TRC20') {
    if (!validateTronAddress(identifier)) {
      return res.status(400).json({ error: 'Invalid Tron (TRC-20) sender wallet address format (Must start with T and have 34 Base58 characters).' });
    }
    const cleanHash = cleanTrx.replace(/^0x/, '');
    if (!/^[a-fA-F0-9]{64}$/.test(cleanHash)) {
      return res.status(400).json({ error: 'Invalid Tron TxHash format (Must be 64 hexadecimal characters).' });
    }
  } else if (method === 'Crypto_USDT_BEP20') {
    if (!validateBscAddress(identifier)) {
      return res.status(400).json({ error: 'Invalid BNB Smart Chain (BEP-20) sender wallet address (Must be 0x followed by 40 hex characters).' });
    }
    const cleanHash = cleanTrx.startsWith('0x') ? cleanTrx : `0x${cleanTrx}`;
    if (!/^0x[a-fA-F0-9]{64}$/.test(cleanHash)) {
      return res.status(400).json({ error: 'Invalid BSC TxHash format (Must be 64 hexadecimal characters).' });
    }
  } else if (method === 'Binance_Pay') {
    if (!validateBinancePayId(identifier)) {
      return res.status(400).json({ error: 'Invalid Binance Pay ID or Email address.' });
    }
  }

  const isCrypto = method === 'Binance_Pay' || method.startsWith('Crypto_USDT');
  const currency = isCrypto ? 'USDT' : 'BDT';
  const expectedAmount = isCrypto ? selectedPack.priceUsdt : selectedPack.priceBdt;

  // 5. Server-side promo code validation
  let bonusMinutes = 0;
  let validatedPromo = null;
  if (promoCode && typeof promoCode === 'string' && promoCode.trim()) {
    const cleanPromo = promoCode.trim().toUpperCase();
    if (!/^[A-Z0-9_]{3,20}$/.test(cleanPromo)) {
      return res.status(400).json({ error: 'Invalid promo code format.' });
    }
    if (OFFICIAL_PROMOS[cleanPromo]) {
      bonusMinutes = OFFICIAL_PROMOS[cleanPromo].bonusMinutes;
      validatedPromo = cleanPromo;
    } else {
      return res.status(400).json({ error: `Invalid or expired promo code: ${cleanPromo}` });
    }
  }

  const totalCalculatedMinutes = selectedPack.baseMinutes + bonusMinutes;
  const nowIso = new Date().toISOString();

  try {
    const normalizedTrx = cleanTrx.toUpperCase().replace(/^0X/, '');
    const reqId = `pay_${normalizedTrx.replace(/[^A-Z0-9_-]/g, '_')}`;
    const reqRef = firestoreDb.collection('payment_requests').doc(reqId);

    const paymentData = {
      id: reqId,
      userId,
      userPhone: req.user.phone_number || '',
      senderIdentifier: identifier,
      senderPhone: !isCrypto ? identifier : '',
      senderCryptoWalletOrBinanceId: isCrypto ? identifier : '',
      trxId: cleanTrx,
      normalizedTrxId: normalizedTrx,
      packId: selectedPack.id,
      packName: selectedPack.name,
      baseMinutes: selectedPack.baseMinutes,
      bonusMinutes,
      minutes: totalCalculatedMinutes,
      amount: expectedAmount,
      currency,
      paymentMethod: method,
      promoCode: validatedPromo,
      status: 'pending',
      createdAt: nowIso,
      updatedAt: nowIso,
    };

    // Atomic transaction: verify duplicate TrxID, lock promo code, and write request
    await firestoreDb.runTransaction(async (transaction) => {
      const existing = await transaction.get(reqRef);
      if (existing.exists) {
        throw new Error('DUPLICATE_TRX_ID');
      }

      if (validatedPromo) {
        // 1. Check if user has already redeemed this promo
        const promoRef = firestoreDb.collection('users').doc(userId).collection('redeemed_promos').doc(validatedPromo);
        const promoDoc = await transaction.get(promoRef);
        if (promoDoc.exists) {
          throw new Error('PROMO_ALREADY_USED');
        }

        // 2. Check if user already has an active pending request locking this promo code
        const promoLockRef = firestoreDb.collection('users').doc(userId).collection('active_promo_locks').doc(validatedPromo);
        const lockDoc = await transaction.get(promoLockRef);
        if (lockDoc.exists) {
          throw new Error('PROMO_ALREADY_PENDING');
        }

        // Lock promo code atomically
        transaction.set(promoLockRef, {
          promoCode: validatedPromo,
          requestId: reqId,
          lockedAt: nowIso,
        });
      }

      transaction.set(reqRef, paymentData);
    });

    console.log(`[Payment] Real payment request submitted atomically: ${cleanTrx} (${method}) by ${userId} for ${expectedAmount} ${currency} -> ${totalCalculatedMinutes} mins`);
    return res.json({ success: true, payment: paymentData });
  } catch (err) {
    console.error('[Payment] Error submitting payment request:', err.message);
    if (err.message === 'DUPLICATE_TRX_ID') {
      return res.status(409).json({ error: 'This Transaction ID / TxHash has already been submitted.' });
    }
    if (err.message === 'PROMO_ALREADY_USED') {
      return res.status(400).json({ error: `Promo code ${validatedPromo} has already been used on your account.` });
    }
    if (err.message === 'PROMO_ALREADY_PENDING') {
      return res.status(400).json({ error: `You already have an active pending payment request with promo code ${validatedPromo}. Please wait for admin approval.` });
    }
    return res.status(500).json({ error: 'Failed to submit payment request', message: err.message });
  }
});

// Admin list payment verification requests
app.get('/api/admin/payment-requests', authenticateAdmin, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'Firestore service unavailable' });

  try {
    const snap = await firestoreDb.collection('payment_requests')
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get();

    const requests = [];
    snap.forEach(doc => requests.push({ id: doc.id, ...doc.data() }));

    return res.json({ success: true, count: requests.length, requests });
  } catch (err) {
    console.error('[Admin] Error fetching payment requests:', err.message);
    return res.status(500).json({ error: 'Failed to fetch payment requests' });
  }
});

// Admin Approve or Reject payment request
app.post('/api/admin/payment-request/action', authenticateAdmin, async (req, res) => {
  const { requestId, action, notes, adminName } = req.body || {};
  if (!firestoreDb) return res.status(503).json({ error: 'Firestore service unavailable' });

  if (!requestId || !action) {
    return res.status(400).json({ error: 'requestId and action (approve/reject) are required' });
  }

  try {
    const reqRef = firestoreDb.collection('payment_requests').doc(requestId);
    const nowIso = new Date().toISOString();

    if (action === 'approve') {
      let minutesCredited = 0;
      let targetUser = '';
      let paymentMethodUsed = '';

      await firestoreDb.runTransaction(async (transaction) => {
        // 1. Fetch payment request inside transaction to lock and prevent race condition
        const reqDoc = await transaction.get(reqRef);
        if (!reqDoc.exists) {
          throw new Error('PAYMENT_NOT_FOUND');
        }

        const pData = reqDoc.data();
        if (pData.status !== 'pending') {
          throw new Error(`ALREADY_${(pData.status || '').toUpperCase()}`);
        }

        targetUser = pData.userId;
        minutesCredited = Number(pData.minutes) || 0;
        paymentMethodUsed = pData.paymentMethod || 'bKash';

        // 2. Atomically verify and redeem promo code inside transaction
        if (pData.promoCode) {
          const promoRef = firestoreDb.collection('users').doc(targetUser).collection('redeemed_promos').doc(pData.promoCode);
          const promoDoc = await transaction.get(promoRef);
          if (promoDoc.exists) {
            throw new Error('PROMO_ALREADY_REDEEMED');
          }
          transaction.set(promoRef, {
            promoCode: pData.promoCode,
            bonusMinutes: pData.bonusMinutes || 0,
            redeemedAt: nowIso,
            paymentRequestId: requestId,
          });
          // Remove active promo lock now that promo is permanently redeemed
          const promoLockRef = firestoreDb.collection('users').doc(targetUser).collection('active_promo_locks').doc(pData.promoCode);
          transaction.delete(promoLockRef);
        }

        // 3. Update wallet balance
        const walletRef = firestoreDb.collection('users').doc(targetUser).collection('wallet').doc('current');
        const txRef = firestoreDb.collection('recharge_transactions').doc(`tx_${pData.trxId.replace(/[^a-zA-Z0-9_-]/g, '_')}`);

        const wDoc = await transaction.get(walletRef);
        let wData = wDoc.exists ? wDoc.data() : {
          balanceMinutes: 0,
          trialMinutes: 0,
          trialActive: false,
          trialExpiresAt: nowIso,
          totalMinutesUsed: 0,
          totalMinutesPurchased: 0,
          currency: pData.currency || 'BDT',
          createdAt: nowIso,
        };

        const newBalance = (wData.balanceMinutes || 0) + minutesCredited;
        const newPurchased = (wData.totalMinutesPurchased || 0) + minutesCredited;

        transaction.set(walletRef, {
          ...wData,
          balanceMinutes: newBalance,
          totalMinutesPurchased: newPurchased,
          updatedAt: nowIso,
        }, { merge: true });

        // 4. Record immutable recharge ledger transaction
        transaction.set(txRef, {
          transactionId: `tx_${pData.trxId}`,
          userId: targetUser,
          userPhone: pData.userPhone || '',
          senderIdentifier: pData.senderIdentifier || pData.senderPhone || '',
          packId: pData.packId || 'custom',
          minutesAdded: minutesCredited,
          amountPaid: Number(pData.amount) || 0,
          currency: pData.currency || 'BDT',
          paymentMethod: paymentMethodUsed,
          trxId: pData.trxId,
          promoCode: pData.promoCode || null,
          status: 'completed',
          approvedBy: adminName || 'Admin',
          createdAt: nowIso,
        });

        // 5. Update request status to approved
        transaction.update(reqRef, {
          status: 'approved',
          approvedAt: nowIso,
          approvedBy: adminName || 'Admin',
          notes: notes || 'Verified and approved',
        });
      });

      console.log(`[Admin] Payment ${requestId} APPROVED atomically. ${minutesCredited} mins credited to ${targetUser} (${paymentMethodUsed}).`);
      return res.json({ success: true, status: 'approved', minutesCredited });
    } else if (action === 'reject') {
      await firestoreDb.runTransaction(async (transaction) => {
        const reqDoc = await transaction.get(reqRef);
        if (!reqDoc.exists) throw new Error('PAYMENT_NOT_FOUND');
        const pData = reqDoc.data();
        if (pData.status !== 'pending') {
          throw new Error(`ALREADY_${(pData.status || '').toUpperCase()}`);
        }
        // If payment had promo code locked, release the lock on rejection
        if (pData.promoCode) {
          const promoLockRef = firestoreDb.collection('users').doc(pData.userId).collection('active_promo_locks').doc(pData.promoCode);
          transaction.delete(promoLockRef);
        }
        transaction.update(reqRef, {
          status: 'rejected',
          rejectedAt: nowIso,
          rejectedBy: adminName || 'Admin',
          notes: notes || 'Payment rejected by admin',
        });
      });

      console.log(`[Admin] Payment ${requestId} REJECTED atomically.`);
      return res.json({ success: true, status: 'rejected' });
    } else {
      return res.status(400).json({ error: 'Invalid action. Must be approve or reject' });
    }
  } catch (err) {
    console.error('[Admin] Error processing payment action:', err.message);
    if (err.message === 'ALREADY_APPROVED') {
      return res.status(409).json({ error: 'Payment request has already been approved.' });
    }
    if (err.message === 'ALREADY_REJECTED') {
      return res.status(409).json({ error: 'Payment request has already been rejected.' });
    }
    if (err.message === 'PROMO_ALREADY_REDEEMED') {
      return res.status(409).json({ error: 'Promo code attached to this request was already redeemed.' });
    }
    if (err.message === 'PAYMENT_NOT_FOUND') {
      return res.status(404).json({ error: 'Payment request not found' });
    }
    return res.status(500).json({ error: 'Failed to process payment action', message: err.message });
  }
});

// Admin on-chain verification endpoint for TRC-20 and BEP-20
app.post('/api/admin/verify-onchain', authenticateAdmin, async (req, res) => {
  const { paymentMethod, trxId, expectedAmount, targetAddress } = req.body || {};
  if (!trxId || !paymentMethod) {
    return res.status(400).json({ error: 'trxId and paymentMethod are required' });
  }

  const cleanHash = trxId.trim();

  try {
    if (paymentMethod === 'Crypto_USDT_TRC20') {
      const expectedDeposit = targetAddress || process.env.CRYPTO_USDT_TRC20 || 'TXztYG8zHPCZNdZqK5oodVWQVL2322mgpf';
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 6000);
      const url = `https://apilist.tronscanapi.com/api/transaction-info?hash=${cleanHash.replace(/^0x/, '')}`;
      const response = await fetch(url, { signal: controller.signal });
      clearTimeout(timeout);

      if (!response.ok) {
        return res.json({ verified: false, error: `Tronscan returned HTTP ${response.status}`, explorerUrl: `https://tronscan.org/#/transaction/${cleanHash}` });
      }

      const data = await response.json();
      if (!data || !data.hash) {
        return res.json({
          verified: false,
          error: 'Transaction not found on Tron blockchain. Either pending confirmation or invalid TxHash.',
          explorerUrl: `https://tronscan.org/#/transaction/${cleanHash}`,
        });
      }

      const isSuccess = data.contractRet === 'SUCCESS';
      const confirmed = !!data.confirmed;

      // Look for TRC20 transfer info
      let transferFound = false;
      let transferredAmount = 0;
      let toRecipient = '';
      let fromSender = '';

      if (Array.isArray(data.trc20TransferInfo)) {
        for (const t of data.trc20TransferInfo) {
          if (t.symbol === 'USDT' || t.to_address === expectedDeposit) {
            transferFound = true;
            toRecipient = t.to_address;
            fromSender = t.from_address;
            const decimals = Number(t.decimals) || 6;
            transferredAmount = Number(t.amount_str) / Math.pow(10, decimals);
            break;
          }
        }
      }

      const recipientMatches = toRecipient.toLowerCase() === expectedDeposit.toLowerCase();
      const amountMatches = expectedAmount ? Math.abs(transferredAmount - Number(expectedAmount)) < 0.1 : true;
      const isFullyVerified = isSuccess && recipientMatches && amountMatches;

      return res.json({
        verified: isFullyVerified,
        status: isSuccess ? 'SUCCESS' : 'FAILED',
        confirmed,
        details: {
          hash: data.hash,
          from: fromSender || data.ownerAddress || '-',
          to: toRecipient || '-',
          expectedRecipient: expectedDeposit,
          recipientMatches,
          amountTransferred: transferredAmount,
          expectedAmount: expectedAmount || 0,
          amountMatches,
          timestamp: data.timestamp ? new Date(data.timestamp).toISOString() : null,
          explorerUrl: `https://tronscan.org/#/transaction/${data.hash}`,
        },
      });
    } else if (paymentMethod === 'Crypto_USDT_BEP20') {
      const expectedDeposit = targetAddress || process.env.CRYPTO_USDT_BEP20 || '0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97';
      const hashFormatted = cleanHash.startsWith('0x') ? cleanHash : `0x${cleanHash}`;

      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 6000);
      const rpcUrl = 'https://bsc-dataseed.binance.org';
      const response = await fetch(rpcUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          jsonrpc: '2.0',
          id: 1,
          method: 'eth_getTransactionReceipt',
          params: [hashFormatted],
        }),
        signal: controller.signal,
      });
      clearTimeout(timeout);

      const rpcResult = await response.json();
      const receipt = rpcResult?.result;

      if (!receipt) {
        return res.json({
          verified: false,
          error: 'Transaction receipt not found on BNB Smart Chain. Confirm tx hash or allow time to mine.',
          explorerUrl: `https://bscscan.com/tx/${hashFormatted}`,
        });
      }

      const isSuccess = receipt.status === '0x1';
      const cleanExpectedDeposit = expectedDeposit.toLowerCase().replace(/^0x/, '');
      const paddedRecipient = '0x' + cleanExpectedDeposit.padStart(64, '0');
      // Standard ERC20/BEP20 Transfer(address,address,uint256) event signature
      const TRANSFER_TOPIC = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';

      let transferFound = false;
      let transferredAmount = 0;
      let fromAddress = receipt.from;
      let toAddress = '';

      if (Array.isArray(receipt.logs)) {
        for (const log of receipt.logs) {
          if (log.topics && log.topics[0] && log.topics[0].toLowerCase() === TRANSFER_TOPIC) {
            const logRecipient = (log.topics[2] || '').toLowerCase();
            if (logRecipient === paddedRecipient.toLowerCase() || logRecipient.endsWith(cleanExpectedDeposit.toLowerCase())) {
              transferFound = true;
              toAddress = '0x' + logRecipient.slice(26);
              if (log.topics[1]) {
                fromAddress = '0x' + log.topics[1].slice(26);
              }
              try {
                // BSC USDT (BSC-USD) uses 18 decimals
                const rawVal = BigInt(log.data);
                transferredAmount = Number(rawVal) / 1e18;
              } catch (_) {
                transferredAmount = parseInt(log.data, 16) / 1e18;
              }
              break;
            }
          }
        }
      }

      // Fallback: direct contract or native transaction recipient match
      if (!transferFound && receipt.to && receipt.to.toLowerCase() === expectedDeposit.toLowerCase()) {
        transferFound = true;
        toAddress = receipt.to;
      }

      const recipientMatches = transferFound && toAddress.toLowerCase() === expectedDeposit.toLowerCase();
      const amountMatches = expectedAmount ? Math.abs(transferredAmount - Number(expectedAmount)) < 0.1 : true;
      const isFullyVerified = isSuccess && recipientMatches && amountMatches;

      return res.json({
        verified: isFullyVerified,
        status: isSuccess ? 'SUCCESS' : 'REVERTED',
        details: {
          hash: receipt.transactionHash,
          blockNumber: parseInt(receipt.blockNumber, 16),
          from: fromAddress || receipt.from,
          to: toAddress || receipt.to || '-',
          expectedRecipient: expectedDeposit,
          recipientMatches,
          amountTransferred: transferredAmount,
          expectedAmount: expectedAmount || 0,
          amountMatches,
          explorerUrl: `https://bscscan.com/tx/${receipt.transactionHash}`,
        },
      });
    } else {
      return res.status(400).json({ error: 'On-chain verification only applies to Crypto_USDT_TRC20 or Crypto_USDT_BEP20' });
    }
  } catch (err) {
    console.error('[OnChainVerify] Error verifying transaction:', err.message);
    return res.status(500).json({ error: 'Verification failed', message: err.message });
  }
});

// Admin Manual Top-up endpoint
app.post('/api/admin/wallet/topup', authenticateAdmin, async (req, res) => {
  const { phone, userId, minutes, amount, notes, adminName } = req.body || {};
  const minutesToAdd = parseInt(minutes, 10);
  if (isNaN(minutesToAdd) || minutesToAdd <= 0) {
    return res.status(400).json({ error: 'Valid minutes amount required' });
  }

  if (!firestoreDb) return res.status(503).json({ error: 'Firestore service unavailable' });

  try {
    let targetUid = userId;

    if (!targetUid && phone) {
      const cleanPhone = phone.trim().replace(/[\s\-\(\)]/g, '');
      const userQuery = await firestoreDb.collection('users')
        .where('phone.number', '==', cleanPhone)
        .limit(1)
        .get();

      if (!userQuery.empty) {
        targetUid = userQuery.docs[0].id;
      } else {
        const altQuery = await firestoreDb.collection('users')
          .where('phone.formattedNumber', '==', cleanPhone)
          .limit(1)
          .get();
        if (!altQuery.empty) {
          targetUid = altQuery.docs[0].id;
        }
      }
    }

    if (!targetUid) {
      return res.status(404).json({ error: 'User not found with the provided phone or ID' });
    }

    const walletRef = firestoreDb.collection('users').doc(targetUid).collection('wallet').doc('current');
    const txId = `adm_tx_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const txRef = firestoreDb.collection('recharge_transactions').doc(txId);

    const nowIso = new Date().toISOString();

    const updatedWallet = await firestoreDb.runTransaction(async (transaction) => {
      const doc = await transaction.get(walletRef);
      let data = doc.exists ? doc.data() : {
        balanceMinutes: 0,
        trialMinutes: 0,
        trialActive: false,
        trialExpiresAt: nowIso,
        totalMinutesUsed: 0,
        totalMinutesPurchased: 0,
        currency: 'BDT',
        createdAt: nowIso,
      };

      const newBalance = (data.balanceMinutes || 0) + minutesToAdd;
      const newPurchased = (data.totalMinutesPurchased || 0) + minutesToAdd;

      const updated = {
        ...data,
        balanceMinutes: newBalance,
        totalMinutesPurchased: newPurchased,
        updatedAt: nowIso,
      };

      transaction.set(walletRef, updated, { merge: true });

      transaction.set(txRef, {
        transactionId: txId,
        userId: targetUid,
        userPhone: phone || data.phone || '',
        packId: 'admin_topup',
        minutesAdded: minutesToAdd,
        amountPaid: Number(amount) || 0,
        currency: 'BDT',
        paymentMethod: 'Admin Manual Credit',
        notes: notes || `Credited by ${adminName || 'SuperAdmin'}`,
        status: 'completed',
        createdAt: nowIso,
      });

      return updated;
    });

    console.log(`[Admin] Successfully topped up ${minutesToAdd} minutes for user ${targetUid}`);
    return res.json({ success: true, userId: targetUid, wallet: updatedWallet, transactionId: txId });
  } catch (err) {
    console.error('[Admin] Error performing topup:', err.message);
    return res.status(500).json({ error: 'Top-up failed', message: err.message });
  }
});

// Admin endpoint to backfill metadata and prune expired legacy statuses (>24h old)
app.post('/api/admin/cleanup-legacy-storage', authenticateAdmin, async (req, res) => {
  if (!storageService) {
    return res.status(503).json({ error: 'Firebase Storage service is not initialized' });
  }

  try {
    const bucket = storageService.bucket();
    const stats = {
      legacyStatusesScanned: 0,
      expiredStatusesDeleted: 0,
      statusesBackfilled: 0,
      legacyAttachmentsScanned: 0,
      attachmentsBackfilled: 0,
    };

    // 1. Process legacy statuses
    const [statusFiles] = await bucket.getFiles({ prefix: 'statuses/' });
    const oneDayAgo = Date.now() - 24 * 60 * 60 * 1000;

    for (const file of statusFiles) {
      const parts = file.name.split('/');
      // Legacy format: statuses/{fileName} (depth == 2)
      if (parts.length === 2 && parts[1]) {
        stats.legacyStatusesScanned++;
        const [meta] = await file.getMetadata();
        const created = new Date(meta.timeCreated).getTime();

        // Expired status: statuses are strictly ephemeral (24 hours)
        if (created < oneDayAgo) {
          await file.delete();
          stats.expiredStatusesDeleted++;
        } else {
          // If created within 24h, backfill authorId if filename starts with userId
          const fileName = parts[1];
          const authorMatch = fileName.match(/^([a-zA-Z0-9_-]+)[_.].*/);
          if (authorMatch && (!meta.metadata || !meta.metadata.authorId)) {
            await file.setMetadata({
              metadata: {
                ...(meta.metadata || {}),
                authorId: authorMatch[1],
              },
            });
            stats.statusesBackfilled++;
          }
        }
      }
    }

    // 2. Process legacy attachments
    const [attachFiles] = await bucket.getFiles({ prefix: 'attachments/' });
    for (const file of attachFiles) {
      const parts = file.name.split('/');
      // Legacy format: attachments/{fileName} (depth == 2)
      if (parts.length === 2 && parts[1]) {
        stats.legacyAttachmentsScanned++;
        const [meta] = await file.getMetadata();
        const fileName = parts[1];
        const senderMatch = fileName.match(/^([a-zA-Z0-9_-]+)[_.].*/);
        if (senderMatch && (!meta.metadata || !meta.metadata.senderId)) {
          await file.setMetadata({
            metadata: {
              ...(meta.metadata || {}),
              senderId: senderMatch[1],
            },
          });
          stats.attachmentsBackfilled++;
        }
      }
    }

    res.json({ success: true, stats });
  } catch (err) {
    console.error('Storage cleanup error:', err.message);
    res.status(500).json({ error: 'Failed to process legacy storage cleanup', details: err.message });
  }
});

/**
 * POST /api/contacts/match
 * Securely matches user's local phonebook against registered users in Firestore.
 * Prevents client-side scraping of /users collection while enabling instant contact discovery.
 */
app.post(
  '/api/contacts/match',
  apiLimiter,
  authenticateRequest,
  validateBody(MatchContactsSchema),
  async (req, res) => {
    try {
      const { phoneNumbers } = req.body;

      if (!firestoreDb) {
        return res.status(503).json({ error: 'Firestore database service is currently unavailable' });
      }

      const sanitizedNumbers = phoneNumbers
        .slice(0, 500)
        .map((p) => String(p).trim().replace(/[\s\-\(\)\+]/g, ''))
        .filter((n) => n.length >= 6);

      const matches = [];
      const seenIds = new Set();

      // Query in batches of 30 using 'in' queries on indexed phone fields
      // Prevents full collection memory dump and limits database read costs
      for (let i = 0; i < sanitizedNumbers.length; i += 30) {
        const chunk = sanitizedNumbers.slice(i, i + 30);
        const [snap1, snap2] = await Promise.all([
          firestoreDb.collection('users').where('phone.rawNumber', 'in', chunk).get(),
          firestoreDb.collection('users').where('phone.number', 'in', chunk).get(),
        ]);

        [...snap1.docs, ...snap2.docs].forEach((doc) => {
          if (seenIds.has(doc.id)) return;
          seenIds.add(doc.id);
          const data = doc.data();
          matches.push({
            id: data.id || doc.id,
            name: data.name || '',
            avatarUrl: data.avatarUrl || '',
            phone: data.phone,
            activityStatus: data.activityStatus || 'offline',
          });
        });
      }

      res.json({ matches });
    } catch (err) {
      console.error('[Contacts] Error matching contacts:', err);
      res.status(500).json({ error: 'Internal error matching contacts' });
    }
  }
);

/**
 * POST /api/translate
 * Real-time text translation using Gemini REST API with Zod validation.
 */
app.post(
  '/api/translate',
  apiLimiter,
  authenticateRequest,
  validateBody(TranslateSchema),
  async (req, res) => {
    const { text, sourceLang, targetLang } = req.body;

    if (!GEMINI_API_KEY) {
      return res.status(503).json({ error: 'Gemini API key is not configured on the relay server' });
    }

    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`;
      const prompt = `Translate the following text from ${sourceLang || 'auto'} to ${targetLang}. Output strictly the direct translated text only, without quotes, notes, or preamble:\n\n${text}`;

      const apiRes = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [
            {
              parts: [{ text: prompt }]
            }
          ],
          generationConfig: {
            temperature: 0.1,
            maxOutputTokens: 500,
          }
        })
      });

      if (!apiRes.ok) {
        console.error('[Translate] Gemini API HTTP status:', apiRes.status);
        return res.status(502).json({ error: 'Upstream translation provider error' });
      }

      const data = await apiRes.json();
      const candidate = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || '';
      res.json({ translatedText: candidate });
    } catch (err) {
      console.error('[Translate] API error:', err);
      res.status(500).json({ error: 'Translation request failed' });
    }
  }
);

const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: '/ws/live-call' });

let activeSessionsCount = 0;

/**
 * Builds the strict, low-latency simultaneous voice interpreter system prompt.
 */
function buildInterpreterPrompt(langA, langB, autoDetect = true) {
  const langAName = langA?.englishName || langA?.name || 'Bengali';
  const langBName = langB?.englishName || langB?.name || 'English';
  const langANative = langA?.nativeName || 'বাংলা';
  const langBNative = langB?.nativeName || 'English';
  const langAHint = langA?.speechStyleHint || 'spoken conversational Bengali';
  const langBHint = langB?.speechStyleHint || 'clear conversational English';

  return `
SYSTEM ROLE: STRICT REAL-TIME BIDIRECTIONAL VOICE INTERPRETER (${langAName} [${langANative}] <-> ${langBName} [${langBNative}]).

CRITICAL OPERATING RULES:
1. AUTOMATIC BIDIRECTIONAL TRANSLATION:
   - When you hear speech in ${langAName} (${langANative}), immediately speak the translation in ${langBHint} (${langBNative}).
   - When you hear speech in ${langBName} (${langBNative}), immediately speak the translation in ${langAHint} (${langANative}).
   - If the speaker mixes both languages, translate the entire utterance into the opposite target language.
2. NEVER ANSWER OR CONVERSE:
   - You are NOT a virtual assistant. You are an invisible, transparent translation bridge on a live phone call.
   - If a caller asks "How are you?" or "Who are you?", DO NOT answer. Translate the question verbatim in the first/second person ("I", "you") into the other language.
3. ZERO COMMENTARY OR META-TEXT:
   - Never say "Here is the translation" or add explanations. Output ONLY the translated audio.
4. PRESERVE EMOTION & TONE:
   - Match the speaker's emotional tone, urgency, warmth, and natural speech rhythm.
5. SILENCE ON NOISE:
   - If you hear only background static, coughing, breathing, or silence, remain completely silent.
`.trim();
}

wss.on('connection', (clientWs, req) => {
  const clientIp = req.headers['x-forwarded-for']?.split(',')[0].trim() || req.socket.remoteAddress || 'unknown';

  // Per-IP Connection Limiting (Pre-auth socket flood protection)
  const currentIpCount = ipWsConnections.get(clientIp) || 0;
  if (currentIpCount >= MAX_WS_PER_IP) {
    console.warn(`[WSS] Connection rejected: IP ${clientIp} exceeded max WebSocket connections (${currentIpCount}/${MAX_WS_PER_IP})`);
    if (clientWs.readyState === WebSocket.OPEN) {
      clientWs.send(
        JSON.stringify({
          type: 'error',
          code: 'IP_CONCURRENT_LIMIT_EXCEEDED',
          message: 'Too many concurrent WebSocket connections from this IP address.',
        })
      );
      clientWs.close(4429, 'Rate limit: Too many connections from IP');
    }
    return;
  }
  ipWsConnections.set(clientIp, currentIpCount + 1);

  activeSessionsCount++;
  const clientId = `client_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
  console.log(`[${clientId}] Client connected from ${clientIp}`);

  let geminiWs = null;
  let isGeminiReady = false;
  let isClosing = false;
  let sessionConfig = {
    langA: { code: 'bn', englishName: 'Bengali', nativeName: 'বাংলা' },
    langB: { code: 'en', englishName: 'English', nativeName: 'English' },
    voice: DEFAULT_VOICE,
    model: DEFAULT_MODEL,
    autoDetect: true,
  };

  const heartbeatInterval = setInterval(() => {
    if (clientWs.readyState === WebSocket.OPEN) {
      clientWs.ping();
    }
  }, 20000);

  let authenticatedUid = null;
  let audioChunkCount = 0;
  let lastAudioSecond = Date.now();
  const MAX_AUDIO_CHUNKS_PER_SEC = 50;

  // Server-side minute metering interval, call tracking, and billing role
  let minuteMeteringInterval = null;
  let billedMinutes = 0;
  let activeCallId = null;
  let isCallee = false;
  let isCaller = true;

  // Pre-auth Handshake Timeout: Stalled unauthenticated connections killed after 15 seconds
  const preAuthTimeout = setTimeout(() => {
    if (!authenticatedUid && !isClosing) {
      console.warn(`[${clientId}] Pre-auth setup handshake timeout (15s) from ${clientIp}. Terminating.`);
      if (clientWs.readyState === WebSocket.OPEN) {
        clientWs.send(
          JSON.stringify({
            type: 'error',
            code: 'AUTH_TIMEOUT',
            message: 'Setup authentication handshake was not received within 15 seconds.',
          })
        );
        clientWs.close(4408, 'Pre-auth handshake timeout');
      }
      cleanup();
    }
  }, 15000);

  // Maximum call session duration limit: 60 minutes
  const sessionLimitTimer = setTimeout(() => {
    console.log(`[${clientId}] Session reached maximum 60 minute duration. Closing.`);
    if (clientWs.readyState === WebSocket.OPEN) {
      clientWs.send(
        JSON.stringify({
          type: 'error',
          code: 'SESSION_TIMEOUT',
          message: 'Live translation session reached maximum 60 minute duration limit.',
        })
      );
      clientWs.close(4408, 'Duration limit reached');
    }
  }, 60 * 60 * 1000);

  function cleanup() {
    if (isClosing) return;
    isClosing = true;
    clearTimeout(preAuthTimeout);
    clearInterval(heartbeatInterval);
    clearTimeout(sessionLimitTimer);

    if (minuteMeteringInterval) {
      clearInterval(minuteMeteringInterval);
      minuteMeteringInterval = null;
    }

    const ipCount = ipWsConnections.get(clientIp) || 1;
    if (ipCount <= 1) {
      ipWsConnections.delete(clientIp);
    } else {
      ipWsConnections.set(clientIp, ipCount - 1);
    }

    if (authenticatedUid && activeUserSessions.has(authenticatedUid)) {
      const userSessions = activeUserSessions.get(authenticatedUid);
      userSessions.delete(clientWs);
      if (userSessions.size === 0) {
        activeUserSessions.delete(authenticatedUid);
      }
    }

    // Terminate upstream Gemini WebSocket unconditionally if CONNECTING or OPEN to prevent zombie sessions
    if (geminiWs && (geminiWs.readyState === WebSocket.OPEN || geminiWs.readyState === WebSocket.CONNECTING)) {
      console.log(`[${clientId}] Terminating upstream Gemini session (state: ${geminiWs.readyState})`);
      try {
        geminiWs.removeAllListeners();
        geminiWs.terminate();
      } catch (wsErr) {
        console.warn(`[${clientId}] Error terminating upstream Gemini socket:`, wsErr.message);
      }
      geminiWs = null;
    }

    activeSessionsCount = Math.max(0, activeSessionsCount - 1);
    console.log(`[${clientId}] Session cleaned up. Active sessions: ${activeSessionsCount}`);
  }

  clientWs.on('close', (code, reason) => {
    console.log(`[${clientId}] Client disconnected (code: ${code}, reason: ${reason || 'none'})`);
    cleanup();
  });

  clientWs.on('error', (err) => {
    console.error(`[${clientId}] Client WS error:`, err);
    cleanup();
  });

  clientWs.on('message', async (data, isBinary) => {
    try {
      // 1. STRICT AUTHENTICATION GUARD:
      // The socket MUST authenticate via 'setup' handshake with a valid Firebase ID token first.
      // Unauthenticated audio packets or control messages are immediately rejected and connection terminated.
      if (!authenticatedUid) {
        if (isBinary) {
          console.warn(`[${clientId}] Unauthenticated binary packet rejected. Closing connection.`);
          if (clientWs.readyState === WebSocket.OPEN) {
            clientWs.send(
              JSON.stringify({
                type: 'error',
                code: 'UNAUTHORIZED',
                message: 'Authentication required. Please complete setup handshake first.',
              })
            );
            clientWs.close(4401, 'Unauthorized');
          }
          return;
        }

        let msg;
        try {
          msg = JSON.parse(data.toString('utf8'));
        } catch (jsonErr) {
          console.warn('[Gemini Live Relay] Malformed JSON payload received:', jsonErr.message);
          if (clientWs.readyState === WebSocket.OPEN) {
            clientWs.send(
              JSON.stringify({
                type: 'error',
                code: 'INVALID_JSON',
                message: 'Malformed JSON payload.',
              })
            );
            clientWs.close(4400, 'Invalid JSON');
          }
          return;
        }

        if (msg.type !== 'setup') {
          console.warn(`[${clientId}] Unauthorized message type '${msg.type}' before authentication. Closing.`);
          if (clientWs.readyState === WebSocket.OPEN) {
            clientWs.send(
              JSON.stringify({
                type: 'error',
                code: 'UNAUTHORIZED',
                message: 'Authentication required. Setup handshake required.',
              })
            );
            clientWs.close(4401, 'Unauthorized');
          }
          return;
        }

        // REDACT TOKEN IN LOGS (Prevents credential leakage in server console)
        const sanitizedMsg = { ...msg, token: msg.token ? '[REDACTED]' : undefined };
        console.log(`[${clientId}] Received setup handshake:`, sanitizedMsg);

        // Authenticate strictly via Firebase ID Token (Bearer header or msg.token)
        const clientToken = (msg.token && typeof msg.token === 'string')
            ? msg.token.trim()
            : (req.headers['authorization']?.startsWith('Bearer ')
                ? req.headers['authorization'].substring(7).trim()
                : null);

        if (!clientToken) {
          console.warn(`[${clientId}] Unauthorized WebSocket client: No Firebase ID token provided.`);
          clientWs.send(
            JSON.stringify({
              type: 'error',
              code: 'UNAUTHORIZED',
              message: 'Authentication required. Please provide a valid Firebase ID token.',
            })
          );
          clientWs.close(4401, 'Unauthorized');
          return;
        }

        if (!authService) {
          console.error(`[${clientId}] Firebase Auth service is unavailable on the server.`);
          clientWs.send(
            JSON.stringify({
              type: 'error',
              code: 'SERVER_ERROR',
              message: 'Authentication service unavailable.',
            })
          );
          clientWs.close(4500, 'Server Auth Unavailable');
          return;
        }

        let decodedUser = null;
        try {
          decodedUser = await authService.verifyIdToken(clientToken);
          console.log(`[${clientId}] Authenticated WebSocket Firebase user: ${decodedUser.uid}`);
        } catch (tokenErr) {
          console.warn(`[${clientId}] WebSocket ID Token verification failed: ${tokenErr.message}`);
        }

        if (!decodedUser) {
          console.warn(`[${clientId}] Unauthorized WebSocket client: Invalid ID token. Closing.`);
          clientWs.send(
            JSON.stringify({
              type: 'error',
              code: 'UNAUTHORIZED',
              message: 'Invalid or expired Firebase ID token.',
            })
          );
          clientWs.close(4401, 'Unauthorized');
          return;
        }

        // Rate Limiter: Max 2 concurrent sessions per authenticated user
        authenticatedUid = decodedUser.uid;
        clearTimeout(preAuthTimeout);
        const userSessions = activeUserSessions.get(authenticatedUid) || new Set();
        if (userSessions.size >= 2) {
          console.warn(`[${clientId}] Rate limit: User ${authenticatedUid} reached max concurrent sessions (${userSessions.size}).`);
          clientWs.send(
            JSON.stringify({
              type: 'error',
              code: 'CONCURRENT_LIMIT_EXCEEDED',
              message: 'Maximum concurrent live translation sessions reached (limit: 2).',
            })
          );
          clientWs.close(4429, 'Rate limit: Too many concurrent sessions');
          return;
        }
        userSessions.add(clientWs);
        activeUserSessions.set(authenticatedUid, userSessions);

        if (!GEMINI_API_KEY) {
          console.warn(`[${clientId}] GEMINI_API_KEY is not set in backend .env!`);
          clientWs.send(
            JSON.stringify({
              type: 'error',
              code: 'MISSING_API_KEY',
              message:
                'Backend GEMINI_API_KEY is not configured yet. Please configure GEMINI_API_KEY in the backend server .env file.',
            })
          );
          setTimeout(() => {
            try {
              clientWs.close(4403, 'MISSING_API_KEY');
            } catch (closeErr) {
              console.warn('[Gemini Live Relay] Could not close client WebSocket after MISSING_API_KEY:', closeErr.message);
            }
          }, 50);
          return;
        }

        // Security: Lock model to DEFAULT_MODEL on server. Client CANNOT override model.
        // Validate voice against Gemini Live whitelist.
        const validVoice = (msg.voice && ALLOWED_VOICES.has(msg.voice))
          ? msg.voice
          : (sessionConfig.voice || DEFAULT_VOICE);

        sessionConfig = {
          langA: msg.langA || sessionConfig.langA,
          langB: msg.langB || sessionConfig.langB,
          voice: validVoice,
          model: DEFAULT_MODEL, // Strictly locked to server DEFAULT_MODEL
          autoDetect: msg.autoDetect !== false,
        };

        // Determine Call Role (Caller vs Callee) via Firestore call record:
        activeCallId = typeof msg.callId === 'string' && msg.callId.trim().length > 0 ? msg.callId.trim() : null;
        isCallee = false;
        isCaller = true;

        if (activeCallId && firestoreDb) {
          try {
            const callDoc = await firestoreDb.collection('calls').doc(activeCallId).get();
            if (callDoc.exists) {
              const callData = callDoc.data() || {};
              if (callData.callerId && callData.callerId !== authenticatedUid && callData.calleeId === authenticatedUid) {
                // Authenticated user is the CALLEE!
                isCallee = true;
                isCaller = false;
                console.log(`[${clientId}] User ${authenticatedUid} identified as CALLEE for call ${activeCallId}. Translation granted free under telecom caller-pays policy.`);
              } else if (callData.callerId === authenticatedUid) {
                isCaller = true;
                isCallee = false;
                console.log(`[${clientId}] User ${authenticatedUid} identified as CALLER for call ${activeCallId}. Relay minute metering active.`);
              }
            }
          } catch (callLookupErr) {
            console.warn(`[${clientId}] Could not inspect call document for callId ${activeCallId}:`, callLookupErr.message);
          }
        }

        // 1.5. SERVER-SIDE PRE-CALL MINUTE & WALLET METERING GUARD:
        // Callees are exempt from billing under telecom caller-pays model.
        // For Callers / Standalone interpreters: Verify sufficient prepaid / trial balance before opening Gemini Live upstream session.
        if (!isCallee && firestoreDb) {
          try {
            const walletRef = firestoreDb.collection('users').doc(authenticatedUid).collection('wallet').doc('current');
            let walletSnap = null;
            try {
              walletSnap = await walletRef.get();
            } catch (transientErr) {
              console.warn(`[${clientId}] Transient wallet check error for ${authenticatedUid}, retrying in 300ms:`, transientErr.message);
              await new Promise((resolve) => setTimeout(resolve, 300));
              walletSnap = await walletRef.get();
            }

            if (!walletSnap || !walletSnap.exists) {
              console.warn(`[${clientId}] User ${authenticatedUid} has no wallet record in Firestore. Rejecting live session.`);
              if (clientWs.readyState === WebSocket.OPEN) {
                clientWs.send(
                  JSON.stringify({
                    type: 'error',
                    code: 'INSUFFICIENT_BALANCE',
                    message: 'No wallet found. Please initialize your wallet or recharge.',
                  })
                );
                clientWs.close(4402, 'INSUFFICIENT_BALANCE');
              }
              cleanup();
              return;
            }

            const wData = walletSnap.data() || {};
            const now = new Date();
            const trialActive = wData.trialActive && (!wData.trialExpiresAt || new Date(wData.trialExpiresAt) > now);
            const usableTrial = trialActive ? (wData.trialMinutes || 0) : 0;
            const usableBalance = wData.balanceMinutes || 0;
            const totalEffectiveMinutes = usableTrial + usableBalance;

            if (totalEffectiveMinutes <= 0) {
              console.warn(`[${clientId}] Quota rejection: Caller ${authenticatedUid} has 0 minutes. Connection rejected.`);
              if (clientWs.readyState === WebSocket.OPEN) {
                clientWs.send(
                  JSON.stringify({
                    type: 'error',
                    code: 'INSUFFICIENT_BALANCE',
                    message: 'Your translation minute balance is 0. Please recharge to use live translation.',
                  })
                );
                clientWs.close(4402, 'INSUFFICIENT_BALANCE');
              }
              cleanup();
              return;
            }

            console.log(`[${clientId}] Caller ${authenticatedUid} authorized for Gemini Live. Usable balance: ${totalEffectiveMinutes} min(s).`);
          } catch (walletCheckErr) {
            console.error(`[${clientId}] Fail-Closed: Error validating wallet balance for ${authenticatedUid}:`, walletCheckErr.message);
            if (clientWs.readyState === WebSocket.OPEN) {
              clientWs.send(
                JSON.stringify({
                  type: 'error',
                  code: 'WALLET_CHECK_UNAVAILABLE',
                  message: 'Unable to verify translation minutes. Please check your connection and retry.',
                })
              );
              clientWs.close(4402, 'INSUFFICIENT_BALANCE');
            }
            cleanup();
            return;
          }
        }

        await initGeminiSession();
        return;
      }

      // 2. AUTHENTICATED USER SESSIONS ONLY:
      if (isBinary) {
        // Audio chunk rate limiter
        const now = Date.now();
        if (now - lastAudioSecond > 1000) {
          audioChunkCount = 0;
          lastAudioSecond = now;
        }
        audioChunkCount++;
        if (audioChunkCount > MAX_AUDIO_CHUNKS_PER_SEC) {
          return; // Drop excessive audio chunks to protect quota
        }

        if (geminiWs && geminiWs.readyState === WebSocket.OPEN && isGeminiReady) {
          const base64Audio = Buffer.from(data).toString('base64');
          const realtimeFrame = {
            realtimeInput: {
              mediaChunks: [
                {
                  mimeType: 'audio/pcm;rate=16000',
                  data: base64Audio,
                },
              ],
            },
          };
          geminiWs.send(JSON.stringify(realtimeFrame));
        }
        return;
      }

      const text = data.toString('utf8');
      const msg = JSON.parse(text);

      if (msg.type === 'audio_base64') {
        // Base64 audio rate limiter
        const now = Date.now();
        if (now - lastAudioSecond > 1000) {
          audioChunkCount = 0;
          lastAudioSecond = now;
        }
        audioChunkCount++;
        if (audioChunkCount > MAX_AUDIO_CHUNKS_PER_SEC) {
          return; // Drop excessive audio chunks
        }

        if (geminiWs && geminiWs.readyState === WebSocket.OPEN && isGeminiReady && msg.data) {
          const realtimeFrame = {
            realtimeInput: {
              mediaChunks: [
                {
                  mimeType: 'audio/pcm;rate=16000',
                  data: msg.data,
                },
              ],
            },
          };
          geminiWs.send(JSON.stringify(realtimeFrame));
        }
      } else if (msg.type === 'swap_languages') {
        const temp = sessionConfig.langA;
        sessionConfig.langA = sessionConfig.langB;
        sessionConfig.langB = temp;
        console.log(
          `[${clientId}] Swapped languages: ${sessionConfig.langA.englishName} <-> ${sessionConfig.langB.englishName}`
        );
        // Re-initialize upstream session with updated roles
        await initGeminiSession();
      }
    } catch (e) {
      console.error(`[${clientId}] Error processing client message:`, e);
    }
  });

  async function initGeminiSession() {
    if (geminiWs) {
      try {
        geminiWs.close();
      } catch (err) {
        console.warn(`[${clientId}] geminiWs.close error:`, err.message);
      }
      geminiWs = null;
      isGeminiReady = false;
    }

    const geminiUrl = `wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=${GEMINI_API_KEY}`;
    console.log(`[${clientId}] Connecting upstream to Gemini Live: ${sessionConfig.model}...`);

    clientWs.send(
      JSON.stringify({
        type: 'status',
        state: 'connecting',
        message: 'Connecting to Gemini Live Multimodal API...',
      })
    );

    try {
      geminiWs = new WebSocket(geminiUrl);

      geminiWs.on('open', () => {
        console.log(`[${clientId}] Connected to Gemini Live upstream! Sending setup handshake...`);

        const systemPrompt = buildInterpreterPrompt(
          sessionConfig.langA,
          sessionConfig.langB,
          sessionConfig.autoDetect
        );

        const setupPayload = {
          setup: {
            model: sessionConfig.model,
            generationConfig: {
              responseModalities: ['AUDIO'],
              temperature: 0.2,
              speechConfig: {
                voiceConfig: {
                  prebuiltVoiceConfig: {
                    voiceName: sessionConfig.voice,
                  },
                },
              },
            },
            systemInstruction: {
              parts: [{ text: systemPrompt }],
            },
            realtimeInputConfig: {
              automaticActivityDetection: {
                disabled: false,
                startOfSpeechSensitivity: 'START_SENSITIVITY_HIGH',
                endOfSpeechSensitivity: 'END_SENSITIVITY_HIGH',
                prefixPaddingMs: 40,
                silenceDurationMs: 450,
              },
            },
            inputAudioTranscription: {},
            outputAudioTranscription: {},
          },
        };

        geminiWs.send(JSON.stringify(setupPayload));
      });

      geminiWs.on('message', (geminiData) => {
        try {
          const raw = geminiData.toString('utf8');
          const resp = JSON.parse(raw);

          // Setup complete confirmation
          if (resp.setupComplete) {
            console.log(`[${clientId}] Gemini setup completed! Ready for bidirectional audio.`);
            isGeminiReady = true;

            // Immediately deduct minute 1 upfront for CALLER only (Standard Telecom model: 0s-59s billed on connect)
            // Callees are 100% free under telecom caller-pays policy.
            // Also guard against re-deduction on language swaps (billedMinutes === 0 check).
            if (!isCallee && firestoreDb && authenticatedUid && billedMinutes === 0) {
              (async () => {
                try {
                  const walletRef = firestoreDb.collection('users').doc(authenticatedUid).collection('wallet').doc('current');
                  const deductionResult = await firestoreDb.runTransaction(async (t) => {
                    const snap = await t.get(walletRef);
                    if (!snap.exists) {
                      return { success: false, exhausted: true, remainingMinutes: 0 };
                    }
                    const data = snap.data() || {};
                    const now = new Date();
                    const trialActive = data.trialActive && (!data.trialExpiresAt || new Date(data.trialExpiresAt) > now);
                    const usableTrial = trialActive ? (data.trialMinutes || 0) : 0;
                    const usableBalance = data.balanceMinutes || 0;
                    const totalEffective = usableTrial + usableBalance;

                    if (totalEffective <= 0) {
                      return { success: false, exhausted: true, remainingMinutes: 0 };
                    }

                    let newTrial = data.trialMinutes || 0;
                    let newBalance = data.balanceMinutes || 0;
                    if (trialActive && newTrial > 0) {
                      newTrial -= 1;
                    } else if (newBalance > 0) {
                      newBalance -= 1;
                    }

                    const newTotalUsed = (data.totalMinutesUsed || 0) + 1;
                    const remainingMinutes = (trialActive ? newTrial : 0) + newBalance;

                    t.update(walletRef, {
                      trialMinutes: newTrial,
                      balanceMinutes: newBalance,
                      totalMinutesUsed: newTotalUsed,
                      updatedAt: now.toISOString(),
                    });

                    // Audit ledger record in call_billing_records
                    const billingRef = firestoreDb.collection('call_billing_records').doc();
                    const geminiCostUsd = 0.035;
                    const retailBdt = 20.0;
                    const usdToBdt = 120.0;
                    const costBdt = geminiCostUsd * usdToBdt;
                    const netProfitBdt = retailBdt - costBdt;

                    t.set(billingRef, {
                      recordId: billingRef.id,
                      callId: activeCallId || `ws_live_${authenticatedUid.substring(0, 6)}_${Date.now()}`,
                      callerId: authenticatedUid,
                      isTranslatedCall: true,
                      durationSeconds: 60,
                      minuteIndex: 1,
                      geminiCostUsd,
                      retailBdt,
                      costBdt,
                      netProfitBdt,
                      remainingMinutesAfter: remainingMinutes,
                      timestamp: now.toISOString(),
                    });

                    return {
                      success: true,
                      exhausted: remainingMinutes <= 0,
                      remainingMinutes,
                    };
                  });

                  billedMinutes = 1;
                  console.log(`[${clientId}] [SaaS Relay Metering] Upfront minute 1 deducted from caller ${authenticatedUid}. Remaining: ${deductionResult.remainingMinutes}`);

                  if (clientWs.readyState === WebSocket.OPEN) {
                    clientWs.send(
                      JSON.stringify({
                        type: 'billing_update',
                        billedMinutes,
                        remainingMinutes: deductionResult.remainingMinutes,
                        lowBalanceWarning: deductionResult.remainingMinutes <= 2,
                        role: 'caller',
                      })
                    );
                  }

                  if (deductionResult.exhausted) {
                    console.warn(`[${clientId}] Minute quota exhausted for caller ${authenticatedUid} on connect. Terminating.`);
                    if (clientWs.readyState === WebSocket.OPEN) {
                      clientWs.send(
                        JSON.stringify({
                          type: 'error',
                          code: 'MINUTES_EXHAUSTED',
                          message: 'Translation minutes exhausted. Session ended.',
                        })
                      );
                      clientWs.close(4402, 'MINUTES_EXHAUSTED');
                    }
                    cleanup();
                  }
                } catch (initialMeterErr) {
                  console.error(`[${clientId}] Initial minute deduction error:`, initialMeterErr.message);
                }
              })();
            }

            clientWs.send(
              JSON.stringify({
                type: 'ready',
                state: 'ready',
                voice: sessionConfig.voice,
                languages: `${sessionConfig.langA.englishName} ⇄ ${sessionConfig.langB.englishName}`,
                role: isCallee ? 'callee' : 'caller',
                isBilled: !isCallee,
              })
            );

            // Server-Side 60s Minute Metering Interval (CALLER ONLY):
            // Prevents caller from streaming audio indefinitely without billing.
            // Callee is completely exempt from 60s metering.
            if (!isCallee && !minuteMeteringInterval && firestoreDb && authenticatedUid) {
              minuteMeteringInterval = setInterval(async () => {
                if (isClosing || clientWs.readyState !== WebSocket.OPEN) return;
                try {
                  const walletRef = firestoreDb.collection('users').doc(authenticatedUid).collection('wallet').doc('current');
                  const deductionResult = await firestoreDb.runTransaction(async (t) => {
                    const snap = await t.get(walletRef);
                    if (!snap.exists) {
                      return { success: false, exhausted: true, remainingMinutes: 0 };
                    }
                    const data = snap.data() || {};
                    const now = new Date();
                    const trialActive = data.trialActive && (!data.trialExpiresAt || new Date(data.trialExpiresAt) > now);
                    const usableTrial = trialActive ? (data.trialMinutes || 0) : 0;
                    const usableBalance = data.balanceMinutes || 0;
                    const totalEffective = usableTrial + usableBalance;

                    if (totalEffective <= 0) {
                      return { success: false, exhausted: true, remainingMinutes: 0 };
                    }

                    let newTrial = data.trialMinutes || 0;
                    let newBalance = data.balanceMinutes || 0;
                    if (trialActive && newTrial > 0) {
                      newTrial -= 1;
                    } else if (newBalance > 0) {
                      newBalance -= 1;
                    }

                    const newTotalUsed = (data.totalMinutesUsed || 0) + 1;
                    const remainingMinutes = (trialActive ? newTrial : 0) + newBalance;

                    t.update(walletRef, {
                      trialMinutes: newTrial,
                      balanceMinutes: newBalance,
                      totalMinutesUsed: newTotalUsed,
                      updatedAt: now.toISOString(),
                    });

                    // Audit ledger record in call_billing_records
                    const billingRef = firestoreDb.collection('call_billing_records').doc();
                    const geminiCostUsd = 0.035;
                    const retailBdt = 20.0;
                    const usdToBdt = 120.0;
                    const costBdt = geminiCostUsd * usdToBdt;
                    const netProfitBdt = retailBdt - costBdt;

                    t.set(billingRef, {
                      recordId: billingRef.id,
                      callId: activeCallId || `ws_live_${authenticatedUid.substring(0, 6)}_${Date.now()}`,
                      callerId: authenticatedUid,
                      isTranslatedCall: true,
                      durationSeconds: 60,
                      minuteIndex: billedMinutes + 1,
                      geminiCostUsd,
                      retailBdt,
                      costBdt,
                      netProfitBdt,
                      remainingMinutesAfter: remainingMinutes,
                      timestamp: now.toISOString(),
                    });

                    return {
                      success: true,
                      exhausted: remainingMinutes <= 0,
                      remainingMinutes,
                    };
                  });

                  billedMinutes += 1;
                  console.log(`[${clientId}] [SaaS Relay Metering] Deducted 1 min from caller ${authenticatedUid}. Remaining: ${deductionResult.remainingMinutes}`);

                  if (clientWs.readyState === WebSocket.OPEN) {
                    clientWs.send(
                      JSON.stringify({
                        type: 'billing_update',
                        billedMinutes,
                        remainingMinutes: deductionResult.remainingMinutes,
                        lowBalanceWarning: deductionResult.remainingMinutes <= 2,
                        role: 'caller',
                      })
                    );
                  }

                  if (deductionResult.exhausted) {
                    console.warn(`[${clientId}] Minute quota exhausted for caller ${authenticatedUid}. Terminating session.`);
                    if (clientWs.readyState === WebSocket.OPEN) {
                      clientWs.send(
                        JSON.stringify({
                          type: 'error',
                          code: 'MINUTES_EXHAUSTED',
                          message: 'Translation minutes exhausted. Session ended.',
                        })
                      );
                      clientWs.close(4402, 'MINUTES_EXHAUSTED');
                    }
                    cleanup();
                  }
                } catch (meterErr) {
                  console.error(`[${clientId}] Periodic minute deduction error:`, meterErr.message);
                }
              }, 60000);
            }
            return;
          }

          // Handle server audio & transcription output
          if (resp.serverContent) {
            const sc = resp.serverContent;

            if (sc.interrupted) {
              clientWs.send(JSON.stringify({ type: 'interrupted' }));
            }

            if (sc.modelTurn && sc.modelTurn.parts) {
              for (const part of sc.modelTurn.parts) {
                // Translated Audio output (24kHz PCM16)
                if (part.inlineData && part.inlineData.mimeType?.startsWith('audio/pcm')) {
                  clientWs.send(
                    JSON.stringify({
                      type: 'audio_out',
                      mimeType: part.inlineData.mimeType,
                      data: part.inlineData.data, // base64
                    })
                  );
                }

                // Subtitle transcripts (what AI translated or transcribed)
                if (part.text) {
                  clientWs.send(
                    JSON.stringify({
                      type: 'transcript',
                      speaker: 'ai_translated',
                      text: part.text,
                    })
                  );
                }
              }
            }
          }
        } catch (err) {
          console.error(`[${clientId}] Error parsing Gemini message:`, err);
        }
      });

      geminiWs.on('error', (err) => {
        console.error(`[${clientId}] Upstream Gemini error:`, err);
        if (clientWs.readyState === WebSocket.OPEN) {
          try {
            clientWs.send(
              JSON.stringify({
                type: 'error',
                code: 'GEMINI_UPSTREAM_ERROR',
                message: 'Translation service error occurred. Please try again.',
              })
            );
            clientWs.close(4502, 'Gemini Upstream Error');
          } catch (e) {}
        }
        cleanup();
      });

      geminiWs.on('close', (code, reason) => {
        console.log(`[${clientId}] Gemini upstream closed (${code}: ${reason || 'normal'})`);
        isGeminiReady = false;
        if (clientWs.readyState === WebSocket.OPEN) {
          try {
            clientWs.send(
              JSON.stringify({
                type: 'status',
                state: 'disconnected',
                message: 'Gemini Live session disconnected',
              })
            );
            clientWs.close(1000, 'Upstream closed');
          } catch (e) {}
        }
        cleanup();
      });
    } catch (err) {
      console.error(`[${clientId}] Failed to connect to Gemini:`, err);
      if (clientWs.readyState === WebSocket.OPEN) {
        try {
          clientWs.send(
            JSON.stringify({
              type: 'error',
              code: 'CONNECTION_FAILED',
              message: 'Failed to establish connection with translation service.',
            })
          );
          clientWs.close(4503, 'Connection failed');
        } catch (e) {}
      }
      cleanup();
    }
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log('===============================================================');
  console.log(`🚀 WhatsUp Gemini Live Relay Gateway running on port ${PORT}`);
  console.log(`🌐 HTTP Health Check: http://0.0.0.0:${PORT}/health`);
  console.log(`⚡ WebSocket URL: ws://0.0.0.0:${PORT}/ws/live-call`);
  console.log(`🔑 Gemini API Key configured: ${Boolean(GEMINI_API_KEY) ? 'YES ✅' : 'NO ⚠️ (Set in .env)'}`);
  console.log(`🎙️ Default Voice Profile: ${DEFAULT_VOICE}`);
  console.log(`🧠 Default Model: ${DEFAULT_MODEL}`);
  console.log('===============================================================');
});
