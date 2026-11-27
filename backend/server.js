import http from 'http';
import express from 'express';
import { WebSocketServer, WebSocket } from 'ws';
import dotenv from 'dotenv';
import cors from 'cors';
import { z } from 'zod';
import { renderProfilePage, renderCvPage } from './pages/profile_page.js';
import { renderBookingPage, bookingIcs } from './pages/booking_page.js';
import { renderRoomPage } from './pages/room_page.js';
import { renderAppHub } from './pages/app_page.js';
import { renderDeleteAccountPage } from './pages/legal_page.js';
import { renderLanding } from './pages/landing_page.js';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import crypto from 'crypto';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { initializeApp, cert } from 'firebase-admin/app';
import { getAppCheck } from 'firebase-admin/app-check';
import { getMessaging } from 'firebase-admin/messaging';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { getStorage } from 'firebase-admin/storage';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.join(__dirname, '.env') });
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

// Whitelist of valid Gemini 2.0 / Multimodal Live Translation voices
const ALLOWED_VOICES = new Set([
  'Puck',
  'Charon',
  'Kore',
  'Fenrir',
  'Aoede',
  'Leda',
  'Autonoe',
  'Orus',
  'Umbriel',
  'Zephyr',
  // Backwards compatibility mappings for older clients
  'Sularis',
  'Perseus',
]);


const PORT = parseInt(process.env.PORT || '8080', 10);
const GEMINI_API_KEY = process.env.GEMINI_API_KEY?.trim() || '';
const DEFAULT_MODEL =
    process.env.GEMINI_LIVE_MODEL?.trim() || 'models/gemini-3.5-live-translate-preview';
const DEFAULT_VOICE = process.env.DEFAULT_VOICE?.trim() || 'Aoede';
// Text translation model (chat messages). Override with GEMINI_TEXT_MODEL
// when the default model is retired or a newer Flash model is preferred.
const TEXT_MODEL =
    process.env.GEMINI_TEXT_MODEL?.trim() || 'gemini-2.5-flash';

// Proposal writing: OpenRouter when configured, else Gemini.
const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY?.trim() || '';
const OPENROUTER_MODEL =
    process.env.OPENROUTER_MODEL?.trim() ||
    'nvidia/nemotron-3-ultra-550b-a55b:free';
const GEMINI_FALLBACK_TEXT_MODEL =
    process.env.GEMINI_FALLBACK_TEXT_MODEL?.trim() || 'gemini-2.0-flash';

const OPENROUTER_FALLBACK_MODEL =
    process.env.OPENROUTER_FALLBACK_MODEL?.trim() ||
    'google/gemma-4-31b-it:free';

// Metered TURN: when an API key is configured the relay fetches short-lived ICE
// servers per request instead of shipping static credentials to every client.
// Falls back to the static TURN_URL/TURN_SECRET setup when absent.
const METERED_API_KEY = process.env.METERED_API_KEY?.trim() || '';
const METERED_DOMAIN = (process.env.METERED_DOMAIN?.trim() || 'livocal.metered.live')
    .replace(/^https?:\/\//, '')
    .replace(/\/$/, '');
let meteredIceCache = { at: 0, servers: null };

async function fetchMeteredIceServers() {
  const now = Date.now();
  if (meteredIceCache.servers && now - meteredIceCache.at < 10 * 60 * 1000) {
    return meteredIceCache.servers;
  }
  const res = await fetch(
    `https://${METERED_DOMAIN}/api/v1/turn/credentials?apiKey=${encodeURIComponent(METERED_API_KEY)}`,
    { signal: AbortSignal.timeout(6000) }
  );
  if (!res.ok) throw new Error(`Metered HTTP ${res.status}`);
  const list = await res.json();
  if (!Array.isArray(list) || list.length === 0) {
    throw new Error('Metered returned no TURN servers');
  }
  meteredIceCache = { at: now, servers: list };
  return list;
}

function sanitizeBoundedNote(val, maxLen = 500) {
  if (val === undefined || val === null) return '';
  return String(val).trim().slice(0, maxLen);
}

// Concurrent WebSocket session tracking per user UID & per IP (Rate Limiting)
const activeUserSessions = new Map();
const ipWsConnections = new Map();
const MAX_WS_PER_IP = 8;

if (serviceAccount) {
  try {
    firebaseApp = initializeApp({
      credential: cert(serviceAccount),
      projectId: serviceAccount.project_id || 'livocal24',
      // New Firebase projects use <projectId>.firebasestorage.app; without
      // this the Admin SDK may default to the legacy appspot.com bucket and
      // account-deletion/cleanup would target the wrong bucket.
      storageBucket:
        process.env.FIREBASE_STORAGE_BUCKET?.trim() ||
        `${serviceAccount.project_id || 'livocal24'}.firebasestorage.app`,
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


const app = express();
app.set('trust proxy', 1); // Trust first-hop reverse proxy (Render / Cloud Run)
app.use(helmet({
  contentSecurityPolicy: false,
}));

// Admin Control Room Web Dashboard static files.
// The dashboard was publicly readable (154 KB of admin UI); it now asks for the
// admin secret via HTTP Basic before serving anything.
function adminUiAuth(req, res, next) {
  const secret = process.env.ADMIN_SECRET;
  if (!secret) return res.status(404).end();

  const header = req.headers.authorization || '';
  if (header.startsWith('Basic ')) {
    const decoded = Buffer.from(header.slice(6), 'base64').toString('utf8');
    const separator = decoded.indexOf(':');
    const password = separator >= 0 ? decoded.slice(separator + 1) : decoded;
    if (password === secret) {
      // Short-lived HttpOnly session so the dashboard's API calls are
      // authenticated without shipping the secret on every request.
      const secure = req.secure || req.headers['x-forwarded-proto'] === 'https';
      res.setHeader(
        'Set-Cookie',
        `${ADMIN_SESSION_COOKIE}=${adminSessionToken()}; Path=/; HttpOnly; SameSite=Strict; Max-Age=28800${secure ? '; Secure' : ''}`,
      );
      return next();
    }
  }

  res.setHeader('WWW-Authenticate', 'Basic realm="Livocal Admin", charset="UTF-8"');
  return res.status(401).send('Authentication required');
}
app.post('/admin/logout', (req, res) => {
  res.setHeader(
    'Set-Cookie',
    `${ADMIN_SESSION_COOKIE}=; Path=/; HttpOnly; SameSite=Strict; Max-Age=0`,
  );
  res.json({ ok: true });
});
app.use('/admin', adminUiAuth, express.static(path.join(__dirname, 'public/admin')));

// Secure CORS configuration: Restrict origins, allow mobile apps without Origin header
const defaultAllowedOrigins = [
  'https://livocal.app',
  'https://www.livocal.app',
  'https://livocal.web.app',
  'https://livocal.firebaseapp.com',
  'https://livocal24.web.app',
  'https://livocal24.firebaseapp.com',
  'https://livocal-relay.onrender.com',
];
const configuredOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map((o) => o.trim()).filter(Boolean)
  : [];
const allowedOrigins = Array.from(new Set([...defaultAllowedOrigins, ...configuredOrigins]));

// Canonical public origin. When PUBLIC_BASE_URL is set (for example
// https://livocal.app) every generated link uses it and the old Render host
// keeps serving, but browsers are redirected to the custom domain.
const PUBLIC_BASE_URL = (process.env.PUBLIC_BASE_URL || '').trim().replace(/\/+$/, '');
// Custom domain is the canonical origin even when the env var is missing, so
// links created from an onrender request still point at livocal.app.
const CANONICAL_ORIGIN = PUBLIC_BASE_URL || 'https://livocal.app';
const CANONICAL_HOST = CANONICAL_ORIGIN.replace(/^https?:\/\//i, '').toLowerCase();
const RENDER_HOST_SUFFIX = '.onrender.com';

/** Absolute origin used for every link we hand to users. */
function publicOrigin(req) {
  const host = String(req?.get('host') || '').toLowerCase();
  if (!host || host.endsWith(RENDER_HOST_SUFFIX)) return CANONICAL_ORIGIN;
  return 'https://' + host;
}

app.use((req, res, next) => {
  if (req.method !== 'GET' && req.method !== 'HEAD') return next();
  const host = String(req.headers.host || '').toLowerCase();
  if (host === CANONICAL_HOST) return next();
  if (!host.endsWith(RENDER_HOST_SUFFIX)) return next();
  const url = req.originalUrl || req.url || '/';
  if (
    url.startsWith('/api/') ||
    url.startsWith('/ws/') ||
    url.startsWith('/static/') ||
    url.startsWith('/admin') ||
    url === '/health'
  ) {
    return next();
  }
  return res.redirect(301, `${CANONICAL_ORIGIN}${url}`);
});

app.use(cors({
  origin: (origin, callback) => {
    // Mobile apps and native HTTP clients do not supply an Origin header
    if (!origin) return callback(null, true);
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    // Only allow localhost if explicitly running in development mode
    if (process.env.NODE_ENV === 'development' && (origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:'))) {
      return callback(null, true);
    }
    // Reject without throwing: a thrown error here surfaced as a 500 page on
    // every cross-origin preflight.
    return callback(null, false);
  },
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'idempotency-key'],
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
  highPriority: z.boolean().optional(),
  expiresAt: z.string().max(64).optional(),
});

const DeleteMessageNotifySchema = z.object({
  receiverId: z.string().min(1, 'receiverId is required').max(128),
  messageId: z.string().min(1, 'messageId is required').max(128),
});

const MatchContactsSchema = z.object({
  phoneNumbers: z.array(z.string().min(1).max(32)).min(1, 'At least 1 phone number required').max(500),
});

const TranslateSchema = z.object({
  text: z.string().min(1, 'text is required').max(5000),
  targetLang: z.string().min(2, 'targetLang is required').max(16),
  sourceLang: z.string().max(16).optional(),
});

const CallSummarySchema = z.object({
  callId: z.string().min(1, 'callId is required').max(128),
  durationSeconds: z.number().int().min(0).max(86400),
  langPair: z
    .object({
      a: z.string().max(16).optional(),
      b: z.string().max(16).optional(),
    })
    .optional(),
  transcript: z
    .array(
      z.object({
        speaker: z.enum(['me', 'client']),
        text: z.string().min(1).max(2000),
      })
    )
    .min(1, 'transcript is required')
    .max(300),
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

// ---------------------------------------------------------------------------
// Firebase App Check enforcement (opt-in via APP_CHECK_ENFORCE=true).
// When enabled, client-facing endpoints require a valid App Check token so a
// repackaged/modified client cannot spend AI budget or enumerate users.
// Admin endpoints are intentionally excluded (they use ADMIN_SECRET).
// ---------------------------------------------------------------------------
const APP_CHECK_ENFORCE = process.env.APP_CHECK_ENFORCE === 'true';

const APP_CHECK_PROTECTED_PATHS = new Set([
  '/api/translate',
  '/api/contacts/match',
  '/api/wallet/init-or-get',
  '/api/wallet/balance',
  '/api/wallet/deduct-minute',
  '/api/wallet/call-end',
  '/api/wallet/p2p-transfer',
  '/api/wallet/deposit-info',
  '/api/wallet/recipient-payment-settings',
  '/api/wallet/my-payment-settings',
  '/api/wallet/payment-request',
]);

async function verifyAppCheckToken(rawToken) {
  if (!rawToken || typeof rawToken !== 'string' || rawToken.length < 20) {
    return { ok: false, reason: 'missing' };
  }
  try {
    await getAppCheck().verifyToken(rawToken.trim());
    return { ok: true };
  } catch (err) {
    return { ok: false, reason: err.message };
  }
}

app.use(async (req, res, next) => {
  if (!APP_CHECK_ENFORCE) return next();
  if (!APP_CHECK_PROTECTED_PATHS.has(req.path)) return next();
  const result = await verifyAppCheckToken(req.headers['x-firebase-appcheck']);
  if (result.ok) return next();
  console.warn(`[AppCheck] Rejected ${req.method} ${req.path}: ${result.reason}`);
  return res.status(401).json({
    error: 'App Check verification failed. Update the app to the latest version.',
    code: 'APP_CHECK_REQUIRED',
  });
});

// Specific rate limiter for push notification endpoints (prevent notification flooding)
// Per-user rate limiting using authenticated UID (prevents collateral blocking behind reverse proxy)
const pushLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30, // max 30 push notifications per minute per authenticated user
  keyGenerator: (req) => req.user?.uid || req.ip,
  validate: { keyGeneratorIpFallback: false },
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many push notification requests. Please slow down.' },
});

// Per-user quotas for cost-bearing endpoints, keyed by the verified Firebase UID
// so a modified client cannot rotate IPs to keep spending the same budget.
const makeUserLimiter = ({ windowMs, max, message }) =>
  rateLimit({
    windowMs,
    max,
    keyGenerator: (req) => req.user?.uid || req.ip,
    validate: { keyGeneratorIpFallback: false },
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: message },
  });

const translateLimiter = makeUserLimiter({
  windowMs: 60 * 1000,
  max: 30,
  message: 'Too many translation requests. Please slow down.',
});

const contactsLimiter = makeUserLimiter({
  windowMs: 60 * 60 * 1000,
  max: 30,
  message: 'Contact matching limit reached. Try again later.',
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
    hasApiKey: Boolean(GEMINI_API_KEY),
    hasTurn: Boolean(
      METERED_API_KEY ||
        (process.env.TURN_URL &&
          (process.env.TURN_SECRET ||
            (process.env.TURN_USERNAME && process.env.TURN_CREDENTIAL)))
    ),
    turnProvider: METERED_API_KEY ? 'metered' : 'static',
    liveModel: DEFAULT_MODEL,
    textModel: TEXT_MODEL,
    proposalProvider: OPENROUTER_API_KEY
      ? 'openrouter'
      : (GEMINI_API_KEY ? 'gemini' : 'fallback'),
    openrouterModel: OPENROUTER_MODEL,
    appCheckEnforced: APP_CHECK_ENFORCE,
    publicBaseUrl: CANONICAL_ORIGIN,
    privacyRoute: true,
    timestamp: new Date().toISOString(),
  });
});

// Legacy service descriptor, now on /api (the root is the landing page).
app.get('/api', (req, res) => {
  res.json({
    service: 'Livocal Live Relay Gateway',
    version: '1.0.0',
    status: 'online',
    privacyPolicy: '/privacy-policy',
  });
});

// ── Marketing landing page ─────────────────────────────────────────────────
function renderLandingFor(req, lang) {
  return renderLanding({ lang, origin: publicOrigin(req) });
}

app.get('/', (req, res) => {
  const accept = String(req.headers['accept-language'] || '').toLowerCase();
  const prefersBangla = accept.startsWith('bn') || accept.includes(',bn');
  const explicit = String(req.query.lang || '').toLowerCase();
  if (!explicit && prefersBangla) {
    return res.redirect(302, '/bn');
  }
  if (explicit === 'bn') {
    return res.redirect(302, '/bn');
  }
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'public, max-age=300');
  return res.send(renderLandingFor(req, 'en'));
});

app.get('/bn', (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'public, max-age=300');
  return res.send(renderLandingFor(req, 'bn'));
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

      <h2>1. Ephemeral Real-Time Voice Translation</h2>
      <div class="card">
        <p><strong>Strict Ephemeral Processing:</strong> During live cross-lingual calls, spoken audio is streamed ephemerally in-memory through our secure gateway to Google Gemini Live API for instant speech translation.</p>
        <ul>
          <li>Audio frames are processed entirely in volatile RAM and are <strong>never written to persistent disk storage</strong>.</li>
          <li>Livocal does <strong>not</strong> use voice data for AI model training or profiling; upstream processing is governed by Google's Gemini API terms.</li>
          <li>When both participants speak the same language, the AI interpreter is automatically bypassed for 100% direct peer-to-peer WebRTC audio.</li>
        </ul>
      </div>

      <h2>2. Information We Collect and Process</h2>
      <ul>
        <li><strong>Account Credentials:</strong> Your verified phone number, processed via Firebase Authentication for secure SMS OTP login.</li>
        <li><strong>Profile Information:</strong> Optional display name, about text, and avatar photo stored securely in Cloud Firestore and Firebase Storage.</li>
        <li><strong>Contacts (No Harvesting):</strong> When you look up friends on Livocal, only the normalized phone numbers needed for matching are sent to an authenticated server endpoint. We do <em>not</em> store or sell your personal address book.</li>
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
      <p>All network traffic between Livocal and backend services is encrypted using <strong>TLS</strong>. Peer-to-peer audio streams use <strong>DTLS-SRTP</strong> encryption. App security PINs are protected using hardware-backed keychains (Android Keystore / iOS Keychain) and stored only as salted hashes.</p>

      <h2>5. Data Deletion and Account Removal</h2>
      <p>You have full ownership of your data. You may delete individual messages, clear chat histories, or permanently delete your account at any time via <strong>Settings &gt; Account &gt; Delete my account</strong>. Account deletion erases your profile, your inbox, attachments you own, and your authentication record. Copies of messages already delivered to another user's inbox remain with that recipient, as with any messaging service.</p>

      <h2>6. Contact Us</h2>
      <p>If you have any questions or privacy inquiries regarding Livocal, please contact our Data Protection Officer at:</p>
      <p><strong>Email:</strong> <a href="mailto:support@livocal.app">support@livocal.app</a></p>
    </div>

    <!-- Bengali Content -->
    <div id="content-bn" style="display: none;">
      <h1>Livocal গোপনীয়তা নীতি</h1>
      <div class="updated">সর্বশেষ আপডেট: অক্টোবর ২০২৬ | অবিলম্বে কার্যকর</div>

      <p><strong>Livocal</strong> ("আমরা", "আমাদের", বা "অ্যাপ") এ আপনাকে স্বাগতম। আমরা আপনার ব্যক্তিগত তথ্যের গোপনীয়তা রক্ষা করতে এবং আপনার প্রতিটি যোগাযোগ সম্পূর্ণরূপে সুরক্ষিত, ব্যক্তিগত এবং গোপনীয় রাখতে প্রতিশ্রুতিবদ্ধ।</p>

      <h2>১. ক্ষণস্থায়ী লাইভ ভয়েস অনুবাদ</h2>
      <div class="card">
        <p><strong>সম্পূর্ণ ক্ষণস্থায়ী প্রসেসিং:</strong> লাইভ দ্বিভাষিক কলের সময়, ব্যবহারকারীর কথ্য অডিও তাৎক্ষণিক অনুবাদের জন্য Google Gemini Multimodal Live API-এর মাধ্যমে শুধুমাত্র ক্ষণস্থায়ী সুরক্ষিত র‍্যামে (RAM) প্রক্রিয়া করা হয়।</p>
        <ul>
          <li>কথোপকথনের অডিও ফ্রেম কখনোই <strong>কোনো স্থায়ী ডিস্ক স্টোরেজে সংরক্ষণ বা রেকর্ড করা হয় না</strong>।</li>
          <li>Livocal আপনার ভয়েস ডেটা <strong>এআই মডেল প্রশিক্ষণ বা প্রোফাইলিং-এ ব্যবহার করে না</strong>; আপনার কথা Google-এর Gemini API শর্তাবলী অনুযায়ী প্রক্রিয়া হয়।</li>
          <li>কলের উভয় পক্ষ একই ভাষায় কথা বললে, এআই অনুবাদক স্বয়ংক্রিয়ভাবে বাইপাস হয়ে ১০০% সরাসরি P2P WebRTC সংযোগে চলে।</li>
        </ul>
      </div>

      <h2>২. যে সকল তথ্য আমরা সংগ্রহ ও প্রক্রিয়া করি</h2>
      <ul>
        <li><strong>অ্যাকাউন্ট প্রমাণীকরণ:</strong> আপনার যাচাইকৃত ফোন নম্বর, যা Firebase Authentication-এর মাধ্যমে সুরক্ষিত SMS OTP লগইনে ব্যবহৃত হয়।</li>
        <li><strong>প্রোফাইল তথ্য:</strong> আপনার ডিসপ্লে নাম, স্ট্যাটাস বায়ো এবং প্রোফাইল ছবি যা Cloud Firestore ও Firebase Storage-এ সুরক্ষিত থাকে।</li>
        <li><strong>কন্টাক্ট তালিকা (হার্ভেস্টিং নয়):</strong> বন্ধুদের খুঁজে পেতে শুধু প্রয়োজনীয় ফোন নম্বর স্বাভাবিক (normalize) করে নিরাপদ সার্ভার এন্ডপয়েন্টে পাঠানো হয়। আপনার সম্পূর্ণ অ্যাড্রেস বুক সংরক্ষণ বা কারো কাছে বিক্রি করা হয় না।</li>
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
      <p>অ্যাপ এবং সার্ভারের মধ্যকার সমস্ত যোগাযোগ <strong>TLS</strong> দ্বারা এনক্রিপ্ট করা। সরাসরি অডিও স্ট্রিমগুলো <strong>DTLS-SRTP</strong> এনক্রিপশন ব্যবহার করে। অ্যাপ সিকিউরিটি পিন ডিভাইসের হার্ডওয়্যার-সমর্থিত Keystore/Keychain-এ শুধুমাত্র সল্টেড হ্যাশ হিসেবে সংরক্ষিত হয়।</p>

      <h2>৫. অ্যাকাউন্ট ও ডেটা অপসারণ</h2>
      <p>আপনার তথ্যের সম্পূর্ণ নিয়ন্ত্রণ আপনার হাতে। আপনি যেকোনো সময় নির্দিষ্ট বার্তা মুছতে, চ্যাট হিস্ট্রি পরিষ্কার করতে বা <strong>Settings &gt; Account &gt; Delete my account</strong> থেকে আপনার অ্যাকাউন্ট স্থায়ীভাবে মুছে ফেলতে পারেন। অ্যাকাউন্ট মুছলে আপনার প্রোফাইল, ইনবক্স, আপনার মালিকানাধীন অ্যাটাচমেন্ট এবং লগইন রেকর্ড মুছে যায়। অন্য ব্যবহারকারীর ইনবক্সে ইতিমধ্যে পৌঁছে যাওয়া বার্তার কপি তাদের কাছে থাকে।</p>

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

// Public freelancer profile: shareable page that works without the app.
// ── Public share snapshots (invoices, proposals) ────────────────────────────
const InvoiceShareSchema = z.object({
  ownerName: z.string().max(80).optional(),
  number: z.string().min(1).max(40),
  clientName: z.string().max(80).optional(),
  items: z
    .array(
      z.object({
        description: z.string().max(300),
        qty: z.number().min(0).max(100000),
        rate: z.number().min(0).max(10000000),
      })
    )
    .max(50),
  currency: z.string().max(8).optional(),
  taxPct: z.number().min(0).max(100).optional(),
  discount: z.number().min(0).max(10000000).optional(),
  total: z.number().min(0).max(100000000),
  status: z.string().max(16).optional(),
  dueDate: z.string().max(40).optional().nullable(),
  notes: z.string().max(1000).optional(),
});

const ProposalShareSchema = z.object({
  ownerName: z.string().max(80).optional(),
  clientName: z.string().max(80).optional(),
  headline: z.string().min(1).max(2000),
  scope: z.string().max(4000).optional(),
  timeline: z.string().max(1000).optional(),
  price: z.string().max(1000).optional(),
  terms: z.string().max(2000).optional(),
});

const profileViewThrottle = new Map();

function shareToken() {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  let token = '';
  for (let i = 0; i < 24; i += 1) {
    token += alphabet[Math.floor(Math.random() * alphabet.length)];
  }
  return token;
}

app.post(
  '/api/share/invoice',
  apiLimiter,
  authenticateRequest,
  validateBody(InvoiceShareSchema),
  async (req, res) => {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });
    if (!firestoreDb) return res.status(503).json({ error: 'unavailable' });
    try {
      let ownerName = req.body.ownerName || '';
      if (!ownerName) {
        const userSnap = await firestoreDb.collection('users').doc(uid).get();
        ownerName = userSnap.exists ? (userSnap.data()?.name || '') : '';
      }
      const token = shareToken();
      await firestoreDb
        .collection('public_invoices')
        .doc(token)
        .set({
          ...req.body,
          ownerUid: uid,
          ownerName,
          createdAt: new Date().toISOString(),
        });
      return res.json({ ok: true, token });
    } catch (err) {
      console.error('[Share] invoice error:', err.message);
      return res.status(500).json({ error: 'failed' });
    }
  }
);

app.post(
  '/api/share/proposal',
  apiLimiter,
  authenticateRequest,
  validateBody(ProposalShareSchema),
  async (req, res) => {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });
    if (!firestoreDb) return res.status(503).json({ error: 'unavailable' });
    try {
      let ownerName = req.body.ownerName || '';
      if (!ownerName) {
        const userSnap = await firestoreDb.collection('users').doc(uid).get();
        ownerName = userSnap.exists ? (userSnap.data()?.name || '') : '';
      }
      const token = shareToken();
      await firestoreDb
        .collection('public_proposals')
        .doc(token)
        .set({
          ...req.body,
          ownerUid: uid,
          ownerName,
          createdAt: new Date().toISOString(),
        });
      return res.json({ ok: true, token });
    } catch (err) {
      console.error('[Share] proposal error:', err.message);
      return res.status(500).json({ error: 'failed' });
    }
  }
);

// ── Username (custom profile link) ──────────────────────────────────────────
const PROFILE_RESERVED = new Set([
  'admin', 'api', 'app', 'book', 'u', 'p', 'help', 'support', 'login',
  'settings', 'www', 'mail', 'root', 'livocal',
]);

const UsernameSchema = z.object({
  username: z.string().min(3).max(24),
});

function normalizeUsername(raw) {
  const value = String(raw || '').trim().toLowerCase();
  if (!/^[a-z0-9](?:[a-z0-9-]{1,22}[a-z0-9])$/.test(value)) return null;
  if (PROFILE_RESERVED.has(value)) return null;
  return value;
}

app.post(
  '/api/profile/username',
  apiLimiter,
  authenticateRequest,
  validateBody(UsernameSchema),
  async (req, res) => {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });
    if (!firestoreDb) return res.status(503).json({ error: 'unavailable' });

    const username = normalizeUsername(req.body.username);
    if (!username) return res.status(400).json({ error: 'invalid_username' });

    try {
      await firestoreDb.runTransaction(async (transaction) => {
        const claimRef = firestoreDb.collection('profiles_slug').doc(username);
        const claimSnap = await transaction.get(claimRef);
        const owner = claimSnap.exists ? (claimSnap.data()?.uid || '') : '';
        if (owner && owner !== uid) throw new Error('taken');

        const profileRef = firestoreDb.collection('profiles').doc(uid);
        const profileSnap = await transaction.get(profileRef);
        const now = new Date().toISOString();

        transaction.set(
          claimRef,
          { uid, updatedAt: now },
          { merge: true }
        );
        if (profileSnap.exists) {
          transaction.update(profileRef, {
            username,
            slug: username,
            updatedAt: now,
          });
        } else {
          transaction.set(profileRef, {
            username,
            slug: username,
            published: false,
            updatedAt: now,
          });
        }
      });
      return res.json({ ok: true, username });
    } catch (err) {
      if (err.message === 'taken') {
        return res.status(409).json({ error: 'username_taken' });
      }
      console.error('[Username] error:', err.message);
      return res.status(500).json({ error: 'failed' });
    }
  }
);

app.get('/api/public/profile/:slug', async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'unavailable' });
  const slug = String(req.params.slug || '').trim().toLowerCase();
  if (!/^[a-z0-9-]{3,32}$/.test(slug)) return res.status(404).json({ error: 'not_found' });
  try {
    const claim = await firestoreDb.collection('profiles_slug').doc(slug).get();
    const uid = claim.exists ? (claim.data()?.uid || '') : '';
    if (!uid) return res.status(404).json({ error: 'not_found' });
    const snap = await firestoreDb.collection('profiles').doc(uid).get();
    if (!snap.exists) return res.status(404).json({ error: 'not_found' });
    const p = snap.data() || {};
    if (p.published !== true) return res.status(404).json({ error: 'not_found' });
    res.setHeader('Cache-Control', 'public, max-age=60');
    return res.json({
      slug,
      displayName: p.displayName || '',
      headline: p.headline || '',
      bio: p.bio || '',
      skills: Array.isArray(p.skills) ? p.skills : [],
      languages: Array.isArray(p.languages) ? p.languages : [],
      rate: p.rate || null,
      availability: p.availability || '',
      portfolio: Array.isArray(p.portfolio) ? p.portfolio : [],
      services: Array.isArray(p.services) ? p.services : [],
      caseStudies: Array.isArray(p.caseStudies) ? p.caseStudies : [],
      experience: Array.isArray(p.experience) ? p.experience : [],
      education: Array.isArray(p.education) ? p.education : [],
      certifications: Array.isArray(p.certifications) ? p.certifications : [],
      faq: Array.isArray(p.faq) ? p.faq : [],
      accentColor: p.accentColor || 'emerald',
      sectionOrder: Array.isArray(p.sectionOrder) ? p.sectionOrder : [],
      avatarUrl: p.avatarUrl || '',
      coverUrl: p.coverUrl || '',
      responseTime: p.responseTime || '',
      githubUrl: p.githubUrl || '',
      linkedinUrl: p.linkedinUrl || '',
      websiteUrl: p.websiteUrl || '',
      cvUrl: p.cvUrl || '',
      projectsDone: Number(p.projectsDone || 0),
      yearsExperience: Number(p.yearsExperience || 0),
      clientsCount: Number(p.clientsCount || 0),
      ratingAvg: Number(p.ratingAvg || 0),
      ratingCount: Number(p.ratingCount || 0),
      verified: p.published === true && Number(p.ratingCount || 0) > 0,
    });
  } catch (err) {
    console.error('[PublicProfile] error:', err.message);
    return res.status(500).json({ error: 'failed' });
  }
});

app.get('/cv/:slug', async (req, res) => {
  if (!firestoreDb) return res.status(503).send('unavailable');
  try {
    const host = await loadHostBySlug(req.params.slug);
    if (!host) return res.status(404).send('Not found');
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'public, max-age=60');
    return res.send(
      renderCvPage({
        profile: host.profile,
        username: host.slug,
        origin: publicOrigin(req),
      })
    );
  } catch (err) {
    console.error('[CV] page error:', err.message);
    return res.status(500).send('error');
  }
});
app.get('/api/public/uid/:slug', async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'unavailable' });
  try {
    const host = await loadHostBySlug(req.params.slug);
    if (!host) return res.status(404).json({ error: 'not_found' });
    return res.json({
      uid: host.uid,
      displayName: host.profile.displayName || '',
      avatarUrl: host.profile.avatarUrl || '',
    });
  } catch (err) {
    console.error('[PublicUid] error:', err.message);
    return res.status(500).json({ error: 'failed' });
  }
});

app.get('/m/:slug', async (req, res) => {
  if (!firestoreDb) return res.status(503).send('unavailable');
  try {
    const host = await loadHostBySlug(req.params.slug);
    if (!host) return res.status(404).send('Not found');
    const esc = (value) =>
      String(value == null ? '' : value)
        .replace(/&/g, '&amp;').replace(/</g, '&lt;')
        .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    const name = esc(host.profile.displayName || 'this freelancer');
    const slug = esc(host.slug);
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'no-store');
    return res.send(`<!DOCTYPE html>
<html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Message ${name} — Livocal</title>
<style>
  body{margin:0;background:#04070d;color:#f1f5f9;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;display:flex;min-height:100vh;align-items:center;justify-content:center;padding:20px}
  .card{max-width:420px;width:100%;background:#0c1424;border:1px solid rgba(255,255,255,.08);border-radius:18px;padding:24px;text-align:center}
  h1{font-size:20px;margin:0 0 8px} p{color:#8b98ad;font-size:13px;line-height:1.6}
  .btn{display:block;margin-top:14px;padding:13px;border-radius:12px;text-decoration:none;font-weight:800;font-size:13.5px}
  .primary{background:#34d399;color:#04120c} .ghost{border:1px solid rgba(255,255,255,.15);color:#f1f5f9}
</style></head><body>
<div class="card">
  <h1>Message ${name}</h1>
  <p>Opening Livocal… If nothing happens, install/open the Livocal app.</p>
  <a class="btn primary" href="livocal://chat/${slug}">Open in Livocal</a>
  <a class="btn ghost" href="/u/${slug}">View profile</a>
  <a class="btn ghost" href="/book/${slug}">Book a call instead</a>
</div>
<script>
  setTimeout(function(){ location.href = 'livocal://chat/${slug}'; }, 150);
</script>
</body></html>`);
  } catch (err) {
    console.error('[Message] page error:', err.message);
    return res.status(500).send('error');
  }
});
// ── Browser guest rooms (F7.1, voice only) ─────────────────────────────────
const JOIN_SECRET =
  process.env.JOIN_SECRET?.trim() ||
  process.env.ADMIN_SECRET?.trim() ||
  'livocal-join-dev';
const joinRooms = new Map();

function signJoinToken(roomId, role, ttlSeconds = 7200) {
  const exp = Math.floor(Date.now() / 1000) + ttlSeconds;
  const payload = `${roomId}.${role}.${exp}`;
  const sig = crypto
    .createHmac('sha256', JOIN_SECRET)
    .update(payload)
    .digest('base64url');
  return `${payload}.${sig}`;
}

function verifyJoinToken(token) {
  const parts = String(token || '').split('.');
  if (parts.length !== 4) return null;
  const [roomId, role, expRaw, sig] = parts;
  const expected = crypto
    .createHmac('sha256', JOIN_SECRET)
    .update(`${roomId}.${role}.${expRaw}`)
    .digest('base64url');
  const a = Buffer.from(sig);
  const b = Buffer.from(expected);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return null;
  if (Number(expRaw) * 1000 < Date.now()) return null;
  if (role !== 'host' && role !== 'guest') return null;
  return { roomId, role };
}

const JOIN_ROOM_TTL_MS = 2 * 60 * 60 * 1000;

function memoryRoom(roomId, hostName, expires) {
  let room = joinRooms.get(roomId);
  if (!room) {
    room = {
      host: null,
      guest: null,
      hostName: hostName || 'Livocal',
      expires: expires || Date.now() + JOIN_ROOM_TTL_MS,
    };
    joinRooms.set(roomId, room);
  }
  return room;
}

/**
 * Reuses the host's live room when it is still open so a browser reload or a
 * relay restart does not invalidate the guest link that was already shared.
 */
async function getOrCreateJoinRoom(slug, hostName) {
  const name = hostName || 'Livocal';
  const now = Date.now();
  if (firestoreDb) {
    try {
      const snapshot = await firestoreDb
        .collection('join_rooms')
        .where('slug', '==', slug)
        .limit(5)
        .get();
      let best = null;
      snapshot.forEach((doc) => {
        const data = doc.data() || {};
        const exp = data.expiresAt?.toMillis
          ? data.expiresAt.toMillis()
          : Number(data.expiresAt) || 0;
        if (exp > now && (!best || exp > best.expires)) {
          best = { roomId: doc.id, exp, hostName: data.hostName || name };
        }
      });
      if (best) {
        memoryRoom(best.roomId, best.hostName, best.exp);
        return {
          roomId: best.roomId,
          hostName: best.hostName,
          expires: best.exp,
        };
      }
      const roomId = crypto.randomBytes(9).toString('hex');
      const expires = now + JOIN_ROOM_TTL_MS;
      await firestoreDb
        .collection('join_rooms')
        .doc(roomId)
        .set({
          slug,
          roomId,
          hostName: name,
          createdAt: FieldValue.serverTimestamp(),
          expiresAt: Timestamp.fromMillis(expires),
        });
      memoryRoom(roomId, name, expires);
      return { roomId, hostName: name, expires };
    } catch (err) {
      console.warn('[GuestRoom] registry unavailable:', err.message);
    }
  }
  const roomId = crypto.randomBytes(9).toString('hex');
  const expires = now + JOIN_ROOM_TTL_MS;
  memoryRoom(roomId, name, expires);
  return { roomId, hostName: name, expires };
}

async function loadJoinRoom(roomId) {
  const cached = joinRooms.get(roomId);
  if (cached) return cached;
  if (!firestoreDb) return null;
  try {
    const doc = await firestoreDb.collection('join_rooms').doc(roomId).get();
    if (!doc.exists) return null;
    const data = doc.data() || {};
    const exp = data.expiresAt?.toMillis
      ? data.expiresAt.toMillis()
      : Number(data.expiresAt) || 0;
    if (exp < Date.now()) return null;
    return memoryRoom(roomId, data.hostName, exp);
  } catch (err) {
    console.warn('[GuestRoom] room load failed:', err.message);
    return null;
  }
}

setInterval(() => {
  const now = Date.now();
  for (const [roomId, room] of joinRooms.entries()) {
    if (room.expires < now && !room.host && !room.guest) {
      joinRooms.delete(roomId);
    }
  }
}, 5 * 60 * 1000).unref();

app.get('/api/public/ice', apiLimiter, async (req, res) => {
  const iceServers = [
    { urls: 'stun:stun.l.google.com:19302' },
    { urls: 'stun:stun1.l.google.com:19302' },
  ];
  if (METERED_API_KEY) {
    try {
      const metered = await fetchMeteredIceServers();
      iceServers.push(...metered);
    } catch (err) {
      console.warn('[GuestICE] Metered failed:', err.message);
    }
  }
  res.setHeader('Cache-Control', 'no-store');
  return res.json({ iceServers });
});

// ── Browser translation helper (F7.2 v1: spoken translation) ───────────────
const guestTranslateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 25,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'rate_limited' },
});

const TRANSLATE_MAX_CHARS = 1400000; // ~700 KB of audio as base64

app.post('/api/public/translate-audio', guestTranslateLimiter, async (req, res) => {
  if (!GEMINI_API_KEY) {
    return res.status(503).json({ error: 'translation_unavailable' });
  }
  const body = req.body || {};
  const audio = typeof body.audio === 'string' ? body.audio : '';
  const mimeType =
    typeof body.mimeType === 'string' && body.mimeType
      ? body.mimeType
      : 'audio/wav';
  const target = String(body.targetLanguage || 'English').slice(0, 40);
  const source = String(body.sourceLanguage || '').slice(0, 40);
  if (!audio) return res.status(400).json({ error: 'missing_audio' });
  if (audio.length > TRANSLATE_MAX_CHARS) {
    return res.status(413).json({ error: 'audio_too_large' });
  }

  const prompt =
    'You are a live interpreter on a freelance client call. ' +
    (source ? `The speaker is talking in ${source}. ` : '') +
    `Translate what you hear into ${target}. ` +
    'Return ONLY the translated sentence, nothing else. Keep names, numbers, ' +
    'prices and dates exactly. If the audio has no clear speech, return an ' +
    'empty string.';

  try {
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/` +
      `${TEXT_MODEL}:generateContent?key=${GEMINI_API_KEY}`;
    const apiRes = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: prompt },
              { inlineData: { mimeType, data: audio } },
            ],
          },
        ],
        generationConfig: { temperature: 0.2, maxOutputTokens: 220 },
      }),
    });
    if (!apiRes.ok) {
      console.warn('[Translate] Gemini HTTP', apiRes.status);
      return res.status(502).json({ error: 'translate_failed' });
    }
    const data = await apiRes.json();
    const text = (data.candidates?.[0]?.content?.parts || [])
      .map((part) => part.text || '')
      .join('')
      .trim();
    res.setHeader('Cache-Control', 'no-store');
    return res.json({ ok: true, text });
  } catch (err) {
    console.error('[Translate] error:', err.message);
    return res.status(500).json({ error: 'translate_error' });
  }
});

// ── Account deletion page (Google Play requirement) ────────────────────────
app.get('/delete-account', (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'public, max-age=3600');
  return res.send(
    renderDeleteAccountPage({
      origin: publicOrigin(req),
      supportEmail: process.env.SUPPORT_EMAIL || 'support@livocal.app',
    })
  );
});

// ── Installable web hub (no app install) ───────────────────────────────────
app.use(
  '/static',
  express.static(path.join(__dirname, 'public', 'pwa'), { maxAge: '7d' })
);

// Landing page assets (CSS, JS, logo, fonts)
app.use(
  '/site',
  express.static(path.join(__dirname, 'public', 'site'), {
    maxAge: '7d',
    etag: true,
  })
);

app.get('/manifest.webmanifest', (req, res) => {
  const slug = String(req.query.slug || '').replace(/[^a-z0-9_-]/gi, '');
  const start = slug ? `/app/${slug}` : '/app';
  res.setHeader('Content-Type', 'application/manifest+json; charset=utf-8');
  res.setHeader('Cache-Control', 'public, max-age=300');
  return res.send(
    JSON.stringify({
      name: 'Livocal',
      short_name: 'Livocal',
      description: 'Live voice translation and booking for freelancers',
      start_url: start,
      scope: '/',
      display: 'standalone',
      background_color: '#04070d',
      theme_color: '#04070d',
      icons: [
        {
          src: '/static/icon-192.png',
          sizes: '192x192',
          type: 'image/png',
          purpose: 'any',
        },
        {
          src: '/static/icon-512.png',
          sizes: '512x512',
          type: 'image/png',
          purpose: 'any maskable',
        },
      ],
    })
  );
});

// ── Site plumbing: favicon, robots, sitemap, Android App Links ─────────────
const ANDROID_CERT_SHA256 = (process.env.ANDROID_CERT_SHA256 || '')
  .split(',')
  .map((value) => value.trim())
  .filter(Boolean);

app.get('/favicon.ico', (req, res) => res.redirect(301, '/static/icon-192.png'));

app.get('/robots.txt', (req, res) => {
  const origin = publicOrigin(req);
  res.setHeader('Cache-Control', 'public, max-age=3600');
  res.type('text/plain').send(
    [
      'User-agent: *',
      'Allow: /',
      'Disallow: /api/',
      'Disallow: /admin',
      'Disallow: /join/',
      '',
      `Sitemap: ${origin}/sitemap.xml`,
      '',
    ].join('\n')
  );
});

app.get('/sitemap.xml', async (req, res) => {
  const origin = publicOrigin(req);
  const urls = ['/', '/bn', '/privacy-policy', '/terms-of-service', '/delete-account'];
  try {
    if (firestoreDb) {
      const snapshot = await firestoreDb
        .collection('profiles')
        .where('published', '==', true)
        .limit(500)
        .get();
      snapshot.forEach((doc) => {
        const data = doc.data() || {};
        const slug = String(data.slug || data.username || '').toLowerCase();
        if (/^[a-z0-9-]{3,32}$/.test(slug)) {
          urls.push(`/u/${slug}`, `/book/${slug}`, `/cv/${slug}`, `/app/${slug}`);
        }
      });
    }
  } catch (err) {
    console.warn('[Sitemap] profile list failed:', err.message);
  }
  const body =
    '<?xml version="1.0" encoding="UTF-8"?>\n' +
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
    urls.map((path) => `  <url><loc>${origin}${path}</loc></url>`).join('\n') +
    '\n</urlset>\n';
  res.setHeader('Cache-Control', 'public, max-age=3600');
  res.type('application/xml').send(body);
});

// Verified Android App Links: https://livocal.app/u/<name> opens the app.
app.get('/.well-known/assetlinks.json', (req, res) => {
  if (!ANDROID_CERT_SHA256.length) {
    return res.status(404).json({ error: 'not_configured' });
  }
  res.setHeader('Cache-Control', 'public, max-age=3600');
  return res.json([
    {
      relation: ['delegate_permission/common.handle_all_urls'],
      target: {
        namespace: 'android_app',
        package_name: 'com.livocal.app',
        sha256_cert_fingerprints: ANDROID_CERT_SHA256,
      },
    },
  ]);
});

app.get('/app/:slug', async (req, res) => {
  if (!firestoreDb) return res.status(503).send('unavailable');
  try {
    const host = await loadHostBySlug(req.params.slug);
    if (!host) return res.status(404).send('Not found');
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'public, max-age=120');
    return res.send(
      renderAppHub({
        slug: req.params.slug,
        displayName: host.profile.displayName,
        headline: host.profile.headline,
        avatarUrl: host.profile.avatarUrl,
      })
    );
  } catch (err) {
    console.error('[AppHub] error:', err.message);
    return res.status(500).send('error');
  }
});

// ── Landing page helpers: demo translation, waitlist, counters ─────────────
const demoLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { ok: false, error: 'rate_limited' },
});

const waitlistLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: 3,
  standardHeaders: true,
  legacyHeaders: false,
  message: { ok: false, error: 'rate_limited' },
});

const eventLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
  message: { ok: false, error: 'rate_limited' },
});

const DEMO_DAILY_CAP = Math.max(0, Number(process.env.DEMO_DAILY_CAP || 300));

/** Increments the global demo counter and reports whether the call is allowed. */
async function allowDemoCall() {
  if (!firestoreDb) return true;
  const day = new Date().toISOString().slice(0, 10);
  const ref = firestoreDb.collection('stats').doc('demo');
  try {
    const snapshot = await ref.get();
    const data = snapshot.data() || {};
    if (data.day !== day) {
      await ref.set(
        { day, count: 1, updatedAt: FieldValue.serverTimestamp() },
        { merge: true }
      );
      return true;
    }
    if (Number(data.count || 0) >= DEMO_DAILY_CAP) return false;
    await ref.update({
      count: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return true;
  } catch (err) {
    console.warn('[Demo] counter failed:', err.message);
    return true;
  }
}

app.post('/api/public/demo-translate', demoLimiter, async (req, res) => {
  const body = req.body || {};
  const text = String(body.text || '').trim().slice(0, 200);
  const from = body.from === 'en' ? 'en' : 'bn';
  if (text.length < 2) {
    return res.status(400).json({ ok: false, error: 'invalid_text' });
  }
  if (!GEMINI_API_KEY) {
    return res.status(503).json({ ok: false, error: 'unavailable' });
  }
  const allowed = await allowDemoCall();
  if (!allowed) {
    return res.status(429).json({ ok: false, error: 'daily_cap' });
  }
  const target = from === 'bn' ? 'English' : 'Bangla';
  const prompt =
    `Translate the following ${from === 'bn' ? 'Bangla' : 'English'} sentence ` +
    `into ${target}. Return only the translation, no quotes and no explanation.\n\n` +
    text;
  try {
    // Model availability differs per API key; try the configured model first
    // and fall back to widely available ones before giving up.
    const models = Array.from(
      new Set(
        [
          TEXT_MODEL,
          'gemini-2.5-flash-lite',
          GEMINI_FALLBACK_TEXT_MODEL,
          'gemini-1.5-flash',
        ].filter(Boolean)
      )
    );
    let lastStatus = 0;
    let lastDetail = '';
    for (const model of models) {
      try {
        const url =
          `https://generativelanguage.googleapis.com/v1beta/models/` +
          `${model}:generateContent?key=${GEMINI_API_KEY}`;
        const apiRes = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: { temperature: 0.2, maxOutputTokens: 200 },
          }),
          signal: AbortSignal.timeout(8000),
        });
        if (!apiRes.ok) {
          lastStatus = apiRes.status;
          const detail = await apiRes.text().catch(() => '');
          lastDetail = detail.slice(0, 300);
          console.warn('[Demo]', model, 'HTTP', apiRes.status, detail.slice(0, 160));
          continue;
        }
        const data = await apiRes.json();
        const raw = (data.candidates?.[0]?.content?.parts || [])
          .map((part) => part.text || '')
          .join('')
          .trim();
        if (!raw) {
          lastStatus = 200;
          console.warn('[Demo]', model, 'returned no text');
          continue;
        }
        return res.json({
          ok: true,
          text: raw.replace(/^["'“”‘’]+|["'“”‘’]+$/g, '').trim(),
          model,
        });
      } catch (err) {
        console.warn('[Demo]', model, 'failed:', err.name);
        lastStatus = 0;
      }
    }
    return res.status(502).json({
      ok: false,
      error: 'gemini_' + (lastStatus || 'timeout'),
      detail: lastDetail,
    });
  } catch (err) {
    console.warn('[Demo] translate failed:', err.name, err.message);
    return res.status(502).json({ ok: false, error: 'translate_failed' });
  }
});

app.post('/api/public/waitlist', waitlistLimiter, async (req, res) => {
  const body = req.body || {};
  const raw = String(body.contact || '').trim().slice(0, 120);
  const locale = body.locale === 'bn' ? 'bn' : 'en';
  const source = String(body.source || 'landing').slice(0, 40);
  if (!raw) return res.status(400).json({ ok: false, error: 'missing_contact' });

  const compact = raw.replace(/[\s-]/g, '');
  const isPhone = /^(\+?8801[3-9]\d{8}|01[3-9]\d{8})$/.test(compact);
  const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(raw);

  let contact;
  if (isEmail) {
    contact = raw.toLowerCase();
  } else if (isPhone) {
    contact = compact.startsWith('0')
      ? '+88' + compact
      : '+' + compact.replace(/^\+?/, '');
  } else {
    return res.status(400).json({ ok: false, error: 'invalid_contact' });
  }

  if (!firestoreDb) return res.status(503).json({ ok: false, error: 'unavailable' });

  const id = crypto.createHash('sha256').update(contact).digest('hex').slice(0, 32);
  const ip = String(req.headers['x-forwarded-for'] || req.ip || '')
    .split(',')[0]
    .trim();
  const ipHash = ip
    ? crypto.createHash('sha256').update(ip).digest('hex').slice(0, 16)
    : '';

  try {
    await firestoreDb.collection('waitlist').doc(id).set(
      {
        contact,
        locale,
        source,
        ipHash,
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    return res.json({ ok: true });
  } catch (err) {
    console.error('[Waitlist] write failed:', err.message);
    return res.status(500).json({ ok: false, error: 'failed' });
  }
});

app.post('/api/public/landing-event', eventLimiter, async (req, res) => {
  const type = String(req.body?.type || '');
  if (!['view', 'cta', 'waitlist', 'demo'].includes(type)) {
    return res.status(204).end();
  }
  if (firestoreDb) {
    try {
      await firestoreDb
        .collection('stats')
        .doc('landing')
        .set(
          {
            [type]: FieldValue.increment(1),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
    } catch (err) {
      // Analytics must never break the page.
    }
  }
  return res.status(204).end();
});

app.get('/room/:slug', async (req, res) => {
  if (!firestoreDb) return res.status(503).send('unavailable');
  try {
    const host = await loadHostBySlug(req.params.slug);
    if (!host) return res.status(404).send('Not found');
    const room = await getOrCreateJoinRoom(
      req.params.slug,
      host.profile.displayName || 'Livocal'
    );
    const hostToken = signJoinToken(room.roomId, 'host');
    const guestToken = signJoinToken(room.roomId, 'guest');
    const guestUrl = `${publicOrigin(req)}/join/${guestToken}`;
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'no-store');
    return res.send(
      renderRoomPage({
        role: 'host',
        roomId: room.roomId,
        token: hostToken,
        peerName: room.hostName || 'Livocal',
        guestUrl,
      })
    );
  } catch (err) {
    console.error('[GuestRoom] host page error:', err.message);
    return res.status(500).send('error');
  }
});

// Mobile host screen: same room as the browser page, so the link works for
// both the in-app WebView host and a desktop browser host.
app.get('/api/public/room/:slug', apiLimiter, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'unavailable' });
  try {
    const host = await loadHostBySlug(req.params.slug);
    if (!host) return res.status(404).json({ error: 'not_found' });
    const room = await getOrCreateJoinRoom(
      req.params.slug,
      host.profile.displayName || 'Livocal'
    );
    const guestToken = signJoinToken(room.roomId, 'guest');
    res.setHeader('Cache-Control', 'no-store');
    return res.json({
      roomId: room.roomId,
      hostName: room.hostName || 'Livocal',
      hostUrl: `${publicOrigin(req)}/room/${encodeURIComponent(
        req.params.slug
      )}`,
      guestUrl: `${publicOrigin(req)}/join/${guestToken}`,
      expiresAt: new Date(room.expires).toISOString(),
    });
  } catch (err) {
    console.error('[GuestRoom] room api error:', err.message);
    return res.status(500).json({ error: 'failed' });
  }
});

app.get('/join/:token', async (req, res) => {
  const info = verifyJoinToken(req.params.token);
  if (!info || info.role !== 'guest') return res.status(404).send('Room not found');
  const room = await loadJoinRoom(info.roomId);
  if (!room) {
    return res.status(410).send('This room has expired. Ask the host for a new link.');
  }
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'no-store');
  return res.send(
    renderRoomPage({
      role: 'guest',
      roomId: info.roomId,
      token: req.params.token,
      peerName: room.hostName,
      guestUrl: '',
    })
  );
});

app.get('/p/:slug', (req, res) => {
  const slug = String(req.params.slug || '').trim();
  return res.redirect(301, `/u/${encodeURIComponent(slug)}`);
});
app.get('/u/:slug', async (req, res) => {
  if (!firestoreDb) return res.status(503).send('unavailable');
  const slug = String(req.params.slug || '').trim().toLowerCase();
  if (!/^[a-z0-9-]{3,32}$/.test(slug)) return res.status(404).send('Not found');
  try {
    const claim = await firestoreDb.collection('profiles_slug').doc(slug).get();
    const uid = claim.exists ? (claim.data()?.uid || '') : '';
    if (!uid) return res.status(404).send('Not found');
    const snap = await firestoreDb.collection('profiles').doc(uid).get();
    if (!snap.exists) return res.status(404).send('Not found');
    const profile = snap.data() || {};
    if (profile.published !== true) return res.status(404).send('Not found');
    const canonical = String(profile.slug || profile.username || slug);
    if (canonical && canonical !== slug) {
      return res.redirect(301, '/u/' + encodeURIComponent(canonical));
    }

    // Anonymous, throttled page-view counter (no cookies).
    try {
      const ip = String(req.headers['x-forwarded-for'] || req.ip || '').split(',')[0].trim();
      const nowMs = Date.now();
      const seen = profileViewThrottle.get(ip) || 0;
      if (!ip || nowMs - seen > 10 * 60 * 1000) {
        if (ip) profileViewThrottle.set(ip, nowMs);
        await firestoreDb
          .collection('profiles')
          .doc(uid)
          .set({ viewCount: FieldValue.increment(1) }, { merge: true });
      }
    } catch (viewErr) {
      // Analytics must never break the page.
    }
    const [days, reviews] = await Promise.all([
      computeBookingDays(uid).catch(() => []),
      loadRecentReviews(uid).catch(() => []),
    ]);

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'public, max-age=60');
    return res.send(
      renderProfilePage({
        profile,
        username: slug,
        days,
        reviews,
        origin: publicOrigin(req),
      })
    );
  } catch (err) {
    console.error('[Profile] page error:', err.message);
    return res.status(500).send('error');
  }
});

// Public booking: shareable page and request endpoint (no app or login).
const bookingLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many booking attempts, please try again later.' },
});

function parseHm(value) {
  const match = /^([01]\d|2[0-3]):([0-5]\d)$/.exec(String(value || ''));
  if (!match) return null;
  return Number(match[1]) * 60 + Number(match[2]);
}

function timeZoneOffsetMs(date, timeZone) {
  try {
    const parts = new Intl.DateTimeFormat('en-US', {
      timeZone,
      hour12: false,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    })
      .formatToParts(date)
      .reduce((acc, part) => {
        acc[part.type] = part.value;
        return acc;
      }, {});
    const asUtc = Date.UTC(
      Number(parts.year),
      Number(parts.month) - 1,
      Number(parts.day),
      Number(parts.hour) % 24,
      Number(parts.minute),
      Number(parts.second)
    );
    return asUtc - date.getTime();
  } catch (_) {
    return 0;
  }
}

function zonedToUtc(dateStr, timeStr, timeZone) {
  const [year, month, day] = dateStr.split('-').map(Number);
  const [hour, minute] = timeStr.split(':').map(Number);
  const naive = Date.UTC(year, month - 1, day, hour, minute);
  let utc = naive - timeZoneOffsetMs(new Date(naive), timeZone);
  utc = naive - timeZoneOffsetMs(new Date(utc), timeZone);
  return new Date(utc);
}

function fmtHm(minutes) {
  const h = Math.floor(minutes / 60).toString().padStart(2, '0');
  const m = (minutes % 60).toString().padStart(2, '0');
  return `${h}:${m}`;
}

/** Expands availability windows into fixed 60-minute bookable slots. */
function expandWindows(config, dateStr, timeZone, durationMinutes = 60) {
  const out = [];
  const windows = Array.isArray(config?.slots) ? config.slots : [];
  for (const window of windows) {
    const start = parseHm(window.start);
    const end = parseHm(window.end);
    if (start === null || end === null || start >= end) continue;
    for (let minute = start; minute + durationMinutes <= end; minute += durationMinutes) {
      const startHm = fmtHm(minute);
      const endHm = fmtHm(minute + durationMinutes);
      out.push({
        start: startHm,
        end: endHm,
        startAt: zonedToUtc(dateStr, startHm, timeZone),
        endAt: zonedToUtc(dateStr, endHm, timeZone),
      });
    }
  }
  return out;
}

function hostDateString(date, timeZone) {
  try {
    return new Intl.DateTimeFormat('en-CA', {
      timeZone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(date);
  } catch (_) {
    return ymd(date);
  }
}

function bookingWeekday(date) {
  const day = date.getUTCDay();
  return day === 0 ? 7 : day;
}

function ymd(date) {
  return date.toISOString().slice(0, 10);
}

async function loadHostBySlug(rawSlug) {
  if (!firestoreDb) return null;
  const slug = String(rawSlug || '').trim().toLowerCase();
  if (!/^[a-z0-9-]{3,32}$/.test(slug)) return null;
  const claim = await firestoreDb.collection('profiles_slug').doc(slug).get();
  const uid = claim.exists ? (claim.data()?.uid || '') : '';
  if (!uid) return null;
  const snap = await firestoreDb.collection('profiles').doc(uid).get();
  if (!snap.exists) return null;
  const profile = snap.data() || {};
  if (profile.published !== true) return null;
  return { uid, slug, profile };
}

async function computeBookingDays(uid) {
  const availSnap = await firestoreDb
    .collection('users')
    .doc(uid)
    .collection('availability')
    .get();
  const availability = {};
  availSnap.docs.forEach((doc) => {
    availability[doc.id] = doc.data();
  });

  const bookingsSnap = await firestoreDb
    .collection('bookings')
    .where('hostUid', '==', uid)
    .get();
  const booked = bookingsSnap.docs
    .map((doc) => doc.data())
    .filter((row) => row.status !== 'cancelled')
    .map((row) => ({ start: Date.parse(row.startAt), end: Date.parse(row.endAt) }))
    .filter((row) => Number.isFinite(row.start) && Number.isFinite(row.end));

  const days = [];
  const now = new Date();
  // Enumerate host-local calendar days, not the server's UTC days.
  const todayParts = hostDateString(now, hostTimeZone(availability))
    .split('-')
    .map(Number);

  for (let i = 0; i < 14; i++) {
    const date = new Date(
      Date.UTC(todayParts[0], todayParts[1] - 1, todayParts[2] + i)
    );
    const config = availability[String(bookingWeekday(date))];
    if (!config || config.enabled !== true) continue;

    const timeZone = config.timezone || 'UTC';
    const slots = expandWindows(config, ymd(date), timeZone, 60)
      .filter((slot) => slot.startAt.getTime() > Date.now())
      .filter(
        (slot) =>
          !booked.some(
            (row) =>
              row.start < slot.endAt.getTime() &&
              row.end > slot.startAt.getTime()
          )
      )
      .map((slot) => ({
        start: slot.start,
        end: slot.end,
        startAt: slot.startAt.toISOString(),
        endAt: slot.endAt.toISOString(),
      }));
    if (slots.length > 0) {
      days.push({
        date: ymd(date),
        label: date.toLocaleDateString('en-GB', {
          day: '2-digit',
          month: 'short',
          weekday: 'short',
          timeZone: 'UTC',
        }),
        slots: slots.map((slot) => ({
          start: slot.start,
          end: slot.end,
          startAt: slot.startAt,
          endAt: slot.endAt,
        })),
      });
    }
  }
  return days;
}

function hostTimeZone(availability) {
  for (const key of Object.keys(availability)) {
    const zone = availability[key]?.timezone;
    if (typeof zone === 'string' && zone.trim()) return zone.trim();
  }
  return 'UTC';
}
function shortName(raw) {
  const parts = String(raw || '').trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return 'Client';
  if (parts.length === 1) return parts[0];
  return `${parts[0]} ${parts[parts.length - 1][0]}.`;
}

async function loadRecentReviews(uid) {
  const snap = await firestoreDb
    .collection('reviews')
    .where('targetUid', '==', uid)
    .get();
  const rows = snap.docs
    .map((doc) => doc.data())
    .filter((row) => Number(row.rating) > 0)
    .sort((a, b) =>
      String(b.createdAt || '').localeCompare(String(a.createdAt || ''))
    )
    .slice(0, 3);

  const reviews = [];
  for (const row of rows) {
    let name = 'Client';
    try {
      const userSnap = await firestoreDb
        .collection('users')
        .doc(String(row.raterUid))
        .get();
      if (userSnap.exists) {
        name = shortName(userSnap.data()?.name || '');
      }
    } catch (err) {
      // Name is optional.
    }
    reviews.push({
      name,
      rating: Number(row.rating) || 5,
      comment: row.comment || '',
    });
  }
  return reviews;
}

app.get('/api/public/availability/:slug', async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'unavailable' });
  try {
    const host = await loadHostBySlug(req.params.slug);
    if (!host) return res.status(404).json({ error: 'not_found' });
    const days = await computeBookingDays(host.uid);
    res.setHeader('Cache-Control', 'no-store');
    return res.json({ displayName: host.profile.displayName || '', days });
  } catch (err) {
    console.error('[Booking] availability error:', err.message);
    return res.status(500).json({ error: 'failed' });
  }
});

app.get('/book/:slug', async (req, res) => {
  if (!firestoreDb) return res.status(503).send('unavailable');
  try {
    const host = await loadHostBySlug(req.params.slug);
    if (!host) return res.status(404).send('Not found');
    const days = await computeBookingDays(host.uid);
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'no-store');
    return res.send(
      renderBookingPage({
        profile: host.profile,
        days,
        username: host.slug,
      })
    );
  } catch (err) {
    console.error('[Booking] page error:', err.message);
    return res.status(500).send('error');
  }
});

app.get('/book/:slug/:bookingId.ics', async (req, res) => {
  if (!firestoreDb) return res.status(503).send('unavailable');
  try {
    const host = await loadHostBySlug(req.params.slug);
    if (!host) return res.status(404).send('Not found');
    const bookingSnap = await firestoreDb
      .collection('bookings')
      .doc(String(req.params.bookingId))
      .get();
    if (!bookingSnap.exists) return res.status(404).send('Not found');
    const booking = bookingSnap.data() || {};
    if (booking.hostUid !== host.uid) return res.status(404).send('Not found');

    res.setHeader('Content-Type', 'text/calendar; charset=utf-8');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="livocal-${req.params.bookingId}.ics"`
    );
    return res.send(
      bookingIcs({
        booking: { ...booking, id: req.params.bookingId },
        hostName: host.profile.displayName || 'Freelancer',
      })
    );
  } catch (err) {
    console.error('[Booking] ics error:', err.message);
    return res.status(500).send('error');
  }
});

app.post('/api/public/book/:slug', bookingLimiter, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'unavailable' });
  try {
    const host = await loadHostBySlug(req.params.slug);
    if (!host) return res.status(404).json({ error: 'not_found' });

    const body = req.body || {};
    const guestName = String(body.guestName || '').trim().slice(0, 80);
    const guestContact = String(body.guestContact || '').trim().slice(0, 120);
    const note = String(body.note || '').trim().slice(0, 500);
    const slot = String(body.slot || '');
    const slotStart = new Date(slot);
    if (
      !guestName ||
      !guestContact ||
      !slot ||
      !Number.isFinite(slotStart.getTime()) ||
      slotStart.getTime() < Date.now() - 60 * 1000
    ) {
      return res.status(400).json({ error: 'invalid' });
    }

    const availSnap = await firestoreDb
      .collection('users')
      .doc(host.uid)
      .collection('availability')
      .get();
    const availability = {};
    availSnap.docs.forEach((doc) => {
      availability[doc.id] = doc.data();
    });
    const timeZone = hostTimeZone(availability);
    const hostDate = hostDateString(slotStart, timeZone);
    const [year, month, day] = hostDate.split('-').map(Number);
    const dateObj = new Date(Date.UTC(year, month - 1, day));
    if (!Number.isFinite(dateObj.getTime())) {
      return res.status(400).json({ error: 'invalid' });
    }

    const config = availability[String(bookingWeekday(dateObj))];
    const slotConfig = config && config.enabled === true
      ? expandWindows(config, hostDate, timeZone, 60).find(
          (row) =>
            Math.abs(row.startAt.getTime() - slotStart.getTime()) < 60 * 1000
        )
      : null;
    if (!slotConfig || slotConfig.endAt <= slotConfig.startAt) {
      return res.status(400).json({ error: 'slot_unavailable' });
    }

    const startAt = slotConfig.startAt;
    const endAt = slotConfig.endAt;

    const existingSnap = await firestoreDb
      .collection('bookings')
      .where('hostUid', '==', host.uid)
      .get();
    const conflict = existingSnap.docs
      .map((doc) => doc.data())
      .filter((row) => row.status !== 'cancelled')
      .some(
        (row) =>
          Date.parse(row.startAt) < endAt.getTime() &&
          Date.parse(row.endAt) > startAt.getTime()
      );
    if (conflict) return res.status(409).json({ error: 'slot_taken' });

    const created = await firestoreDb.collection('bookings').add({
      hostUid: host.uid,
      guestName,
      guestContact,
      note,
      startAt: startAt.toISOString(),
      endAt: endAt.toISOString(),
      status: 'pending',
      createdAt: new Date().toISOString(),
    });

    try {
      if (messagingService) {
        const tokenDoc = await firestoreDb.collection('fcmTokens').doc(host.uid).get();
        const token = tokenDoc.exists ? tokenDoc.data().token : null;
        if (token) {
          await messagingService.send({
            token,
            notification: {
              title: 'New booking request',
              body: `${guestName} · ${startAt.toISOString().slice(0, 16).replace('T', ' ')} UTC`,
            },
            data: { type: 'BOOKING_REQUEST', bookingId: created.id },
            android: {
              priority: 'high',
              notification: { channelId: 'livocal_messages', defaultSound: true },
            },
          });
        }
      }
    } catch (pushErr) {
      console.error('[Booking] push failed:', pushErr.message);
    }

    return res.json({
      ok: true,
      id: created.id,
      startAt: startAt.toISOString(),
      endAt: endAt.toISOString(),
    });
  } catch (err) {
    console.error('[Booking] create error:', err.message);
    return res.status(500).json({ error: 'failed' });
  }
});

// Public invoice view: no login, no Storage. Print/Save as PDF in the browser.
app.get('/i/:token', async (req, res) => {
  if (!firestoreDb) return res.status(503).send('unavailable');
  const token = String(req.params.token || '').trim();
  if (!/^[a-z0-9]{16,40}$/.test(token)) return res.status(404).send('Not found');
  try {
    const doc = await firestoreDb.collection('public_invoices').doc(token).get();
    if (!doc.exists) return res.status(404).send('Not found');
    const inv = doc.data() || {};
    const esc = (value) =>
      String(value == null ? '' : value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    const currency = esc(inv.currency || 'USD');
    const money = (value) =>
      `${currency} ${(Number(value) || 0).toFixed(2)}`;
    const items = (Array.isArray(inv.items) ? inv.items : [])
      .map(
        (item) => `<tr>
          <td>${esc(item.description || '')}</td>
          <td class="num">${esc(item.qty ?? '')}</td>
          <td class="num">${money(item.rate)}</td>
          <td class="num">${money((Number(item.qty) || 0) * (Number(item.rate) || 0))}</td>
        </tr>`
      )
      .join('');
    const due = inv.dueDate
      ? new Date(inv.dueDate).toLocaleDateString('en-GB')
      : '';
    const status = String(inv.status || 'sent');
    const subtotal = (Array.isArray(inv.items) ? inv.items : []).reduce(
      (sum, item) =>
        sum + (Number(item.qty) || 0) * (Number(item.rate) || 0),
      0
    );

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'public, max-age=60');
    return res.send(`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${esc(inv.number || 'Invoice')} — ${esc(inv.ownerName || 'Livocal')}</title>
<style>
  *{box-sizing:border-box}
  body{margin:0;background:#eef2f7;color:#0b1220;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Noto Sans Bengali',sans-serif;line-height:1.55}
  .sheet{max-width:760px;margin:24px auto;background:#fff;border-radius:14px;padding:32px;box-shadow:0 12px 40px rgba(15,40,70,.12)}
  .top{display:flex;justify-content:space-between;align-items:flex-start;gap:16px}
  h1{font-size:24px;margin:0;color:#0f766e;letter-spacing:-.3px}
  .muted{color:#64748b;font-size:12px}
  .badge{display:inline-block;padding:4px 10px;border-radius:999px;font-size:10px;font-weight:800;text-transform:uppercase;border:1px solid #cbd5e1;background:#f8fafc}
  .parties{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin:22px 0}
  table{width:100%;border-collapse:collapse;margin-top:8px}
  th,td{padding:9px 8px;border-bottom:1px solid #e2e8f0;font-size:12.5px;text-align:left}
  th{font-size:10px;letter-spacing:.07em;text-transform:uppercase;color:#64748b}
  .num{text-align:right}
  .totals{margin-left:auto;width:260px;margin-top:14px}
  .totals .row{display:flex;justify-content:space-between;padding:4px 0;font-size:12.5px}
  .totals .grand{border-top:1px solid #cbd5e1;margin-top:6px;padding-top:8px;font-weight:800;font-size:15px;color:#0f766e}
  .notes{margin-top:18px;font-size:12px;color:#475569}
  .actions{margin-top:22px;display:flex;gap:10px}
  .btn{padding:10px 16px;border-radius:10px;border:0;background:#0f9d76;color:#fff;font-weight:800;font-size:12.5px;cursor:pointer;text-decoration:none}
  footer{margin-top:24px;text-align:center;color:#94a3b8;font-size:10.5px}
  @media(max-width:600px){.sheet{margin:10px;padding:20px}.parties{grid-template-columns:1fr}.totals{width:100%}}
  @media print{body{background:#fff}.sheet{box-shadow:none;margin:0;border-radius:0;padding:0}.actions{display:none}}
</style>
</head>
<body>
<div class="sheet">
  <div class="top">
    <div>
      <h1>INVOICE</h1>
      <div class="muted">${esc(inv.number || '')}</div>
    </div>
    <div style="text-align:right">
      <span class="badge">${esc(status)}</span>
      ${due ? `<div class="muted" style="margin-top:6px">Due ${esc(due)}</div>` : ''}
    </div>
  </div>

  <div class="parties">
    <div>
      <div class="muted">From</div>
      <strong>${esc(inv.ownerName || 'Freelancer')}</strong>
      <div class="muted">Livocal</div>
    </div>
    <div>
      <div class="muted">Bill to</div>
      <strong>${esc(inv.clientName || 'Client')}</strong>
    </div>
  </div>

  <table>
    <thead><tr><th>Description</th><th class="num">Qty</th><th class="num">Rate</th><th class="num">Amount</th></tr></thead>
    <tbody>${items}</tbody>
  </table>

  <div class="totals">
    <div class="row"><span>Subtotal</span><span>${money(subtotal)}</span></div>
    ${Number(inv.taxPct) > 0 ? `<div class="row"><span>Tax ${esc(inv.taxPct)}%</span><span>${money(subtotal * Number(inv.taxPct) / 100)}</span></div>` : ''}
    ${Number(inv.discount) > 0 ? `<div class="row"><span>Discount</span><span>- ${money(inv.discount)}</span></div>` : ''}
    <div class="row grand"><span>Total</span><span>${money(inv.total)}</span></div>
  </div>

  ${inv.notes ? `<div class="notes"><strong>Notes:</strong> ${esc(inv.notes)}</div>` : ''}

  <div class="actions">
    <button class="btn" onclick="window.print()">Print / Save PDF</button>
  </div>
  <footer>Powered by Livocal · live voice translation for freelancers</footer>
</div>
</body>
</html>`);
  } catch (err) {
    console.error('[Invoice] page error:', err.message);
    return res.status(500).send('error');
  }
});

// Public proposal view (share link, no login).
app.get('/pr/:token', async (req, res) => {
  if (!firestoreDb) return res.status(503).send('unavailable');
  const token = String(req.params.token || '').trim();
  if (!/^[a-z0-9]{16,40}$/.test(token)) return res.status(404).send('Not found');
  try {
    const doc = await firestoreDb.collection('public_proposals').doc(token).get();
    if (!doc.exists) return res.status(404).send('Not found');
    const p = doc.data() || {};
    const esc = (value) =>
      String(value == null ? '' : value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    const section = (title, body) =>
      body
        ? `<section><h2>${esc(title)}</h2><p>${esc(body).replace(/\n/g, '<br>')}</p></section>`
        : '';

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'public, max-age=60');
    return res.send(`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Proposal — ${esc(p.ownerName || 'Freelancer')}</title>
<style>
  *{box-sizing:border-box}
  body{margin:0;background:#eef2f7;color:#0b1220;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Noto Sans Bengali',sans-serif;line-height:1.6}
  .sheet{max-width:780px;margin:24px auto;background:#fff;border-radius:14px;padding:34px;box-shadow:0 12px 40px rgba(15,40,70,.12)}
  .top{display:flex;justify-content:space-between;gap:14px;align-items:flex-start;border-bottom:2px solid #0f766e;padding-bottom:14px}
  h1{font-size:22px;margin:0;color:#0f766e}
  .muted{color:#64748b;font-size:12px}
  h2{font-size:10px;letter-spacing:.12em;text-transform:uppercase;color:#0f766e;margin:18px 0 6px}
  p{margin:0;font-size:13px}
  section{border-bottom:1px solid #e2e8f0;padding-bottom:12px}
  .actions{margin:16px 0}
  .btn{border:0;background:#0f9d76;color:#fff;border-radius:10px;padding:10px 16px;font-weight:800;font-size:12.5px;cursor:pointer}
  footer{margin-top:20px;text-align:center;color:#94a3b8;font-size:10.5px}
  @media(max-width:600px){.sheet{margin:10px;padding:20px}}
  @media print{body{background:#fff}.sheet{box-shadow:none;margin:0;border-radius:0;padding:0}.actions{display:none}}
</style>
</head>
<body>
<div class="sheet">
  <div class="actions"><button class="btn" onclick="window.print()">Print / Save PDF</button></div>
  <div class="top">
    <div>
      <h1>${esc(p.headline || 'Proposal')}</h1>
      <div class="muted">Prepared for ${esc(p.clientName || 'Client')}</div>
    </div>
    <div class="muted" style="text-align:right">${esc(p.ownerName || 'Freelancer')}</div>
  </div>
  ${section('Scope', p.scope)}
  ${section('Timeline', p.timeline)}
  ${section('Price', p.price)}
  ${section('Terms', p.terms)}
  <footer>Powered by Livocal · live voice translation for freelancers</footer>
</div>
</body>
</html>`);
  } catch (err) {
    console.error('[Proposal] page error:', err.message);
    return res.status(500).send('error');
  }
});

// Daily booking digest (free GitHub Actions cron calls this with a secret).
app.post('/api/digest/run', async (req, res) => {
  const secret = process.env.DIGEST_SECRET || '';
  if (!secret) return res.status(503).json({ error: 'digest_disabled' });
  if (req.headers['x-digest-key'] !== secret) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  if (!firestoreDb || !messagingService) {
    return res.status(503).json({ error: 'unavailable' });
  }

  try {
    const dateKey = new Intl.DateTimeFormat('en-CA', {
      timeZone: 'Asia/Dhaka',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(new Date());
    const start = new Date(`${dateKey}T00:00:00+06:00`);
    const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);

    const snap = await firestoreDb
      .collection('bookings')
      .where('startAt', '>=', start.toISOString())
      .get();
    const today = snap.docs
      .map((doc) => doc.data())
      .filter(
        (row) =>
          row.status !== 'cancelled' &&
          Date.parse(row.startAt) < end.getTime()
      );

    const byHost = new Map();
    for (const row of today) {
      const list = byHost.get(row.hostUid) || [];
      list.push(row);
      byHost.set(row.hostUid, list);
    }

    let sent = 0;
    for (const [hostUid, rows] of byHost.entries()) {
      try {
        const tokenDoc = await firestoreDb.collection('fcmTokens').doc(hostUid).get();
        const token = tokenDoc.exists ? tokenDoc.data().token : null;
        if (!token) continue;
        const first = rows
          .sort((a, b) => Date.parse(a.startAt) - Date.parse(b.startAt))[0];
        const time = new Date(first.startAt).toLocaleTimeString('en-GB', {
          hour: '2-digit',
          minute: '2-digit',
          timeZone: 'Asia/Dhaka',
        });
        await messagingService.send({
          token,
          notification: {
            title: `Today: ${rows.length} booking${rows.length > 1 ? 's' : ''}`,
            body: `${first.guestName || 'Guest'} at ${time}`,
          },
          data: { type: 'DAILY_DIGEST' },
          android: {
            priority: 'high',
            notification: { channelId: 'livocal_messages', defaultSound: true },
          },
        });
        sent += 1;
      } catch (pushErr) {
        console.error('[Digest] push failed:', pushErr.message);
      }
    }

    return res.json({ ok: true, bookings: today.length, hosts: sent });
  } catch (err) {
    console.error('[Digest] error:', err.message);
    return res.status(500).json({ error: 'failed' });
  }
});

// Hosted Public Terms of Service Page for Google Play & App Store Compliance
app.get(['/terms-of-service', '/terms'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Livocal - Terms of Service | সেবার শর্তাবলী</title>
  <style>
    :root { --primary: #00B386; --bg: #0B1220; --card: #131C2B; --text: #E8EEF7; --muted: #9AA7BD; }
    * { box-sizing: border-box; }
    body { margin: 0; background: var(--bg); color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; line-height: 1.65; }
    header { padding: 32px 20px 16px; max-width: 820px; margin: 0 auto; }
    h1 { font-size: 26px; margin: 0 0 6px; }
    .sub { color: var(--muted); font-size: 14px; }
    main { max-width: 820px; margin: 0 auto; padding: 0 20px 64px; }
    section { background: var(--card); border-radius: 14px; padding: 20px 22px; margin-top: 16px; }
    h2 { font-size: 17px; margin: 0 0 10px; color: var(--primary); }
    p, li { font-size: 14.5px; color: var(--text); }
    ul { padding-left: 20px; }
    a { color: var(--primary); }
    footer { max-width: 820px; margin: 0 auto; padding: 0 20px 48px; color: var(--muted); font-size: 12.5px; }
  </style>
</head>
<body>
  <header>
    <h1>Terms of Service</h1>
    <div class="sub">Livocal · Last updated: 25 November 2026</div>
  </header>
  <main>
    <section>
      <h2>1. Acceptance</h2>
      <p>By creating an account or using Livocal you agree to these terms. If you do not agree, please do not use the app.</p>
    </section>
    <section>
      <h2>2. What Livocal does</h2>
      <p>Livocal provides messaging, voice calls and real-time AI speech translation. Translation is generated automatically by third-party AI models and may contain mistakes, especially with names, numbers, accents and technical terms. Always confirm critical information yourself.</p>
    </section>
    <section>
      <h2>3. Accounts</h2>
      <ul>
        <li>You must be at least 13 years old (or the minimum age in your country).</li>
        <li>Keep your phone number and verification codes private.</li>
        <li>You are responsible for activity on your account.</li>
      </ul>
    </section>
    <section>
      <h2>4. Acceptable use</h2>
      <ul>
        <li>No harassment, threats, hate speech, or illegal content.</li>
        <li>No impersonation, spam, or automated abuse of the service.</li>
        <li>No attempts to bypass usage limits, billing or security controls.</li>
      </ul>
      <p>We may suspend accounts that break these rules.</p>
    </section>
    <section>
      <h2>5. Translation minutes and payments</h2>
      <p>Translated calls use prepaid minutes. Free trial minutes and premium minutes are shown in the app. Purchases are processed by Google Play; refunds follow Google Play policy. Minutes are non-transferable and expire as shown at purchase.</p>
    </section>
    <section>
      <h2>6. Privacy</h2>
      <p>How we handle data is described in our <a href="/privacy-policy">Privacy Policy</a>, which forms part of these terms.</p>
    </section>
    <section>
      <h2>7. Availability</h2>
      <p>The service depends on network connectivity and third-party providers. We may change, suspend or discontinue features, and we do not guarantee uninterrupted availability.</p>
    </section>
    <section>
      <h2>8. Limitation of liability</h2>
      <p>To the extent permitted by law, Livocal is not liable for indirect or consequential losses, or for decisions made based on machine translation output.</p>
    </section>
    <section>
      <h2>9. Termination</h2>
      <p>You may delete your account at any time from Settings → Account. We may terminate accounts that violate these terms.</p>
    </section>
    <section>
      <h2>10. Contact</h2>
      <p>Questions about these terms: <a href="mailto:support@livocal.app">support@livocal.app</a></p>
    </section>
  </main>
  <footer>© 2026 Livocal. All rights reserved.</footer>
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

      // Check if target user has blocked the caller
      const blockDoc = await firestoreDb
        .collection('users')
        .doc(targetUserId)
        .collection('blocked_users')
        .doc(callerUid)
        .get();
      if (blockDoc.exists) {
        return res.status(403).json({ error: 'Caller is blocked by recipient' });
      }

      // Check if target user has muted the caller
      let isMutedByRecipient = false;
      try {
        const muteDoc = await firestoreDb
          .collection('users')
          .doc(targetUserId)
          .collection('muted_contacts')
          .doc(callerUid)
          .get();
        if (muteDoc.exists && muteDoc.data().muted === true) {
          isMutedByRecipient = true;
        }
      } catch (muteErr) {
        console.warn(`[CallNotify] Could not check mute status for ${targetUserId}:`, muteErr.message);
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

      // High Priority Data Message for waking up Android / CallKit (silent if recipient muted caller)
      const message = {
        token,
        data: {
          type: 'INCOMING_CALL',
          callId: String(callId),
          callerId: String(callerUid),
          callerName: String(verifiedCallerName),
          callerNumber: String(verifiedCallerNumber),
          timestamp: String(Date.now()),
          isMuted: isMutedByRecipient ? 'true' : 'false',
        },
        android: {
          priority: 'high',
          ...(isMutedByRecipient
            ? {}
            : {
                notification: {
                  channelId: 'livocal_messages',
                  priority: 'high',
                  defaultSound: true,
                  defaultVibrateTimings: true,
                },
              }),
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

    const { receiverId, messageContent, messageId, authorId, highPriority } = req.body;

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

      // 3. Check if recipient has blocked this author
      const blockDoc = await firestoreDb
        .collection('users')
        .doc(receiverId)
        .collection('blocked_users')
        .doc(callerUid)
        .get();
      if (blockDoc.exists) {
        return res.status(403).json({ error: 'Author is blocked by recipient' });
      }

      // 4. Check if recipient has muted this author
      let isMutedByRecipient = false;
      try {
        const muteDoc = await firestoreDb
          .collection('users')
          .doc(receiverId)
          .collection('muted_contacts')
          .doc(callerUid)
          .get();
        if (muteDoc.exists && muteDoc.data().muted === true) {
          isMutedByRecipient = true;
        }
      } catch (muteErr) {
        console.warn(`[ChatNotify] Could not check mute status for ${receiverId}:`, muteErr.message);
      }

      // High Priority Semantics: The RECIPIENT's preference is the sole authority
      let isHighPriority = true;
      try {
        if (firestoreDb) {
          const customDoc = await firestoreDb
            .collection('users')
            .doc(receiverId)
            .collection('notification_settings')
            .doc(callerUid)
            .get();
          if (customDoc.exists && typeof customDoc.data().highPriority === 'boolean') {
            isHighPriority = customDoc.data().highPriority;
          } else {
            const prefDoc = await firestoreDb
              .collection('users')
              .doc(receiverId)
              .collection('notification_settings')
              .doc('preferences')
              .get();
            if (prefDoc.exists && typeof prefDoc.data().highPriority === 'boolean') {
              isHighPriority = prefDoc.data().highPriority;
            }
          }
        }
      } catch (prefErr) {
        console.warn(`[ChatNotify] Could not check recipient highPriority pref for ${receiverId}:`, prefErr.message);
      }

      // If contact is muted by recipient, send a silent data-only push without system tray notification
      const payload = {
        token: targetToken,
        ...(isMutedByRecipient
          ? {}
          : {
              notification: {
                title: verifiedAuthorName,
                body: String(messageContent || 'Sent a message').substring(0, 500),
                imageUrl: verifiedAuthorAvatar || undefined,
              },
            }),
        data: {
          type: 'CHAT_MESSAGE',
          messageId: String(messageId),
          authorName: String(verifiedAuthorName),
          authorId: String(callerUid),
          authorAvatar: String(verifiedAuthorAvatar),
          isMuted: isMutedByRecipient ? 'true' : 'false',
          ...(req.body.expiresAt ? { expiresAt: String(req.body.expiresAt) } : {}),
        },
        android: {
          priority: isHighPriority ? 'high' : 'normal',
          notification: {
            channelId: isHighPriority ? 'livocal_high_importance' : 'livocal_default',
            priority: isHighPriority ? 'high' : 'default',
          },
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

// Remote Delete for Everyone / Purge Silent FCM Push
app.post(
  '/api/notify/delete-message',
  authenticateRequest,
  pushLimiter,
  validateBody(DeleteMessageNotifySchema),
  async (req, res) => {
    if (!firebaseApp || !messagingService) {
      return res.status(503).json({ error: 'Firebase Admin not initialized on server' });
    }

    const { receiverId, messageId } = req.body;
    const callerUid = req.user.uid;

    try {
      if (!firestoreDb) {
        return res.status(503).json({ error: 'Firestore database service is currently unavailable' });
      }

      const recipientDoc = await firestoreDb.collection('users').doc(receiverId).get();
      if (!recipientDoc.exists) {
        return res.status(404).json({ error: 'Recipient user not found' });
      }

      const targetToken = recipientDoc.data()?.fcmToken;
      if (!targetToken) {
        return res.status(200).json({ success: true, message: 'Recipient has no push token' });
      }

      const fcmPayload = {
        token: targetToken,
        data: {
          type: 'DELETE_MESSAGE',
          messageId: String(messageId),
          senderId: String(callerUid),
        },
        android: {
          priority: 'high',
        },
      };

      await messagingService.send(fcmPayload);
      return res.status(200).json({ success: true, message: 'Delete sync notification dispatched' });
    } catch (err) {
      console.error('[DeleteNotify] Failed to dispatch delete message push:', err.message);
      return res.status(500).json({ error: 'Failed to dispatch delete push' });
    }
  }
);

// Secure ICE Servers endpoint (Metered TURN, coturn HMAC or static credentials)
app.get(['/api/webrtc/ice-servers', '/api/turn-credentials'], authenticateRequest, async (req, res) => {
  const iceServers = [
    { urls: 'stun:stun.l.google.com:19302' },
    { urls: 'stun:stun1.l.google.com:19302' },
    { urls: 'stun:stun2.l.google.com:19302' },
  ];

  if (METERED_API_KEY) {
    try {
      const metered = await fetchMeteredIceServers();
      // Metered returns [{ urls, username, credential }, ...]
      iceServers.push(...metered);
      res.setHeader('X-Turn-Provider', 'metered');
      return res.json({ iceServers });
    } catch (err) {
      console.warn('[ICE] Metered TURN fetch failed, falling back:', err.message);
    }
  }

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
    const cleanDeviceId = (deviceId && typeof deviceId === 'string') ? deviceId.trim() : null;

    // Strict Fail-Closed Security (C3): deviceId is strictly required to grant free trial.
    // If deviceId is omitted, null, empty, or too short, trial is DENIED (grantTrial = false).
    let grantTrial = false;

    if (!cleanDeviceId || cleanDeviceId.length < 8) {
      console.warn(`[SaaS Billing] Security Alert: User ${userId} requested wallet init without valid deviceId ("${deviceId}"). Denying trial minutes (fail-closed).`);
      grantTrial = false;
    } else {
      const fingerprintRef = firestoreDb.collection('device_fingerprints').doc(cleanDeviceId);
      const fingerprintSnap = await fingerprintRef.get();

      if (fingerprintSnap.exists) {
        // Device has already claimed trial on this or another phone number
        grantTrial = false;
        console.log(`[SaaS Billing] Device ${cleanDeviceId} already claimed trial. Denying trial minutes for uid ${userId}.`);
      } else {
        // Fresh physical device: Grant trial and persist hardware fingerprint
        grantTrial = true;
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
  const { callId } = req.body || {};

  if (!callId || typeof callId !== 'string' || !/^[a-zA-Z0-9_\-]{6,128}$/.test(callId.trim())) {
    return res.status(400).json({ error: 'Valid callId is required' });
  }

  if (!firestoreDb) {
    return res.status(503).json({ error: 'Firestore database service is currently unavailable' });
  }

  const cleanCallId = callId.trim();

  // Server-side truth: ownership and the translation flag come from Firestore,
  // never from the request body (a modified client must not be able to skip or
  // replay billing by lying about the call).
  let callData;
  try {
    const callSnap = await firestoreDb.collection('calls').doc(cleanCallId).get();
    if (callSnap.exists) {
      callData = callSnap.data() || {};
    } else {
      // Call document may already be cleaned up; fall back to the summary so a
      // legitimate final minute is still billable.
      const summarySnap = await firestoreDb
        .collection('call_summaries')
        .doc(cleanCallId)
        .get();
      if (!summarySnap.exists) {
        return res.status(404).json({ error: 'Call session not found' });
      }
      callData = summarySnap.data() || {};
    }
  } catch (verifyErr) {
    console.error('[SaaS Billing] Call verification failed:', verifyErr.message);
    return res.status(500).json({ error: 'Failed to verify call session' });
  }

  if (callData.callerId !== callerUid) {
    return res.status(403).json({ error: 'Forbidden: caller mismatch' });
  }

  // Free local call bypass: translation explicitly disabled for this call.
  if (callData.translationEnabled === false) {
    return res.json({
      success: true,
      deducted: 0,
      isTranslatedCall: false,
      remainingMinutes: null,
      message: 'FREE_LOCAL_CALL',
    });
  }

  // Bound the billable minutes by the call's real age so replaying this call
  // cannot drain or fabricate minutes beyond the elapsed time.
  const parsedCreatedAt = (() => {
    const value = callData.createdAt;
    if (!value) return null;
    if (typeof value?.toDate === 'function') return value.toDate().getTime();
    if (typeof value === 'string') {
      const ms = Date.parse(value);
      return Number.isFinite(ms) ? ms : null;
    }
    return null;
  })();
  const elapsedMinutes = Math.floor(
    (Date.now() - (parsedCreatedAt ?? Date.now())) / 60000,
  ) + 1; // Telecom model: first minute is billed on connect

  let alreadyBilled = 0;
  try {
    const billedSnap = await firestoreDb
      .collection('call_billing_records')
      .where('callId', '==', cleanCallId)
      .get();
    alreadyBilled = billedSnap.size;
  } catch (countErr) {
    console.error('[SaaS Billing] Billing lookup failed:', countErr.message);
    return res.status(500).json({ error: 'Failed to read billing records' });
  }

  if (alreadyBilled >= elapsedMinutes) {
    return res.json({
      success: true,
      deducted: 0,
      alreadyBilled: true,
      remainingMinutes: null,
      message: 'ALREADY_BILLED_FOR_THIS_MINUTE',
    });
  }

  const billingMinuteIndex = alreadyBilled + 1;

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

      // Audit ledger record in call_billing_records (deterministic id prevents
      // double billing when two requests race for the same minute).
      const billingRef = firestoreDb
        .collection('call_billing_records')
        .doc(`${cleanCallId}_${billingMinuteIndex}`);
      const geminiCostUsd = 0.035; // Gemini 3.5 Live audio cost per minute (~$0.035)
      const retailBdt = 20.0;     // Freelancer retail price per minute (~৳20)
      const usdToBdt = 120.0;
      const costBdt = geminiCostUsd * usdToBdt; // ~4.2 BDT
      const netProfitBdt = retailBdt - costBdt; // ~15.8 BDT per minute (~79% profit margin)

      t.create(billingRef, {
        recordId: billingRef.id,
        callId: cleanCallId,
        callerId: callerUid,
        calleeId: callData.calleeId || '',
        isTranslatedCall: true,
        durationSeconds: 60,
        minuteIndex: billingMinuteIndex,
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
    const alreadyExists =
      err?.code === 6 || /ALREADY_EXISTS/.test(err?.message || '');
    if (alreadyExists) {
      return res.json({
        success: true,
        deducted: 0,
        alreadyBilled: true,
        remainingMinutes: null,
        message: 'ALREADY_BILLED_FOR_THIS_MINUTE',
      });
    }
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

  // Validate callId format to prevent path traversal or injection
  if (!callId || typeof callId !== 'string' || !/^[a-zA-Z0-9_\-]{6,128}$/.test(callId.trim())) {
    return res.status(400).json({ error: 'Valid callId is required (6-128 alphanumeric characters)' });
  }

  const cleanCallId = callId.trim();

  // Participant Authorization Guard (Strict Fail-Closed)
  try {
    const callSnap = await firestoreDb.collection('calls').doc(cleanCallId).get();
    if (callSnap.exists) {
      const callData = callSnap.data() || {};
      if (callData.callerId !== callerUid && callData.calleeId !== callerUid) {
        return res.status(403).json({ error: 'Forbidden: You are not a participant in this call session' });
      }
    } else {
      // If calls collection document was already cleared, verify against existing call_summaries
      const existingSummarySnap = await firestoreDb.collection('call_summaries').doc(cleanCallId).get();
      if (existingSummarySnap.exists) {
        const sumData = existingSummarySnap.data() || {};
        if (sumData.callerId !== callerUid && sumData.calleeId !== callerUid) {
          return res.status(403).json({ error: 'Forbidden: Cannot overwrite call summary of another user' });
        }
      } else {
        // Neither call session nor existing summary exists -> Reject arbitrary call ID creation!
        return res.status(404).json({ error: 'Call session not found' });
      }
    }
  } catch (authErr) {
    console.error('[Call-End Auth] Participant verification error (fail-closed):', authErr.message);
    return res.status(500).json({ error: 'Internal error verifying call session' });
  }

  try {
    const summaryRef = firestoreDb.collection('call_summaries').doc(cleanCallId);
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

// Bangladeshi MFS Mobile Phone Number Validation (bKash / Nagad)
const BD_PHONE_REGEX = /^(?:\+?8801|01)[3-9]\d{8}$/;

const safeCompareSecrets = (provided, target) => {
  if (typeof provided !== 'string' || typeof target !== 'string') return false;
  const providedBuf = Buffer.from(provided, 'utf8');
  const targetBuf = Buffer.from(target, 'utf8');
  if (providedBuf.length !== targetBuf.length) return false;
  return crypto.timingSafeEqual(providedBuf, targetBuf);
};

const ADMIN_SESSION_COOKIE = 'livocal_admin_session';
const adminSessionToken = () => {
  const secret = process.env.ADMIN_SECRET || '';
  if (!secret) return '';
  return crypto
    .createHmac('sha256', secret)
    .update('livocal-admin-session-v1')
    .digest('hex');
};
const readCookie = (req, name) => {
  const raw = req.headers.cookie || '';
  for (const part of raw.split(';')) {
    const idx = part.indexOf('=');
    if (idx < 0) continue;
    if (part.slice(0, idx).trim() === name) {
      return part.slice(idx + 1).trim();
    }
  }
  return '';
};

// Admin Authorization Middleware (Strict: Headers only, No query params, Timing-safe)
const logAdminAction = (req) => {
  if (!firestoreDb) return;
  if (req.method === 'GET') return; // keep the log to state-changing actions
  try {
    const path = String(req.originalUrl || req.url || '').split('?')[0];
    firestoreDb
      .collection('admin_audit')
      .add({
        method: req.method,
        path,
        ip: req.ip || '',
        at: new Date().toISOString(),
        atMs: Date.now(),
        ua: String(req.headers['user-agent'] || '').slice(0, 180),
      })
      .catch(() => {});
  } catch (_) {}
};

const authenticateAdmin = async (req, res, next) => {
  const providedSecret = req.headers['x-admin-secret'];

  if (providedSecret && safeCompareSecrets(providedSecret, effectiveAdminSecret)) {
    logAdminAction(req);
    return next();
  }

  // Browser session established by the /admin Basic-auth gate.
  const sessionCookie = readCookie(req, ADMIN_SESSION_COOKIE);
  if (sessionCookie && safeCompareSecrets(sessionCookie, adminSessionToken())) {
    logAdminAction(req);
    return next();
  }

  const authHeader = req.headers['authorization'];
  if (authHeader && authHeader.startsWith('Bearer ') && authService) {
    const token = authHeader.substring(7).trim();
    try {
      const decoded = await authService.verifyIdToken(token);
      if (decoded.admin === true || decoded.uid === process.env.SUPER_ADMIN_UID) {
        req.adminUser = decoded;
        logAdminAction(req);
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
  const { packId, minutes, amount, currency, paymentMethod, transactionId, idempotencyKey, promoCode } = req.body || {};

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

  // Idempotency key sanitization
  const rawIdempotencyKey = idempotencyKey || req.headers['idempotency-key'] || transactionId;
  const cleanIdempotencyKey = (typeof rawIdempotencyKey === 'string' && rawIdempotencyKey.trim().length > 0)
    ? rawIdempotencyKey.trim().replace(/[^a-zA-Z0-9_-]/g, '').substring(0, 64)
    : null;

  // Keyless deduplication guard: Suppress accidental duplicate recharges within 120s for unkeyed requests
  if (!cleanIdempotencyKey) {
    const twoMinutesAgoIso = new Date(Date.now() - 120 * 1000).toISOString();
    try {
      const recentDuplicates = await firestoreDb.collection('recharge_transactions')
        .where('userId', '==', targetUid)
        .where('status', '==', 'completed')
        .where('createdAt', '>=', twoMinutesAgoIso)
        .limit(5)
        .get();

      for (const d of recentDuplicates.docs) {
        const txData = d.data() || {};
        if (txData.minutesAdded === minutesToAdd) {
          return res.status(200).json({
            success: true,
            alreadyProcessed: true,
            transactionId: d.id,
            minutesAdded: txData.minutesAdded,
            message: `Recharge of ${minutesToAdd}m was already processed for this user within the last 2 minutes (TxID: ${d.id}). Provide an idempotencyKey for distinct transactions.`,
          });
        }
      }
    } catch (dupErr) {
      console.warn('[Wallet Recharge] Keyless duplicate check warning:', dupErr.message);
    }
  }

  try {
    const walletRef = firestoreDb.collection('users').doc(targetUid).collection('wallet').doc('current');
    // Deterministic fallback ID tied to user, minutes, and 1-minute time bucket to prevent retry double-credit
    const timeBucket = Math.floor(Date.now() / 60000);
    const txId = cleanIdempotencyKey
      ? (cleanIdempotencyKey.startsWith('tx_') ? cleanIdempotencyKey : `tx_${cleanIdempotencyKey}`)
      : `rcg_tx_${targetUid.substring(0, 8)}_${minutesToAdd}_${timeBucket}`;
    const txRef = firestoreDb.collection('recharge_transactions').doc(txId);

    const result = await firestoreDb.runTransaction(async (transaction) => {
      // 1. Check idempotency: READ txRef before writes!
      const txDoc = await transaction.get(txRef);
      if (txDoc.exists) {
        const existingTx = txDoc.data() || {};
        return {
          alreadyProcessed: true,
          transactionId: txId,
          minutesAdded: existingTx.minutesAdded || minutesToAdd,
        };
      }

      // 2. READ walletRef
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
        idempotencyKey: cleanIdempotencyKey || null,
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

      return {
        alreadyProcessed: false,
        wallet: walletUpdate,
        transactionId: txId,
      };
    });

    if (result.alreadyProcessed) {
      console.log(`[SaaS Billing] Recharge idempotent retry detected for ${txId}. Returning existing status.`);
      return res.json({
        success: true,
        alreadyProcessed: true,
        transactionId: txId,
        message: 'Recharge already processed (idempotent)',
      });
    }

    console.log(`[SaaS Billing] Admin recharged ${minutesToAdd} minutes for user ${targetUid}. New balance: ${result.wallet.balanceMinutes} mins.`);
    return res.json({ success: true, wallet: result.wallet, transactionId: txId });
  } catch (err) {
    console.error('[SaaS Billing] Error processing wallet recharge:', err.message);
    return res.status(500).json({ error: 'Failed to process recharge', message: err.message });
  }
});

// Admin metrics overview endpoint
// One-time privacy migration: remove the legacy `phone` field from user docs so
// an authenticated stranger can no longer read another person's number by uid.
// Safe to run repeatedly; use { "dryRun": true } to preview counts first.
app.post('/api/admin/scrub-user-phones', authenticateAdmin, async (req, res) => {
  if (!firestoreDb) {
    return res.status(503).json({ error: 'Firestore database service is currently unavailable' });
  }
  const dryRun = req.body?.dryRun === true;
  let scanned = 0;
  let scrubbed = 0;

  try {
    let lastDoc = null;
    for (;;) {
      let query = firestoreDb.collection('users').orderBy('__name__').limit(200);
      if (lastDoc) query = query.startAfter(lastDoc);
      const snap = await query.get();
      if (snap.empty) break;

      const batch = firestoreDb.batch();
      let queued = 0;
      snap.forEach((doc) => {
        scanned += 1;
        const data = doc.data() || {};
        if (Object.prototype.hasOwnProperty.call(data, 'phone')) {
          scrubbed += 1;
          if (!dryRun) {
            batch.update(doc.ref, { phone: FieldValue.delete() });
            queued += 1;
          }
        }
      });
      if (!dryRun && queued > 0) await batch.commit();

      lastDoc = snap.docs[snap.docs.length - 1];
      if (snap.size < 200) break;
    }

    return res.json({ success: true, dryRun, scanned, scrubbed });
  } catch (err) {
    console.error('[Privacy] scrub-user-phones failed:', err.message);
    return res.status(500).json({ error: 'Migration failed', message: err.message });
  }
});

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

// P2P In-Chat Minute Transfer (Atomic User A -> User B) with Idempotency Protection
app.post('/api/wallet/p2p-transfer', authenticateRequest, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'Firestore service unavailable' });

  const fromUserId = req.user?.uid;
  const { toUserId, minutes, note, idempotencyKey, messageId } = req.body || {};

  if (!fromUserId) {
    return res.status(401).json({ error: 'Unauthorized: missing sender UID' });
  }
  if (!toUserId || typeof toUserId !== 'string' || !/^[a-zA-Z0-9_\-]{6,128}$/.test(toUserId.trim())) {
    return res.status(400).json({ error: 'Valid recipient toUserId is required (6-128 alphanumeric characters)' });
  }
  if (fromUserId === toUserId) {
    return res.status(400).json({ error: 'Cannot transfer minutes to yourself' });
  }

  // Strict payment & idempotency format validation
  if (idempotencyKey && (typeof idempotencyKey !== 'string' || !/^[a-zA-Z0-9_\-]{8,128}$/.test(idempotencyKey.trim()))) {
    return res.status(400).json({ error: 'Invalid idempotencyKey format. Must be 8-128 alphanumeric characters, underscores, or hyphens.' });
  }
  if (messageId && (typeof messageId !== 'string' || !/^[a-zA-Z0-9_\-]{8,128}$/.test(messageId.trim()))) {
    return res.status(400).json({ error: 'Invalid messageId format.' });
  }

  const mins = parseInt(minutes, 10);
  if (isNaN(mins) || mins <= 0) {
    return res.status(400).json({ error: 'Minutes to transfer must be a positive integer' });
  }

  // Idempotency key sanitization
  const rawIdempotencyKey = idempotencyKey || req.headers['idempotency-key'];
  const cleanIdempotencyKey = (typeof rawIdempotencyKey === 'string' && rawIdempotencyKey.trim().length > 0)
    ? rawIdempotencyKey.trim().replace(/[^a-zA-Z0-9_-]/g, '').substring(0, 64)
    : null;

  try {
    // 0. Safety duplicate check: prevent rapid double-debit if client retried or had network timeout
    const oneMinuteAgoIso = new Date(Date.now() - 60 * 1000).toISOString();
    try {
      const recentTransfers = await firestoreDb.collection('p2p_transfers')
        .where('fromUserId', '==', fromUserId)
        .where('toUserId', '==', toUserId)
        .where('status', '==', 'completed')
        .where('createdAt', '>=', oneMinuteAgoIso)
        .limit(5)
        .get();

      for (const d of recentTransfers.docs) {
        const tData = d.data() || {};
        if (tData.minutes === mins) {
          return res.json({
            success: true,
            alreadyProcessed: true,
            transferId: d.id,
            remainingMinutes: tData.senderBalanceAfter ?? null,
            transferredMinutes: tData.minutes || mins,
            message: 'Transfer already processed recently (idempotent duplicate prevention).',
          });
        }
      }
    } catch (dupErr) {
      console.warn('[P2P Transfer] Duplicate check warning:', dupErr.message);
    }

    const senderRef = firestoreDb.collection('users').doc(fromUserId).collection('wallet').doc('current');
    const receiverRef = firestoreDb.collection('users').doc(toUserId).collection('wallet').doc('current');
    const transferId = cleanIdempotencyKey
      ? `p2p_idem_${cleanIdempotencyKey}`
      : `p2p_min_${fromUserId.substring(0, 8)}_${toUserId.substring(0, 8)}_${mins}_${Math.floor(Date.now() / 60000)}`;
    const transferRef = firestoreDb.collection('p2p_transfers').doc(transferId);

    const result = await firestoreDb.runTransaction(async (tx) => {
      // 1. Idempotency Check: if transfer was already executed, return existing record without double-debiting
      const transferSnap = await tx.get(transferRef);
      if (transferSnap.exists) {
        const existingData = transferSnap.data() || {};
        if (existingData.fromUserId && existingData.fromUserId !== fromUserId) {
          throw new Error('Idempotency key collision from another user');
        }
        return {
          alreadyProcessed: true,
          transferId,
          remainingMinutes: existingData.senderBalanceAfter ?? null,
          transferredMinutes: existingData.minutes || mins,
        };
      }

      // 2. Fetch sender wallet
      const senderSnap = await tx.get(senderRef);
      if (!senderSnap.exists) {
        throw new Error('Sender wallet does not exist');
      }

      const senderData = senderSnap.data() || {};
      const senderBalance = Number(senderData.balanceMinutes || 0);
      if (senderBalance < mins) {
        throw new Error(`Insufficient minute balance. Current: ${senderBalance}, Requested: ${mins}`);
      }

      // 3. Fetch receiver wallet
      const receiverSnap = await tx.get(receiverRef);
      let receiverBalance = 0;
      let receiverPurchased = 0;
      if (receiverSnap.exists) {
        const rData = receiverSnap.data() || {};
        receiverBalance = Number(rData.balanceMinutes || 0);
        receiverPurchased = Number(rData.totalMinutesPurchased || 0);
      }

      const nowIso = new Date().toISOString();

      // 4. Atomic Deduct & Credit
      tx.set(senderRef, {
        balanceMinutes: senderBalance - mins,
        updatedAt: nowIso,
      }, { merge: true });

      tx.set(receiverRef, {
        balanceMinutes: receiverBalance + mins,
        totalMinutesPurchased: receiverPurchased + mins,
        updatedAt: nowIso,
      }, { merge: true });

      // 5. Immutable central audit record for Admin Panel
      const equivalentUsd = Number((mins / 7).toFixed(2));
      tx.set(transferRef, {
        id: transferId,
        idempotencyKey: cleanIdempotencyKey || null,
        messageId: (typeof messageId === 'string' && messageId.trim().length > 0) ? messageId.trim() : null,
        boundMessageId: (typeof messageId === 'string' && messageId.trim().length > 0) ? messageId.trim() : null,
        type: 'minute_transfer',
        fromUserId,
        toUserId,
        minutes: mins,
        amount: `$${equivalentUsd}`,
        usdAmount: equivalentUsd,
        senderBalanceBefore: senderBalance,
        senderBalanceAfter: senderBalance - mins,
        note: sanitizeBoundedNote(note, 100),
        status: 'completed',
        method: 'Livocal Wallet',
        createdAt: nowIso,
      });

      return {
        alreadyProcessed: false,
        transferId,
        remainingMinutes: senderBalance - mins,
      };
    });

    return res.json({
      success: true,
      message: result.alreadyProcessed
        ? `Transfer already processed (idempotent)`
        : `Successfully transferred ${mins} minutes`,
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
      adminNote: sanitizeBoundedNote(note, 500),
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

  const bkashNum = (docData?.bkashNumber || process.env.BKASH_NUMBER || '').trim();
  const nagadNum = (docData?.nagadNumber || process.env.NAGAD_NUMBER || '').trim();
  const binancePayId = (docData?.binancePayId || process.env.BINANCE_PAY_ID || '').trim();
  const trc20Addr = (docData?.cryptoUsdtTrc20 || process.env.CRYPTO_USDT_TRC20 || '').trim();
  const bep20Addr = (docData?.cryptoUsdtBep20 || process.env.CRYPTO_USDT_BEP20 || '').trim();

  return { bkashNum, nagadNum, binancePayId, trc20Addr, bep20Addr };
}

// Public / authenticated endpoint for clients to get active deposit accounts & addresses dynamically
app.get('/api/wallet/deposit-info', authenticateUserOrAdmin, async (req, res) => {
  const { bkashNum, nagadNum, binancePayId, trc20Addr, bep20Addr } = await getDepositGateways();

  res.json({
    success: true,
    depositInfo: {
      bkash: {
        number: bkashNum || null,
        type: 'Personal / Send Money',
        isConfigured: !!bkashNum,
      },
      nagad: {
        number: nagadNum || null,
        type: 'Personal / Send Money',
        isConfigured: !!nagadNum,
      },
      binancePay: {
        payId: binancePayId || null,
        name: 'Livocal Global',
        isConfigured: !!binancePayId,
      },
      cryptoUsdt: {
        trc20: {
          network: 'TRC-20',
          networkName: 'Tron (TRC-20)',
          address: trc20Addr || null,
          explorerUrl: 'https://tronscan.org/#/transaction/',
          isConfigured: !!trc20Addr,
        },
        bep20: {
          network: 'BEP-20',
          networkName: 'BNB Smart Chain (BEP-20)',
          address: bep20Addr || null,
          explorerUrl: 'https://bscscan.com/tx/',
          isConfigured: !!bep20Addr,
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

  if (cleanBkash && !BD_PHONE_REGEX.test(cleanBkash.replace(/[\s\-]/g, ''))) {
    return res.status(400).json({ error: 'Invalid bKash phone number format. Must be a valid Bangladeshi number (e.g. 017XXXXXXXX or +8801XXXXXXXX).' });
  }
  if (cleanNagad && !BD_PHONE_REGEX.test(cleanNagad.replace(/[\s\-]/g, ''))) {
    return res.status(400).json({ error: 'Invalid Nagad phone number format. Must be a valid Bangladeshi number (e.g. 018XXXXXXXX or +8801XXXXXXXX).' });
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

// Fetch recipient's payment receiving accounts for P2P transfers
app.get('/api/wallet/recipient-payment-settings', authenticateRequest, async (req, res) => {
  const recipientId = (req.query.recipientId || req.query.userId || '').trim();
  if (!recipientId) {
    return res.status(400).json({ error: 'recipientId is required' });
  }

  if (!firestoreDb) {
    return res.status(503).json({ error: 'Database service unavailable' });
  }

  try {
    const userDocRef = firestoreDb.collection('users').doc(recipientId);
    const [userDoc, walletSettingsDoc] = await Promise.all([
      userDocRef.get(),
      userDocRef.collection('wallet').doc('payment_settings').get()
    ]);

    if (!userDoc.exists && !walletSettingsDoc.exists) {
      return res.status(404).json({ error: 'Recipient not found' });
    }

    const userData = userDoc.exists ? userDoc.data() : {};
    const walletData = walletSettingsDoc.exists ? walletSettingsDoc.data() : {};

    const binancePayId = (walletData.binancePayId || userData.binancePayId || '').trim();
    const cryptoUsdtTrc20 = (walletData.cryptoUsdtTrc20 || userData.cryptoUsdtTrc20 || '').trim();
    const cryptoUsdtBep20 = (walletData.cryptoUsdtBep20 || userData.cryptoUsdtBep20 || '').trim();
    const bkashNumber = (walletData.bkashNumber || userData.bkashNumber || '').trim();
    const nagadNumber = (walletData.nagadNumber || userData.nagadNumber || '').trim();

    return res.json({
      success: true,
      recipientId,
      binancePayId: binancePayId || null,
      cryptoUsdtTrc20: cryptoUsdtTrc20 || null,
      cryptoUsdtBep20: cryptoUsdtBep20 || null,
      bkashNumber: bkashNumber || null,
      nagadNumber: nagadNumber || null,
      isConfigured: !!(binancePayId || cryptoUsdtTrc20 || cryptoUsdtBep20 || bkashNumber || nagadNumber),
    });
  } catch (err) {
    console.error('[Wallet] recipient-payment-settings error:', err);
    return res.status(500).json({ error: 'Failed to fetch recipient payment settings' });
  }
});

// Authenticated user updates their own receiving payment accounts
app.post('/api/wallet/my-payment-settings', authenticateRequest, async (req, res) => {
  const userId = req.user.uid;
  const {
    binancePayId,
    cryptoUsdtTrc20,
    cryptoUsdtBep20,
    bkashNumber,
    nagadNumber,
  } = req.body || {};

  if (!firestoreDb) {
    return res.status(503).json({ error: 'Database service unavailable' });
  }

  // Address & Account validations
  const cleanBinance = typeof binancePayId === 'string' ? binancePayId.trim() : '';
  const cleanTrc20 = typeof cryptoUsdtTrc20 === 'string' ? cryptoUsdtTrc20.trim() : '';
  const cleanBep20 = typeof cryptoUsdtBep20 === 'string' ? cryptoUsdtBep20.trim() : '';
  const cleanBkash = typeof bkashNumber === 'string' ? bkashNumber.trim() : '';
  const cleanNagad = typeof nagadNumber === 'string' ? nagadNumber.trim() : '';

  if (cleanBinance && !validateBinancePayId(cleanBinance)) {
    return res.status(400).json({ error: 'Invalid Binance Pay ID format. Must be an 8-12 digit ID or a valid email address.' });
  }

  if (cleanBkash && !BD_PHONE_REGEX.test(cleanBkash.replace(/[\s\-]/g, ''))) {
    return res.status(400).json({ error: 'Invalid bKash number. Must be a valid 11-digit Bangladeshi mobile number (e.g. 017XXXXXXXX or +8801XXXXXXXX).' });
  }

  if (cleanNagad && !BD_PHONE_REGEX.test(cleanNagad.replace(/[\s\-]/g, ''))) {
    return res.status(400).json({ error: 'Invalid Nagad number. Must be a valid 11-digit Bangladeshi mobile number (e.g. 018XXXXXXXX or +8801XXXXXXXX).' });
  }

  if (cleanTrc20 && !validateTronAddress(cleanTrc20)) {
    return res.status(400).json({ error: 'Invalid TRC-20 USDT address format. Must start with T and be 34 Base58 characters.' });
  }

  if (cleanBep20 && !validateBscAddress(cleanBep20)) {
    return res.status(400).json({ error: 'Invalid BEP-20 USDT address format. Must start with 0x and be 42 characters.' });
  }

  const payload = {
    binancePayId: cleanBinance,
    cryptoUsdtTrc20: cleanTrc20,
    cryptoUsdtBep20: cleanBep20,
    bkashNumber: cleanBkash,
    nagadNumber: cleanNagad,
    updatedAt: new Date().toISOString(),
  };

  try {
    const userRef = firestoreDb.collection('users').doc(userId);
    const batch = firestoreDb.batch();

    // 1. Save in user's wallet/payment_settings subcollection
    const settingsRef = userRef.collection('wallet').doc('payment_settings');
    batch.set(settingsRef, payload, { merge: true });

    // 2. Scrub any legacy payment fields from the public parent user document to isolate PII
    try {
      const userDoc = await userRef.get();
      if (userDoc.exists) {
        batch.update(userRef, {
          binancePayId: FieldValue.delete(),
          cryptoUsdtTrc20: FieldValue.delete(),
          cryptoUsdtBep20: FieldValue.delete(),
          bkashNumber: FieldValue.delete(),
          nagadNumber: FieldValue.delete(),
        });
      }
    } catch (scrubErr) {
      console.warn('[Wallet] Non-fatal error scrubbing legacy payment fields from user doc:', scrubErr.message);
    }

    await batch.commit();

    return res.json({
      success: true,
      message: 'Payment settings saved successfully',
      settings: payload,
    });
  } catch (err) {
    console.error('[Wallet] my-payment-settings error:', err);
    return res.status(500).json({ error: 'Failed to update payment settings' });
  }
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
  } else if (method === 'bKash' || method === 'Nagad') {
    if (!BD_PHONE_REGEX.test(identifier)) {
      return res.status(400).json({ error: `Invalid ${method} sender phone number. Must be a valid Bangladeshi number (e.g. 017XXXXXXXX or +8801XXXXXXXX).` });
    }
  }

  const isCrypto = method === 'Binance_Pay' || method.startsWith('Crypto_USDT');
  const currency = isCrypto ? 'USDT' : 'BDT';
  const expectedAmount = isCrypto ? selectedPack.priceUsdt : selectedPack.priceBdt;

  // Fail-Closed Guard: Ensure deposit gateway is configured on server
  const gateways = await getDepositGateways();
  let gatewayAddress = '';
  if (method === 'bKash') gatewayAddress = gateways.bkashNum;
  else if (method === 'Nagad') gatewayAddress = gateways.nagadNum;
  else if (method === 'Binance_Pay') gatewayAddress = gateways.binancePayId;
  else if (method === 'Crypto_USDT_TRC20') gatewayAddress = gateways.trc20Addr;
  else if (method === 'Crypto_USDT_BEP20') gatewayAddress = gateways.bep20Addr;

  if (!gatewayAddress) {
    return res.status(503).json({
      error: `Payment gateway for ${method} is not configured on the server. Please select another payment method or contact support.`,
    });
  }

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
          notes: sanitizeBoundedNote(notes || 'Verified and approved', 500),
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
          notes: sanitizeBoundedNote(notes || 'Payment rejected by admin', 500),
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
      const gateways = await getDepositGateways();
      const expectedDeposit = targetAddress || gateways.trc20Addr;
      if (!expectedDeposit) {
        return res.status(400).json({ verified: false, error: 'Tron (TRC-20) deposit address is not configured on the server.' });
      }
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
      const gateways = await getDepositGateways();
      const expectedDeposit = targetAddress || gateways.bep20Addr;
      if (!expectedDeposit) {
        return res.status(400).json({ verified: false, error: 'BSC (BEP-20) deposit address is not configured on the server.' });
      }
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

// Admin Manual Top-up endpoint with Idempotency Protection
app.post('/api/admin/wallet/topup', authenticateAdmin, async (req, res) => {
  const { phone, userId, minutes, amount, notes, adminName, idempotencyKey, transactionId } = req.body || {};
  const minutesToAdd = parseInt(minutes, 10);
  if (isNaN(minutesToAdd) || minutesToAdd <= 0) {
    return res.status(400).json({ error: 'Valid minutes amount required' });
  }

  if (!firestoreDb) return res.status(503).json({ error: 'Firestore service unavailable' });

  // Idempotency key sanitization
  const rawIdempotencyKey = idempotencyKey || req.headers['idempotency-key'] || transactionId;
  const cleanIdempotencyKey = (typeof rawIdempotencyKey === 'string' && rawIdempotencyKey.trim().length > 0)
    ? rawIdempotencyKey.trim().replace(/[^a-zA-Z0-9_-]/g, '').substring(0, 64)
    : null;

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

    // Safety duplicate prevention: ONLY check 120s window for KEYLESS requests.
    // Distinct requests with distinct idempotency keys (e.g. separate manual topups from modal) must proceed unhindered!
    if (!cleanIdempotencyKey) {
      const twoMinutesAgoIso = new Date(Date.now() - 120 * 1000).toISOString();
      try {
        const recentDuplicates = await firestoreDb.collection('recharge_transactions')
          .where('userId', '==', targetUid)
          .where('packId', '==', 'admin_topup')
          .where('status', '==', 'completed')
          .where('createdAt', '>=', twoMinutesAgoIso)
          .limit(5)
          .get();

        for (const d of recentDuplicates.docs) {
          const txData = d.data() || {};
          if (txData.minutesAdded === minutesToAdd) {
            return res.status(200).json({
              success: true,
              alreadyProcessed: true,
              transactionId: d.id,
              minutesAdded: txData.minutesAdded,
              message: `Keyless top-up of ${minutesToAdd}m was already credited to this user within the last 2 minutes (TxID: ${d.id}). Provide an explicit idempotencyKey for distinct transactions.`,
            });
          }
        }
      } catch (dupErr) {
        console.warn('[Admin Topup] Duplicate check warning:', dupErr.message);
      }
    }

    const walletRef = firestoreDb.collection('users').doc(targetUid).collection('wallet').doc('current');
    // Deterministic fallback key tied to user, minutes, and 1-minute time bucket if no idempotency key provided
    const txId = cleanIdempotencyKey
      ? (cleanIdempotencyKey.startsWith('topup_') ? cleanIdempotencyKey : `topup_${cleanIdempotencyKey}`)
      : `adm_tx_${targetUid.substring(0, 8)}_${minutesToAdd}_${Math.floor(Date.now() / 60000)}`;
    const txRef = firestoreDb.collection('recharge_transactions').doc(txId);

    const nowIso = new Date().toISOString();

    const result = await firestoreDb.runTransaction(async (transaction) => {
      // 1. Check idempotency: READ txRef before writes!
      const txDoc = await transaction.get(txRef);
      if (txDoc.exists) {
        const existingTx = txDoc.data() || {};
        return {
          alreadyProcessed: true,
          wallet: null,
          transactionId: txId,
          minutesAdded: existingTx.minutesAdded || minutesToAdd,
        };
      }

      // 2. READ walletRef
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
        idempotencyKey: cleanIdempotencyKey || null,
        userId: targetUid,
        userPhone: phone || data.phone || '',
        packId: 'admin_topup',
        minutesAdded: minutesToAdd,
        amountPaid: Number(amount) || 0,
        currency: 'BDT',
        paymentMethod: 'Admin Manual Credit',
        notes: sanitizeBoundedNote(notes || `Credited by ${adminName || 'SuperAdmin'}`, 500),
        status: 'completed',
        createdAt: nowIso,
      });

      return {
        alreadyProcessed: false,
        wallet: updated,
        transactionId: txId,
      };
    });

    if (result.alreadyProcessed) {
      console.log(`[Admin] Topup idempotent retry detected for ${txId}. Returning existing status.`);
      return res.json({
        success: true,
        alreadyProcessed: true,
        userId: targetUid,
        transactionId: txId,
        message: 'Top-up already processed (idempotent)',
      });
    }

    console.log(`[Admin] Successfully topped up ${minutesToAdd} minutes for user ${targetUid}`);
    return res.json({ success: true, userId: targetUid, wallet: result.wallet, transactionId: txId });
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
 * POST /api/admin/migrate-user-payment-pii
 * Authenticated admin endpoint to scrub legacy payment addresses from all /users documents
 * and migrate them into users/{userId}/wallet/payment_settings.
 * Eliminates PII leaks and prevents rules update violations for legacy users.
 */
app.post('/api/admin/migrate-user-payment-pii', authenticateAdmin, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'Firestore service unavailable' });

  const PAYMENT_FIELDS = [
    'binancePayId',
    'cryptoUsdtTrc20',
    'cryptoUsdtBep20',
    'bkashNumber',
    'nagadNumber',
  ];

  try {
    const usersSnapshot = await firestoreDb.collection('users').get();
    let scannedUsers = 0;
    let migratedUsers = 0;
    let scrubbedUsers = 0;

    for (const userDoc of usersSnapshot.docs) {
      scannedUsers++;
      const userData = userDoc.data();
      const paymentUpdates = {};
      const deleteUpdates = {};
      let hasLegacyPayment = false;

      for (const field of PAYMENT_FIELDS) {
        if (field in userData) {
          hasLegacyPayment = true;
          const val = userData[field];
          if (typeof val === 'string' && val.trim().length > 0) {
            paymentUpdates[field] = val.trim();
          }
          deleteUpdates[field] = FieldValue.delete();
        }
      }

      if (hasLegacyPayment) {
        const batch = firestoreDb.batch();
        if (Object.keys(paymentUpdates).length > 0) {
          const settingsRef = userDoc.ref.collection('wallet').doc('payment_settings');
          paymentUpdates.updatedAt = new Date().toISOString();
          paymentUpdates.migratedFromUserDoc = true;
          batch.set(settingsRef, paymentUpdates, { merge: true });
          migratedUsers++;
        }
        batch.update(userDoc.ref, deleteUpdates);
        await batch.commit();
        scrubbedUsers++;
      }
    }

    try {
      await firestoreDb.collection('_system_migrations').doc('payment_pii_isolation').set({
        completed: true,
        completedAt: new Date().toISOString(),
        scannedUsers,
        migratedUsers,
        scrubbedUsers,
        triggeredBy: 'admin_api',
      }, { merge: true });
    } catch (saveErr) {
      console.warn('[AdminMigratePaymentPII] Could not save migration status doc:', saveErr.message);
    }

    return res.json({
      success: true,
      scannedUsers,
      migratedUsers,
      scrubbedUsers,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    console.error('[AdminMigratePaymentPII] Error:', err.message);
    return res.status(500).json({ error: 'Failed to migrate user payment fields', details: err.message });
  }
});

/**
 * Authoritative background sweeper to purge expired disappearing messages across all chats.
 * Compares Firestore Timestamps accurately without cross-type serialization flaws.
 */
async function purgeExpiredMessagesCore() {
  if (!firestoreDb) return 0;
  const nowTimestamp = Timestamp.now();
  let deletedCount = 0;
  let lastChatDoc = null;
  let hasMore = true;

  while (hasMore) {
    let query = firestoreDb.collection('chats').limit(100);
    if (lastChatDoc) {
      query = query.startAfter(lastChatDoc);
    }
    const chatsSnap = await query.get();
    if (chatsSnap.empty) {
      hasMore = false;
      break;
    }
    lastChatDoc = chatsSnap.docs[chatsSnap.docs.length - 1];
    if (chatsSnap.docs.length < 100) {
      hasMore = false;
    }

    for (const chatDoc of chatsSnap.docs) {
      const msgsSnap = await chatDoc.ref.collection('messages')
        .where('expiresAt', '<=', nowTimestamp)
        .limit(100)
        .get();

      if (msgsSnap.empty) continue;

      const purgedIds = [];
      for (const mDoc of msgsSnap.docs) {
        await mDoc.ref.delete();
        purgedIds.push(mDoc.id);
        deletedCount++;
      }

      // Notify recipient device with high-priority silent FCM push to purge local Isar storage immediately!
      const recipientUid = chatDoc.id;
      if (purgedIds.length > 0) {
        try {
          const userDoc = await firestoreDb.collection('users').doc(recipientUid).get();
          const fcmToken = userDoc.data()?.fcmToken;
          if (fcmToken) {
            const messaging = getMessaging();
            await messaging.send({
              token: fcmToken,
              data: {
                type: 'PURGE_EXPIRED',
                messageId: purgedIds[0],
                messageIds: JSON.stringify(purgedIds),
              },
              android: { priority: 'high' },
            }).catch(e => console.warn(`[PurgePush] Error sending to ${recipientUid}:`, e.message));
          }
        } catch (pushErr) {
          console.warn(`[PurgePush] FCM lookup failed for ${recipientUid}:`, pushErr.message);
        }
      }
    }
  }
  return deletedCount;
}

// Scheduled server-side cleanup task: runs every 10 minutes to guarantee cloud disappearing message deletion
setInterval(async () => {
  try {
    const count = await purgeExpiredMessagesCore();
    if (count > 0) {
      console.log(`[DisappearingMessages] Scheduled server purge deleted ${count} expired message(s)`);
    }
  } catch (err) {
    console.warn('[DisappearingMessages] Scheduled server purge note:', err.message);
  }
}, 10 * 60 * 1000);

/**
 * POST /api/admin/purge-expired-messages
 * Authenticated admin endpoint to safely purge expired disappearing messages using Firestore Timestamps.
 * Strictly protected by authenticateAdmin middleware and uses Timestamp comparison to avoid cross-type bugs.
 */
app.post('/api/admin/purge-expired-messages', authenticateAdmin, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'Firestore service unavailable' });
  try {
    const deletedCount = await purgeExpiredMessagesCore();
    return res.json({
      success: true,
      purgedCount: deletedCount,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    console.error('[AdminPurgeMessages] Error purging expired messages:', err.message);
    return res.status(500).json({ error: 'Failed to purge expired messages' });
  }
});

/**
 * GET /api/admin/reports
 * Authenticated admin endpoint to review abuse and contact reports.
 * Protected by authenticateAdmin middleware.
 */
app.get('/api/admin/reports', authenticateAdmin, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'Firestore service unavailable' });
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 50, 100);
    const snap = await firestoreDb.collection('reports')
      .orderBy('timestamp', 'desc')
      .limit(limit)
      .get();

    const reports = snap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      timestamp: doc.data().timestamp?.toDate ? doc.data().timestamp.toDate().toISOString() : null,
    }));

    return res.json({
      success: true,
      count: reports.length,
      reports,
    });
  } catch (err) {
    console.error('[AdminReports] Error fetching reports:', err.message);
    return res.status(500).json({ error: 'Failed to fetch reports' });
  }
});

/**
 * POST /api/admin/reports/:id/action
 * Authenticated admin endpoint to update review status of a report.
 */
app.post('/api/admin/reports/:id/action', authenticateAdmin, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'Firestore service unavailable' });
  try {
    const { id } = req.params;
    const { status, adminNotes } = req.body;
    if (!status || !['pending_review', 'resolved', 'dismissed', 'action_taken'].includes(status)) {
      return res.status(400).json({ error: 'Invalid report status' });
    }

    const reportRef = firestoreDb.collection('reports').doc(id);
    const doc = await reportRef.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Report not found' });
    }

    await reportRef.update({
      status,
      adminNotes: adminNotes || null,
      reviewedAt: new Date().toISOString(),
    });

    return res.json({ success: true, id, status });
  } catch (err) {
    console.error('[AdminReports] Error updating report:', err.message);
    return res.status(500).json({ error: 'Failed to update report status' });
  }
});

/**
 * GET /api/admin/whoami
 * Lets the dashboard detect an existing session cookie without asking for the
 * secret again.
 */
app.get('/api/admin/whoami', authenticateAdmin, (req, res) => {
  res.json({ ok: true });
});

/**
 * GET /api/admin/users?q=&limit=
 * Admin user directory. The public client can never list users; this endpoint
 * exists only behind the admin secret and masks phone numbers.
 */
app.get('/api/admin/users', authenticateAdmin, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'Firestore unavailable' });
  const q = String(req.query.q || '').trim().toLowerCase();
  const limit = Math.min(parseInt(req.query.limit || '40', 10) || 40, 200);

  try {
    const snap = await firestoreDb.collection('users').limit(500).get();
    const rows = [];
    for (const doc of snap.docs) {
      const d = doc.data() || {};
      const rawPhone = typeof d.phone === 'string'
        ? d.phone
        : (d.phone && typeof d.phone === 'object' ? `${d.phone.code || ''}${d.phone.number || ''}` : '');
      const name = String(d.name || '');
      const haystack = `${name} ${rawPhone} ${doc.id}`.toLowerCase();
      if (q && !haystack.includes(q)) continue;
      rows.push({
        id: doc.id,
        name,
        avatarUrl: d.avatarUrl || '',
        activityStatus: d.activityStatus || 'offline',
        spokenLanguage: d.spokenLanguage || '',
        phoneMasked: rawPhone ? `••••${rawPhone.slice(-4)}` : '',
      });
    }
    res.json({ users: rows.slice(0, limit), total: rows.length });
  } catch (err) {
    console.error('[AdminUsers] list error:', err.message);
    res.status(500).json({ error: 'Failed to list users' });
  }
});

/**
 * GET /api/admin/users/:uid
 * One-screen profile for support: wallet, recent calls, billing rows.
 */
app.get('/api/admin/users/:uid', authenticateAdmin, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'Firestore unavailable' });
  const uid = String(req.params.uid || '').trim();
  if (!uid || uid.length > 128) return res.status(400).json({ error: 'Invalid uid' });

  try {
    const userSnap = await firestoreDb.collection('users').doc(uid).get();
    if (!userSnap.exists) return res.status(404).json({ error: 'User not found' });

    const d = userSnap.data() || {};
    const [walletSnap, outgoing, incoming, billing] = await Promise.all([
      firestoreDb.collection('users').doc(uid).collection('wallet').doc('current').get(),
      firestoreDb.collection('calls').where('callerId', '==', uid).limit(20).get(),
      firestoreDb.collection('calls').where('calleeId', '==', uid).limit(20).get(),
      firestoreDb.collection('call_billing_records').where('userId', '==', uid).limit(20).get().catch(() => null),
    ]);

    const calls = [];
    for (const doc of [...outgoing.docs, ...incoming.docs]) {
      const c = doc.data() || {};
      calls.push({
        id: doc.id,
        callerId: c.callerId || '',
        calleeId: c.calleeId || '',
        status: c.status || '',
        durationSeconds: c.durationSeconds || 0,
        createdAt: c.createdAt || null,
      });
    }
    calls.sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')));

    const ledger = (billing?.docs || []).map((doc) => {
      const b = doc.data() || {};
      return {
        id: doc.id,
        minutes: b.minutes || b.deductedMinutes || 0,
        cost: b.cost || 0,
        at: b.createdAt || b.timestamp || null,
      };
    });

    res.json({
      user: {
        id: uid,
        name: d.name || '',
        avatarUrl: d.avatarUrl || '',
        activityStatus: d.activityStatus || 'offline',
        spokenLanguage: d.spokenLanguage || '',
        defaultDisappearingTimer: d.defaultDisappearingTimer || 'Off',
      },
      wallet: walletSnap.exists ? walletSnap.data() : null,
      calls: calls.slice(0, 20),
      ledger: ledger.slice(0, 20),
    });
  } catch (err) {
    console.error('[AdminUsers] detail error:', err.message);
    res.status(500).json({ error: 'Failed to load user' });
  }
});

/**
 * GET /api/admin/audit
 * Recent privileged actions (written by authenticateAdmin).
 */
app.get('/api/admin/audit', authenticateAdmin, async (req, res) => {
  if (!firestoreDb) return res.status(503).json({ error: 'Firestore unavailable' });
  const limit = Math.min(parseInt(req.query.limit || '100', 10) || 100, 300);
  try {
    const snap = await firestoreDb
      .collection('admin_audit')
      .orderBy('atMs', 'desc')
      .limit(limit)
      .get();
    const entries = snap.docs.map((doc) => ({ id: doc.id, ...(doc.data() || {}) }));
    res.json({ entries });
  } catch (err) {
    console.error('[AdminAudit] list error:', err.message);
    res.json({ entries: [] });
  }
});


app.post(
  '/api/contacts/match',
  apiLimiter,
  authenticateRequest,
  contactsLimiter,
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
        const [snap1, snap2, snap3] = await Promise.all([
          firestoreDb.collection('users').where('phone.rawNumber', 'in', chunk).get(),
          firestoreDb.collection('users').where('phone.number', 'in', chunk).get(),
          firestoreDb.collection('users').where('phone.formattedNumber', 'in', chunk).get(),
        ]);

        [...snap1.docs, ...snap2.docs, ...snap3.docs].forEach((doc) => {
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
  translateLimiter,
  validateBody(TranslateSchema),
  async (req, res) => {
    const { text, sourceLang, targetLang } = req.body;

    if (!GEMINI_API_KEY) {
      return res.status(503).json({ error: 'Gemini API key is not configured on the relay server' });
    }

    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${TEXT_MODEL}:generateContent?key=${GEMINI_API_KEY}`;
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

/**
 * Normalizes the model's JSON (or a code-fenced variant) into the public
 * summary shape. Returns null when the payload cannot be trusted.
 */
function normalizeCallSummary(value) {
  if (!value || typeof value !== 'object') return null;
  const asText = (v) => (typeof v === 'string' ? v.trim() : '');
  const asList = (v, max = 5) =>
    Array.isArray(v) ? v.map(asText).filter(Boolean).slice(0, max) : [];
  const summaryText = asText(value.summary);
  if (!summaryText) return null;

  const actionItems = Array.isArray(value.actionItems)
    ? value.actionItems
        .map((item) => {
          if (typeof item === 'string') return { text: item.trim(), owner: 'me' };
          if (!item || typeof item !== 'object') return null;
          const text = asText(item.text);
          if (!text) return null;
          return { text, owner: item.owner === 'client' ? 'client' : 'me' };
        })
        .filter(Boolean)
        .slice(0, 5)
    : [];

  return {
    summary: summaryText,
    decisions: asList(value.decisions),
    actionItems,
    clientHints: asText(value.clientHints),
  };
}

function parseCallSummaryJson(raw) {
  if (!raw) return null;
  const cleaned = String(raw).replace(/```json/gi, '').replace(/```/g, '').trim();
  const start = cleaned.indexOf('{');
  const end = cleaned.lastIndexOf('}');
  if (start === -1 || end <= start) return null;
  try {
    return normalizeCallSummary(JSON.parse(cleaned.slice(start, end + 1)));
  } catch (_) {
    return null;
  }
}

/**
 * Extractive fallback when Gemini is unavailable: no guessing, only lines that
 * were actually said.
 */
function buildFallbackCallSummary(transcript) {
  const lines = transcript.map(
    (item) => `${item.speaker === 'me' ? 'Me' : 'Client'}: ${item.text}`
  );
  const summary = lines.slice(0, 4).join(' ').slice(0, 600);
  const actionPattern =
    /\b(will|shall|send|share|prepare|confirm|pay|deliver|deadline|tomorrow|next week)\b|করব|পাঠাবো|দেব|শেষ করব/i;
  const actionItems = transcript
    .filter((item) => actionPattern.test(item.text))
    .slice(0, 3)
    .map((item) => ({
      text: item.text.slice(0, 300),
      owner: item.speaker === 'me' ? 'me' : 'client',
    }));
  return { summary, decisions: [], actionItems, clientHints: '' };
}

/**
 * POST /api/call/summary
 * Turns a translated call transcript into a bilingual summary with decisions
 * and action items. The raw transcript is used for this request only and is
 * never stored; only the resulting summary is kept at
 * calls/{callId}/summary/latest.
 */
app.post(
  '/api/call/summary',
  apiLimiter,
  authenticateRequest,
  translateLimiter,
  validateBody(CallSummarySchema),
  async (req, res) => {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });
    if (!firestoreDb) return res.status(503).json({ error: 'unavailable' });

    const { callId, durationSeconds, transcript } = req.body;
    const langPair = {
      a: req.body.langPair?.a || 'auto',
      b: req.body.langPair?.b || 'en',
    };

    // Participant guard: fail closed when the call document exists.
    try {
      const callSnap = await firestoreDb.collection('calls').doc(callId).get();
      if (callSnap.exists) {
        const call = callSnap.data() || {};
        const partyIds = [call.callerId, call.calleeId].filter(Boolean).map(String);
        const phone = req.user?.phone_number || '';
        const isParty =
          partyIds.includes(uid) ||
          (phone &&
            (partyIds.includes(`phone_${phone}`) || partyIds.includes(phone)));
        if (!isParty) return res.status(403).json({ error: 'forbidden' });
      }
    } catch (err) {
      console.error('[CallSummary] participant check failed:', err.message);
      return res.status(500).json({ error: 'failed' });
    }

    const transcriptText = transcript
      .map((item) => `${item.speaker === 'me' ? 'Me' : 'Client'}: ${item.text}`)
      .join('\n')
      .slice(0, 12000);

    const prompt = [
      'You are a meeting summarizer for a translated business call between a freelancer ("Me") and a client ("Client").',
      'Return ONLY JSON with this exact shape:',
      '{"summary":"3 concise sentences","decisions":["..."],"actionItems":[{"text":"...","owner":"me|client"}],"clientHints":"budget, timeline and scope hints"}',
      'Write summary, decisions, action items and clientHints bilingually: the English sentence followed by its Bangla translation separated by " / ".',
      'At most 5 decisions and 5 action items. Use empty arrays and an empty string when the transcript has no such content.',
      'Never invent facts that are not in the transcript.',
      '',
      'Transcript:',
      transcriptText,
    ].join('\n');

    let summary = null;
    let source = 'fallback';

    if (GEMINI_API_KEY) {
      try {
        const url = `https://generativelanguage.googleapis.com/v1beta/models/${TEXT_MODEL}:generateContent?key=${GEMINI_API_KEY}`;
        const apiRes = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
              temperature: 0.2,
              maxOutputTokens: 900,
              responseMimeType: 'application/json',
            },
          }),
        });
        if (apiRes.ok) {
          const data = await apiRes.json();
          const raw = data.candidates?.[0]?.content?.parts?.[0]?.text || '';
          summary = parseCallSummaryJson(raw);
          if (summary) source = 'gemini';
        } else {
          console.error('[CallSummary] Gemini HTTP status:', apiRes.status);
        }
      } catch (err) {
        console.error('[CallSummary] Gemini error:', err.message);
      }
    }

    if (!summary) summary = buildFallbackCallSummary(transcript);

    const stored = {
      summary: summary.summary,
      decisions: summary.decisions,
      actionItems: summary.actionItems,
      clientHints: summary.clientHints,
      langPair,
      durationSeconds,
      createdBy: uid,
      createdAt: FieldValue.serverTimestamp(),
    };

    try {
      await firestoreDb
        .collection('calls')
        .doc(callId)
        .collection('summary')
        .doc('latest')
        .set(stored);
    } catch (err) {
      console.error('[CallSummary] save failed:', err.message);
    }

    return res.json({
      summary: {
        summary: summary.summary,
        decisions: summary.decisions,
        actionItems: summary.actionItems,
        clientHints: summary.clientHints,
      },
      source,
    });
  }
);

const ReviewSchema = z.object({
  callId: z.string().min(1, 'callId is required').max(128),
  targetUid: z.string().min(1, 'targetUid is required').max(128),
  rating: z.number().int().min(1, 'rating must be 1-5').max(5),
  comment: z.string().max(500).optional(),
});

const ProposalSchema = z.object({
  displayName: z.string().max(80).optional(),
  headline: z.string().max(160).optional(),
  skills: z.array(z.string().max(40)).max(20).optional(),
  clientName: z.string().max(80).optional(),
  brief: z.string().max(1200).optional(),
  hints: z.string().max(800).optional(),
  rate: z
    .object({
      amount: z.number().min(0).max(1000000),
      currency: z.string().max(8),
      basis: z.string().max(16),
    })
    .optional(),
});

function fallbackProposal(input) {
  const skills = (input.skills || []).slice(0, 6).join(', ') || 'your project';
  const price = input.rate && input.rate.amount > 0
    ? `${input.rate.currency} ${input.rate.amount} per ${input.rate.basis === 'project' ? 'project' : 'hour'}`
    : 'To be agreed';
  const brief = (input.brief || '').trim();
  const bangla = /[\u0980-\u09FF]/.test(brief);

  if (bangla) {
    return {
      headline: `প্রস্তাব: ${brief ? brief.slice(0, 60) : 'আপনার প্রজেক্ট'}`,
      scope: `কাজের সারসংক্ষেপ: ${brief || 'আপনার প্রজেক্ট'}। আমি ${skills} দেখব। ডেলিভারেবল ও মাইলস্টোন শুরুর আগে লিখিতভাবে ঠিক হবে।`,
      timeline: '৩ কর্মদিবসে প্রথম ড্রাফট, রিভিশনসহ।',
      price: price.includes('project') ? `${price} (প্রজেক্ট অনুযায়ী)` : `${price} (ঘণ্টা অনুযায়ী)`,
      terms: '৫০% অগ্রিম, বাকিটা ডেলিভারির সময়। দুই রাউন্ড রিভিশন অন্তর্ভুক্ত।',
    };
  }

  return {
    headline: `Proposal: ${brief ? brief.slice(0, 60) : 'your project'}`,
    scope: `Scope: ${brief || 'your project'}. I will handle ${skills}. Deliverables and milestones are agreed in writing before the start.`,
    timeline: 'First draft within 3 working days, revisions included.',
    price,
    terms: '50% advance, balance on delivery. Two revision rounds included.',
  };
}
/**
 * POST /api/ai/proposal
 * Drafts a bilingual client proposal from the freelancer's profile data.
 * Nothing is stored server-side.
 */
app.post(
  '/api/ai/proposal',
  apiLimiter,
  authenticateRequest,
  translateLimiter,
  validateBody(ProposalSchema),
  async (req, res) => {
    const input = req.body || {};
    const skills = Array.isArray(input.skills) ? input.skills.slice(0, 20) : [];
    const rate = input.rate && input.rate.amount > 0 ? input.rate : null;

    const prompt = [
      'You are a senior freelancer writing a short, client-ready proposal.',
      'Return ONLY JSON with this exact shape:',
      '{"headline":"...","scope":"...","timeline":"...","price":"...","terms":"..."}',
      'Write every field in ONE language only: use the language of the Job brief (Bangla if the brief is Bangla, otherwise English). Never mix two languages.',
      'Scope: 3-5 short sentences. Timeline: concrete days/weeks. Price: use the given rate when present, otherwise ask for scope. Terms: 2 sentences (payment + revisions).',
      'Never invent certifications, clients, years of experience or skills that are not in the profile.',
      '',
      `Freelancer: ${input.displayName || 'Freelancer'}`,
      `Headline: ${input.headline || ''}`,
      `Skills: ${skills.join(', ')}`,
      `Client: ${input.clientName || 'Client'}`,
      `Rate: ${rate ? `${rate.currency} ${rate.amount} per ${rate.basis}` : 'not set'}`,
      `Job brief: ${(input.brief || '').slice(0, 1200)}`,
      `Extra context: ${(input.hints || '').slice(0, 800)}`,
    ].join('\n');

    let proposal = null;
    let source = 'fallback';
    let reason = '';

    if (OPENROUTER_API_KEY) {
      const models = [OPENROUTER_MODEL, OPENROUTER_FALLBACK_MODEL].filter(
        (model, index, list) => model && list.indexOf(model) === index
      );
      for (const model of models) {
        try {
          const apiRes = await fetch(
            'https://openrouter.ai/api/v1/chat/completions',
            {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${OPENROUTER_API_KEY}`,
                'HTTP-Referer': PUBLIC_BASE_URL || 'https://livocal.app',
                'X-Title': 'Livocal',
              },
              signal: AbortSignal.timeout(45000),
              body: JSON.stringify({
                model,
                temperature: 0.5,
                max_tokens: 900,
                messages: [
                  {
                    role: 'system',
                    content:
                      'You are a senior freelancer writing a short, client-ready proposal. Output JSON only.',
                  },
                  { role: 'user', content: prompt },
                ],
              }),
            }
          );
          if (apiRes.ok) {
            const data = await apiRes.json();
            const raw = data.choices?.[0]?.message?.content || '';
            proposal = parseProposalJson(raw);
            if (proposal) {
              source = 'openrouter';
              break;
            }
            reason = 'openrouter_parse';
          } else {
            reason = 'openrouter_http_' + apiRes.status;
            console.error('[Proposal] OpenRouter', model, 'HTTP', apiRes.status);
            if (apiRes.status === 401 || apiRes.status === 402) break;
          }
        } catch (err) {
          reason = 'openrouter_error';
          console.error('[Proposal] OpenRouter error:', err.message);
        }
      }
    }
    if (!proposal && GEMINI_API_KEY) {
      const geminiModels = [TEXT_MODEL, GEMINI_FALLBACK_TEXT_MODEL].filter(
        (model, index, list) => model && list.indexOf(model) === index
      );
      for (const model of geminiModels) {
        try {
          const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}`;
          const apiRes = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              contents: [{ parts: [{ text: prompt }] }],
              generationConfig: {
                temperature: 0.5,
                maxOutputTokens: 900,
                responseMimeType: 'application/json',
              },
            }),
          });
          if (apiRes.ok) {
            const data = await apiRes.json();
            const raw = data.candidates?.[0]?.content?.parts?.[0]?.text || '';
            proposal = parseProposalJson(raw);
            if (proposal) {
              source = 'gemini';
              break;
            }
            reason = 'gemini_parse';
          } else {
            reason = 'gemini_http_' + apiRes.status;
            console.error('[Proposal] Gemini', model, 'HTTP', apiRes.status);
          }
        } catch (err) {
          reason = 'gemini_error';
          console.error('[Proposal] Gemini error:', err.message);
        }
      }
    }
    if (!proposal) {
      if (!reason) reason = 'ai_not_configured';
      proposal = fallbackProposal({ ...input, skills, rate });
    }
    return res.json({ proposal, source, reason });
  }
);

function parseProposalJson(raw) {
  if (!raw) return null;
  const cleaned = String(raw).replace(/```json/gi, '').replace(/```/g, '').trim();
  const start = cleaned.indexOf('{');
  const end = cleaned.lastIndexOf('}');
  if (start === -1 || end <= start) return null;
  try {
    const value = JSON.parse(cleaned.slice(start, end + 1));
    const fields = ['headline', 'scope', 'timeline', 'price', 'terms'];
    const proposal = {};
    for (const field of fields) {
      const text = typeof value[field] === 'string' ? value[field].trim() : '';
      if (!text) return null;
      proposal[field] = text.slice(0, 2000);
    }
    return proposal;
  } catch (_) {
    return null;
  }
}

/**
 * POST /api/call/review
 * One rating per participant per call. Aggregates live on profiles/{uid} so
 * the public page can show them without exposing individual reviews.
 */
app.post(
  '/api/call/review',
  apiLimiter,
  authenticateRequest,
  validateBody(ReviewSchema),
  async (req, res) => {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ error: 'Unauthorized' });
    if (!firestoreDb) return res.status(503).json({ error: 'unavailable' });

    const { callId, targetUid, rating } = req.body;
    const comment = String(req.body.comment || '').trim().slice(0, 500);
    if (targetUid === uid) return res.status(400).json({ error: 'invalid_target' });

    try {
      const callSnap = await firestoreDb.collection('calls').doc(callId).get();
      if (!callSnap.exists) return res.status(403).json({ error: 'forbidden' });
      const call = callSnap.data() || {};
      const parties = [String(call.callerId || ''), String(call.calleeId || '')];
      if (!parties.includes(uid) || !parties.includes(targetUid)) {
        return res.status(403).json({ error: 'forbidden' });
      }

      const reviewId = `${callId}_${uid}`;
      const reviewRef = firestoreDb.collection('reviews').doc(reviewId);
      const profileRef = firestoreDb.collection('profiles').doc(targetUid);
      let duplicate = false;

      await firestoreDb.runTransaction(async (transaction) => {
        const existing = await transaction.get(reviewRef);
        if (existing.exists) {
          duplicate = true;
          return;
        }
        const profileSnap = await transaction.get(profileRef);
        const profile = profileSnap.exists ? profileSnap.data() || {} : {};
        const count = Number(profile.ratingCount || 0) + 1;
        const sum = Number(profile.ratingSum || 0) + rating;

        transaction.set(reviewRef, {
          callId,
          raterUid: uid,
          targetUid,
          rating,
          comment,
          createdAt: new Date().toISOString(),
        });
        if (profileSnap.exists) {
          transaction.update(profileRef, {
            ratingCount: count,
            ratingSum: sum,
            ratingAvg: Math.round((sum / count) * 100) / 100,
            updatedAt: new Date().toISOString(),
          });
        }
      });

      if (duplicate) return res.status(409).json({ error: 'already_reviewed' });
      return res.json({ ok: true });
    } catch (err) {
      console.error('[Review] error:', err.message);
      return res.status(500).json({ error: 'failed' });
    }
  }
);

/**
 * POST /api/account/delete
 * Full self-service account erasure. Deletes owned Storage objects, Firestore
 * documents/subcollections and finally the Firebase Auth record.
 *
 * Order is deliberate: destructive data cleanup runs first, Auth deletion is
 * last (point of no return). If any owned-data step fails we keep the Auth
 * user so the client can safely retry.
 */
app.post(
  '/api/account/delete',
  apiLimiter,
  authenticateRequest,
  async (req, res) => {
    const uid = req.user?.uid;
    if (!uid) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    // Explicit confirmation guards against accidental destructive calls.
    if (req.body?.confirm !== 'DELETE') {
      return res.status(400).json({ error: 'CONFIRMATION_REQUIRED' });
    }

    if (!firestoreDb || !authService) {
      return res.status(503).json({ error: 'Account service unavailable' });
    }

    const errors = [];
    const deleted = { calls: 0, statuses: 0, storageObjects: 0 };

    async function deleteStoragePrefix(prefix, filter) {
      if (!storageService) return 0;
      let count = 0;
      try {
        const bucket = storageService.bucket();
        let pageToken;
        do {
          const [files, nextQuery] = await bucket.getFiles({
            prefix,
            maxResults: 200,
            pageToken,
          });
          for (const file of files) {
            if (filter && !filter(file.name)) continue;
            await file.delete({ ignoreNotFound: true });
            count++;
          }
          pageToken = nextQuery?.pageToken;
        } while (pageToken);
      } catch (err) {
        console.error(
          `[AccountDelete] Storage prefix '${prefix}' failed for ${uid}:`,
          err?.message || err
        );
        errors.push(`storage:${prefix}`);
      }
      return count;
    }

    // 1. Owned Cloud Storage objects (avatars, statuses, sent attachments,
    //    and attachments received from other users).
    deleted.storageObjects += await deleteStoragePrefix(`userAvatars/${uid}/`);
    deleted.storageObjects += await deleteStoragePrefix(`avatars/${uid}.`);
    deleted.storageObjects += await deleteStoragePrefix(`statuses/${uid}/`);
    deleted.storageObjects += await deleteStoragePrefix(`attachments/${uid}/`);
    deleted.storageObjects += await deleteStoragePrefix('attachments/', (name) => {
      const parts = name.split('/');
      return parts.length >= 4 && parts[2] === uid;
    });

    // 2. Calls (includes transcripts and ICE candidate subcollections).
    try {
      for (const field of ['callerId', 'calleeId']) {
        const snap = await firestoreDb
          .collection('calls')
          .where(field, '==', uid)
          .get();
        for (const doc of snap.docs) {
          await firestoreDb.recursiveDelete(doc.ref);
          deleted.calls++;
        }
      }
    } catch (err) {
      console.error(`[AccountDelete] Calls cleanup failed for ${uid}:`, err?.message || err);
      errors.push('calls');
    }

    // 3. Status updates authored by the user.
    try {
      const snap = await firestoreDb
        .collection('statuses')
        .where('userId', '==', uid)
        .get();
      for (const doc of snap.docs) {
        await firestoreDb.recursiveDelete(doc.ref);
        deleted.statuses++;
      }
    } catch (err) {
      console.error(`[AccountDelete] Statuses cleanup failed for ${uid}:`, err?.message || err);
      errors.push('statuses');
    }

    // 4. Own chat inbox. Messages already delivered to other users' inboxes
    //    remain with the recipient (same behaviour as mainstream messengers).
    try {
      await firestoreDb
        .recursiveDelete(firestoreDb.collection('chats').doc(uid));
    } catch (err) {
      console.error(`[AccountDelete] Inbox cleanup failed for ${uid}:`, err?.message || err);
      errors.push('chats');
    }

    // 5. Push token.
    try {
      await firestoreDb.collection('fcmTokens').doc(uid).delete();
    } catch (err) {
      console.error(`[AccountDelete] FCM token cleanup failed for ${uid}:`, err?.message || err);
      errors.push('fcmTokens');
    }

    // 5b. Per-chat settings documents that reference this participant.
    try {
      const snap = await firestoreDb
        .collection('chat_settings')
        .where('participants', 'array-contains', uid)
        .get();
      for (const doc of snap.docs) {
        await doc.ref.delete();
      }
    } catch (err) {
      console.error(`[AccountDelete] chat_settings cleanup failed for ${uid}:`, err?.message || err);
      errors.push('chat_settings');
    }

    // 6. Profile + private subcollections (wallet/payment PII, blocks, mutes,
    //    linked devices). Recursive delete is required because Firestore does
    //    not cascade deletes automatically.
    try {
      await firestoreDb.recursiveDelete(
        firestoreDb.collection('users').doc(uid)
      );
    } catch (err) {
      console.error(`[AccountDelete] Profile cleanup failed for ${uid}:`, err?.message || err);
      errors.push('users');
    }

    // Financial ledgers (call_billing_records, p2p_transfers, p2p_payments)
    // and abuse reports are retained for accounting/legal obligations.

    if (errors.length > 0) {
      return res.status(500).json({
        error: 'ACCOUNT_DELETE_PARTIAL',
        message:
          'Some account data could not be deleted. Please try again or contact support.',
        failed: errors,
      });
    }

    // 7. Point of no return: remove the sign-in record last.
    try {
      await authService.deleteUser(uid);
    } catch (err) {
      console.error(`[AccountDelete] Auth deletion failed for ${uid}:`, err?.message || err);
      return res.status(500).json({
        error: 'ACCOUNT_DELETE_AUTH_FAILED',
        message:
          'Profile data was erased but the sign-in record could not be removed. Please contact support.',
      });
    }

    console.log(`[AccountDelete] Completed for ${uid}:`, deleted);
    return res.json({ success: true, deleted });
  }
);

const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: '/ws/live-call' });

// Browser guest-room signaling (F7.1)
const roomWss = new WebSocketServer({ server, path: '/ws/room' });
roomWss.on('connection', async (socket, request) => {
  try {
    const url = new URL(request.url || '', 'http://localhost');
    const info = verifyJoinToken(url.searchParams.get('token'));
    if (!info) {
      socket.close(4001, 'invalid');
      return;
    }
    const room = await loadJoinRoom(info.roomId);
    if (!room) {
      socket.send(JSON.stringify({ type: 'expired' }));
      socket.close(4004, 'expired');
      return;
    }
    const role = info.role;
    if (room[role]) {
      socket.send(JSON.stringify({ type: 'full' }));
      socket.close(4009, 'full');
      return;
    }
    room[role] = socket;

    const other = role === 'host' ? room.guest : room.host;
    if (other && other.readyState === WebSocket.OPEN) {
      other.send(
        JSON.stringify({
          type: role === 'guest' ? 'peer-joined' : 'host-ready',
        })
      );
    }

    socket.on('message', (data) => {
      const target = role === 'host' ? room.guest : room.host;
      if (target && target.readyState === WebSocket.OPEN) {
        target.send(data.toString());
      }
    });

    socket.on('close', () => {
      if (room[role] === socket) room[role] = null;
      const target = role === 'host' ? room.guest : room.host;
      if (target && target.readyState === WebSocket.OPEN) {
        target.send(JSON.stringify({ type: 'peer-left' }));
      }
      if (!room.host && !room.guest) joinRooms.delete(info.roomId);
    });
  } catch (err) {
    console.error('[GuestRoom] ws error:', err.message);
    socket.close(1011, 'error');
  }
});

let activeSessionsCount = 0;

// Global Map of Active Call Billing Sessions keyed by callId (or uid if standalone)
// Preserves billing cadence and prevents double-billing across WebSocket reconnects
const callBillingSessions = new Map();

function finalizeBillingSession(key) {
  if (!key) return;
  const session = callBillingSessions.get(key);
  if (session) {
    if (session.disconnectTimer) {
      clearTimeout(session.disconnectTimer);
      session.disconnectTimer = null;
    }
    if (session.meteringInterval) {
      clearInterval(session.meteringInterval);
      session.meteringInterval = null;
    }
    callBillingSessions.delete(key);
    console.log(`[Billing] Session finalized and cleaned up for: ${key}`);
  }
}

const SAFE_LANG_CODE_REGEX = /^[a-zA-Z]{2,4}(-[a-zA-Z0-9]{2,4})?$/;
const SAFE_NAME_REGEX = /^[a-zA-Z0-9\s()/\-]{2,40}$/;
const DEFAULT_LANG_A = { code: 'bn', englishName: 'Bengali', nativeName: 'বাংলা', speechStyleHint: 'spoken conversational Bengali' };
const DEFAULT_LANG_B = { code: 'en', englishName: 'English', nativeName: 'English', speechStyleHint: 'clear conversational English' };

/**
 * Sanitizes language descriptors to prevent prompt injection and prototype pollution.
 */
function sanitizeLanguage(lang, fallback) {
  if (!lang) return fallback;
  if (typeof lang === 'string') {
    const code = lang.trim();
    if (SAFE_LANG_CODE_REGEX.test(code)) {
      return { code, englishName: code, nativeName: code, speechStyleHint: '' };
    }
    return fallback;
  }
  if (typeof lang === 'object' && lang !== null) {
    const code = (typeof lang.code === 'string' && SAFE_LANG_CODE_REGEX.test(lang.code.trim()))
      ? lang.code.trim()
      : fallback.code;
    const rawEnglish = (typeof lang.englishName === 'string') ? lang.englishName.trim() : (typeof lang.name === 'string' ? lang.name.trim() : '');
    const englishName = (rawEnglish.length > 0 && SAFE_NAME_REGEX.test(rawEnglish))
      ? rawEnglish
      : fallback.englishName;
    const rawNative = typeof lang.nativeName === 'string' ? lang.nativeName.replace(/[\r\n\t]/g, ' ').trim() : '';
    const nativeName = (rawNative.length > 0 && rawNative.length <= 40)
      ? rawNative
      : fallback.nativeName;
    const rawHint = typeof lang.speechStyleHint === 'string' ? lang.speechStyleHint.replace(/[\r\n\t]/g, ' ').trim() : '';
    const speechStyleHint = (rawHint.length > 0 && rawHint.length <= 80 && /^[a-zA-Z0-9\s()/\-]+$/.test(rawHint))
      ? rawHint
      : (fallback.speechStyleHint || '');

    return { code, englishName, nativeName, speechStyleHint };
  }
  return fallback;
}

/**
 * Builds the strict, low-latency simultaneous voice interpreter system prompt.
 */
function buildInterpreterPrompt(targetLang) {
  const target = sanitizeLanguage(targetLang, DEFAULT_LANG_B);
  return `
SYSTEM ROLE: REAL-TIME VOICE INTERPRETER.

Translate every utterance you hear into ${target.englishName} (${target.nativeName}) and speak only that translation.
- Never answer questions, never add commentary or meta text.
- Keep names, numbers and the speaker's tone intact.
- If the speech is already in ${target.englishName}, repeat it naturally (passthrough).
- Stay completely silent for background noise or silence.
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
    langA: { ...DEFAULT_LANG_A },
    langB: { ...DEFAULT_LANG_B },
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
  let sessionKey = null;
  let isCallee = false;
  let isCaller = false;
  let isSetupInProgress = false;
  let isSetupComplete = false;
  let isVerifiedParticipant = false;

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

  function cleanup(code) {
    if (isClosing) return;
    isClosing = true;
    clearTimeout(preAuthTimeout);
    clearInterval(heartbeatInterval);
    clearTimeout(sessionLimitTimer);

    if (minuteMeteringInterval) {
      clearInterval(minuteMeteringInterval);
      minuteMeteringInterval = null;
    }

    // Mid-call disconnect handling for call billing sessions:
    // Strictly restrict billing teardown to verified participants whose setup has fully completed
    if (isSetupComplete && isVerifiedParticipant && sessionKey && callBillingSessions.has(sessionKey)) {
      if (code === 1000) {
        // Normal closure (call hang up) by verified participant -> finalize billing
        finalizeBillingSession(sessionKey);
      } else {
        const session = callBillingSessions.get(sessionKey);
        if (session) {
          if (session.clientWs === clientWs) {
            session.clientWs = null;
            if (!session.disconnectTimer) {
              console.log(`[${clientId}] Caller disconnected mid-call for ${sessionKey}. Starting 45s reconnect grace timer.`);
              session.disconnectTimer = setTimeout(() => {
                console.log(`[Billing] Call ${sessionKey} disconnect grace period expired. Cleaning up billing session.`);
                finalizeBillingSession(sessionKey);
              }, 45000);
            }
          } else if (session.calleeWs === clientWs) {
            session.calleeWs = null;
            console.log(`[${clientId}] Callee disconnected for ${sessionKey}. Caller billing session unaffected.`);
          }
        }
      }
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
    cleanup(code);
  });

  clientWs.on('error', (err) => {
    console.error(`[${clientId}] Client WS error:`, err);
    cleanup();
  });

  clientWs.on('message', async (data, isBinary) => {
    try {
      // 1. STRICT AUTHENTICATION & SETUP VERIFICATION GUARD:
      // The socket MUST complete the 'setup' handshake and pass all Firestore participant authorization checks
      // before ANY other messages (audio, language swap, call_ended, hangup) can be processed.
      // Drops pipelined messages sent during in-progress setup to eliminate race conditions.
      if (!isSetupComplete) {
        if (isBinary) {
          console.warn(`[${clientId}] Unauthenticated binary packet rejected before setup completion. Closing connection.`);
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

        if (msg.type !== 'setup' || isSetupInProgress) {
          console.warn(`[${clientId}] Unauthorized message type '${msg.type}' (or pipelined during in-progress setup) before verification. Closing.`);
          if (clientWs.readyState === WebSocket.OPEN) {
            clientWs.send(
              JSON.stringify({
                type: 'error',
                code: 'UNAUTHORIZED',
                message: 'Authentication required. Setup handshake and verification must complete first.',
              })
            );
            clientWs.close(4401, 'Unauthorized');
          }
          return;
        }

        isSetupInProgress = true;

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

        if (APP_CHECK_ENFORCE) {
          const appCheckResult = await verifyAppCheckToken(msg.appCheckToken);
          if (!appCheckResult.ok) {
            console.warn(
              `[${clientId}] App Check verification failed: ${appCheckResult.reason}`,
            );
            clientWs.send(
              JSON.stringify({
                type: 'error',
                code: 'APP_CHECK_REQUIRED',
                message: 'App Check verification failed. Update the app.',
              }),
            );
            clientWs.close(4403, 'APP_CHECK_REQUIRED');
            return;
          }
        }

        // Rate Limiter: Max 2 concurrent sessions per authenticated user
        authenticatedUid = decodedUser.uid;
        clearTimeout(preAuthTimeout);
        const userSessions = activeUserSessions.get(authenticatedUid) || new Set();

        // One live translated call per account: close any earlier verified
        // session so the latest device wins (reconnects are not blocked because
        // pre-handshake sockets are ignored).
        for (const existingWs of [...userSessions]) {
          if (existingWs === clientWs) continue;
          const stillOpen = existingWs.readyState === WebSocket.OPEN;
          if (stillOpen && existingWs._livocalLiveVerified === true) {
            console.warn(
              `[${clientId}] Closing previous live session for ${authenticatedUid} (one active call per account).`,
            );
            try {
              existingWs.send(
                JSON.stringify({
                  type: 'error',
                  code: 'ANOTHER_SESSION_ACTIVE',
                  message:
                    'Another live translation session started on this account.',
                }),
              );
              existingWs.close(4409, 'ANOTHER_SESSION_ACTIVE');
            } catch (closeErr) {
              console.warn(`[${clientId}] Could not close previous session:`, closeErr.message);
            }
            userSessions.delete(existingWs);
          }
        }
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
        // Validate voice against Gemini Live whitelist with upstream compatibility aliases.
        const voiceAliases = { Sularis: 'Autonoe', Perseus: 'Umbriel' };
        const rawVoice = (msg.voice && ALLOWED_VOICES.has(msg.voice))
          ? msg.voice
          : (sessionConfig.voice || DEFAULT_VOICE);
        const validVoice = voiceAliases[rawVoice] || rawVoice;

        sessionConfig = {
          langA: sanitizeLanguage(msg.langA, sessionConfig.langA),
          langB: sanitizeLanguage(msg.langB, sessionConfig.langB),
          voice: validVoice,
          model: DEFAULT_MODEL, // Strictly locked to server DEFAULT_MODEL
          autoDetect: msg.autoDetect !== false,
        };

        // Determine Call Role (Caller vs Callee) via Firestore call record:
        // CRITICAL RACE FIX (B-3): sessionKey is NEVER assigned before Firestore participant verification succeeds!
        const candidateCallId = typeof msg.callId === 'string' && msg.callId.trim().length > 0 ? msg.callId.trim() : null;
        let localIsCallee = false;
        let localIsCaller = true;

        if (candidateCallId) {
          if (!firestoreDb) {
            console.error(`[${clientId}] Cannot verify callId ${candidateCallId} because Firestore is unavailable.`);
            if (clientWs.readyState === WebSocket.OPEN) {
              clientWs.send(
                JSON.stringify({
                  type: 'error',
                  code: 'DATABASE_UNAVAILABLE',
                  message: 'Call verification service unavailable. Please try again.',
                })
              );
              clientWs.close(4503, 'DATABASE_UNAVAILABLE');
            }
            isSetupInProgress = false;
            return;
          }

          try {
            const callDoc = await firestoreDb.collection('calls').doc(candidateCallId).get();
            if (!callDoc.exists) {
              console.warn(`[${clientId}] Security rejection: No active call record found for callId ${candidateCallId} (user: ${authenticatedUid}).`);
              if (clientWs.readyState === WebSocket.OPEN) {
                clientWs.send(
                  JSON.stringify({
                    type: 'error',
                    code: 'INVALID_CALL_ID',
                    message: 'No active call session found for the provided callId.',
                  })
                );
                clientWs.close(4404, 'INVALID_CALL_ID');
              }
              isSetupInProgress = false;
              return;
            }

            const callData = callDoc.data() || {};
            if (callData.callerId && callData.callerId !== authenticatedUid && callData.calleeId === authenticatedUid) {
              // Authenticated user is the CALLEE!
              localIsCallee = true;
              localIsCaller = false;
              console.log(`[${clientId}] User ${authenticatedUid} verified as CALLEE for call ${candidateCallId}. Translation granted free under telecom caller-pays policy.`);
            } else if (callData.callerId === authenticatedUid) {
              // Authenticated user is the CALLER!
              localIsCaller = true;
              localIsCallee = false;
              console.log(`[${clientId}] User ${authenticatedUid} verified as CALLER for call ${candidateCallId}. Relay minute metering active.`);
            } else {
              // Security: User is neither caller nor callee for this callId!
              console.warn(`[${clientId}] Security rejection: User ${authenticatedUid} attempted to access call ${candidateCallId} without being caller (${callData.callerId}) or callee (${callData.calleeId}).`);
              if (clientWs.readyState === WebSocket.OPEN) {
                clientWs.send(
                  JSON.stringify({
                    type: 'error',
                    code: 'UNAUTHORIZED_CALL_SESSION',
                    message: 'You are not an authorized participant in this call session.',
                  })
                );
                clientWs.close(4403, 'UNAUTHORIZED_CALL_SESSION');
              }
              isSetupInProgress = false;
              return;
            }
          } catch (callLookupErr) {
            console.error(`[${clientId}] Failed to verify call session for ${candidateCallId}:`, callLookupErr.message);
            if (clientWs.readyState === WebSocket.OPEN) {
              clientWs.send(
                JSON.stringify({
                  type: 'error',
                  code: 'CALL_VERIFICATION_FAILED',
                  message: 'Could not verify call session authorization.',
                })
              );
              clientWs.close(4500, 'CALL_VERIFICATION_FAILED');
            }
            isSetupInProgress = false;
            return;
          }
        }

        // Authoritative state assignment: ONLY executed AFTER Firestore verification passes!
        activeCallId = candidateCallId;
        sessionKey = candidateCallId || `standalone_${authenticatedUid}`;
        isCallee = localIsCallee;
        isCaller = localIsCaller;
        isVerifiedParticipant = true;
        isSetupComplete = true;
        isSetupInProgress = false;
        clientWs._livocalLiveVerified = true;

        // Reconnect session linking (Role-Guarded):
        // Only the paying caller whose UID matches existingSession.callerUid may claim the billing socket!
        if (callBillingSessions.has(sessionKey)) {
          const existingSession = callBillingSessions.get(sessionKey);
          if (existingSession) {
            if (isCaller && !isCallee && existingSession.callerUid === authenticatedUid) {
              if (existingSession.disconnectTimer) {
                clearTimeout(existingSession.disconnectTimer);
                existingSession.disconnectTimer = null;
                console.log(`[${clientId}] Cancelled disconnect grace timer for reconnected caller on ${sessionKey}`);
              }
              existingSession.clientWs = clientWs;
              billedMinutes = existingSession.billedMinutes;
              console.log(`[${clientId}] Linked caller ${authenticatedUid} to active billing session for ${sessionKey}. Billed so far: ${billedMinutes}m`);
            } else if (isCallee) {
              console.log(`[${clientId}] Callee ${authenticatedUid} joined call session ${sessionKey}. Caller billing socket preserved.`);
              existingSession.calleeWs = clientWs;
            } else {
              console.warn(`[${clientId}] Blocked unauthorized socket overwrite attempt on session ${sessionKey} by user ${authenticatedUid} (expected caller ${existingSession.callerUid}).`);
            }
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
        sessionConfig.langA = sanitizeLanguage(sessionConfig.langB, DEFAULT_LANG_A);
        sessionConfig.langB = sanitizeLanguage(temp, DEFAULT_LANG_B);
        console.log(
          `[${clientId}] Swapped languages: ${sessionConfig.langA.englishName} <-> ${sessionConfig.langB.englishName}`
        );
        // Re-initialize upstream session with updated roles
        await initGeminiSession();
      } else if (msg.type === 'call_ended' || msg.type === 'hangup') {
        if (!isSetupComplete || !isVerifiedParticipant || !sessionKey || (!isCaller && !isCallee)) {
          console.warn(`[${clientId}] Blocked unverified call_ended signal for ${sessionKey || 'unassigned'}`);
          return;
        }
        console.log(`[${clientId}] Call ended signal received from verified participant (${isCaller ? 'caller' : 'callee'}) for ${sessionKey}`);
        finalizeBillingSession(sessionKey);
        cleanup(1000);
        return;
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

        const systemPrompt = buildInterpreterPrompt(sessionConfig.langB);

        const setupPayload = {
          setup: {
            model: sessionConfig.model,
            generationConfig: {
              responseModalities: ['AUDIO'],
              speechConfig: {
                voiceConfig: {
                  prebuiltVoiceConfig: {
                    voiceName: sessionConfig.voice,
                  },
                },
              },
              // Required by gemini-3.5-live-translate-preview. Each session
              // carries one speaker, so the target is always the peer's
              // language: the translated audio is forwarded to that peer.
              translationConfig: {
                targetLanguageCode: sessionConfig.langB.code,
                echoTargetLanguage: true,
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

            // CallId-keyed Session Metering:
            // Check if this call session already has an active billing session in callBillingSessions
            const existingBillingSession = sessionKey ? callBillingSessions.get(sessionKey) : null;

            if (!isCallee && firestoreDb && authenticatedUid) {
              if (existingBillingSession && existingBillingSession.billedMinutes > 0) {
                // MID-CALL RECONNECT PATH:
                // User was ALREADY billed upfront minute 1 (or more) and metering cadence is active.
                // DO NOT deduct upfront minute 1 again!
                if (existingBillingSession.callerUid === authenticatedUid) {
                  existingBillingSession.clientWs = clientWs;
                  if (existingBillingSession.disconnectTimer) {
                    clearTimeout(existingBillingSession.disconnectTimer);
                    existingBillingSession.disconnectTimer = null;
                  }
                  billedMinutes = existingBillingSession.billedMinutes;
                  console.log(`[${clientId}] [SaaS Relay Metering] Mid-call reconnect confirmed for caller ${authenticatedUid} on ${sessionKey}. Preserving existing billed count (${existingBillingSession.billedMinutes}m) with 0 extra upfront charge.`);

                  if (clientWs.readyState === WebSocket.OPEN) {
                    clientWs.send(
                      JSON.stringify({
                        type: 'billing_update',
                        billedMinutes: existingBillingSession.billedMinutes,
                        remainingMinutes: existingBillingSession.remainingMinutes,
                        lowBalanceWarning: existingBillingSession.remainingMinutes <= 2,
                        role: 'caller',
                        reconnected: true,
                      })
                    );
                  }
                } else {
                  console.warn(`[${clientId}] [SaaS Relay Metering] Blocked unauthorized mid-call reconnect for ${sessionKey} by ${authenticatedUid} (expected caller ${existingBillingSession.callerUid}).`);
                }
              } else {
                // INITIAL CALL CONNECTION PATH:
                // Immediately deduct minute 1 upfront for CALLER only (Standard Telecom model: 0s-59s billed on connect)
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

                    // Initialize persistent billing session
                    const persistentSession = {
                      callId: activeCallId,
                      sessionKey,
                      callerUid: authenticatedUid,
                      clientWs,
                      calleeWs: existingBillingSession?.calleeWs || null,
                      billedMinutes: 1,
                      remainingMinutes: deductionResult.remainingMinutes,
                      isCallee: false,
                      createdAt: Date.now(),
                      disconnectTimer: null,
                      meteringInterval: null,
                    };

                    // Server-Side 60s Minute Metering Interval anchored to callId
                    persistentSession.meteringInterval = setInterval(async () => {
                      try {
                        const walletDocRef = firestoreDb.collection('users').doc(authenticatedUid).collection('wallet').doc('current');
                        const result = await firestoreDb.runTransaction(async (t) => {
                          const snap = await t.get(walletDocRef);
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

                          t.update(walletDocRef, {
                            trialMinutes: newTrial,
                            balanceMinutes: newBalance,
                            totalMinutesUsed: newTotalUsed,
                            updatedAt: now.toISOString(),
                          });

                          const billingRef = firestoreDb.collection('call_billing_records').doc();
                          const geminiCostUsd = 0.035;
                          const retailBdt = 20.0;
                          const usdToBdt = 120.0;
                          const costBdt = geminiCostUsd * usdToBdt;
                          const netProfitBdt = retailBdt - costBdt;

                          t.set(billingRef, {
                            recordId: billingRef.id,
                            callId: persistentSession.callId || `ws_live_${authenticatedUid.substring(0, 6)}_${Date.now()}`,
                            callerId: authenticatedUid,
                            isTranslatedCall: true,
                            durationSeconds: 60,
                            minuteIndex: persistentSession.billedMinutes + 1,
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

                        persistentSession.billedMinutes += 1;
                        persistentSession.remainingMinutes = result.remainingMinutes;
                        persistentSession.consecutiveFailures = 0;
                        console.log(`[${persistentSession.sessionKey}] [SaaS Relay Metering] Deducted 1 min from caller ${authenticatedUid} (minute ${persistentSession.billedMinutes}). Remaining: ${result.remainingMinutes}`);

                        if (persistentSession.clientWs && persistentSession.clientWs.readyState === WebSocket.OPEN) {
                          persistentSession.clientWs.send(
                            JSON.stringify({
                              type: 'billing_update',
                              billedMinutes: persistentSession.billedMinutes,
                              remainingMinutes: result.remainingMinutes,
                              lowBalanceWarning: result.remainingMinutes <= 2,
                              role: 'caller',
                            })
                          );
                        }

                        if (result.exhausted) {
                          console.warn(`[${persistentSession.sessionKey}] Minute quota exhausted for caller ${authenticatedUid}. Terminating session.`);
                          if (persistentSession.clientWs && persistentSession.clientWs.readyState === WebSocket.OPEN) {
                            persistentSession.clientWs.send(
                              JSON.stringify({
                                type: 'error',
                                code: 'MINUTES_EXHAUSTED',
                                message: 'Translation minutes exhausted. Session ended.',
                              })
                            );
                            persistentSession.clientWs.close(4402, 'MINUTES_EXHAUSTED');
                          }
                          if (persistentSession.calleeWs && persistentSession.calleeWs.readyState === WebSocket.OPEN) {
                            persistentSession.calleeWs.send(
                              JSON.stringify({
                                type: 'error',
                                code: 'MINUTES_EXHAUSTED',
                                message: 'Caller translation minutes exhausted. Session ended.',
                              })
                            );
                            persistentSession.calleeWs.close(4402, 'MINUTES_EXHAUSTED');
                          }
                          finalizeBillingSession(persistentSession.sessionKey);
                        }
                      } catch (periodicErr) {
                        console.error(`[${persistentSession.sessionKey}] Periodic minute deduction error (strict 1-strike fail-closed):`, periodicErr.message);
                        if (persistentSession.clientWs && persistentSession.clientWs.readyState === WebSocket.OPEN) {
                          persistentSession.clientWs.send(
                            JSON.stringify({
                              type: 'error',
                              code: 'METERING_ERROR',
                              message: 'Billing verification failed. Session ended.',
                            })
                          );
                          persistentSession.clientWs.close(4402, 'METERING_ERROR');
                        }
                        if (persistentSession.calleeWs && persistentSession.calleeWs.readyState === WebSocket.OPEN) {
                          persistentSession.calleeWs.send(
                            JSON.stringify({
                              type: 'error',
                              code: 'METERING_ERROR',
                              message: 'Caller billing verification failed. Session ended.',
                            })
                          );
                          persistentSession.calleeWs.close(4402, 'METERING_ERROR');
                        }
                        finalizeBillingSession(persistentSession.sessionKey);
                      }
                    }, 60000);

                    callBillingSessions.set(sessionKey, persistentSession);

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
                      if (persistentSession.calleeWs && persistentSession.calleeWs.readyState === WebSocket.OPEN) {
                        persistentSession.calleeWs.send(
                          JSON.stringify({
                            type: 'error',
                            code: 'MINUTES_EXHAUSTED',
                            message: 'Caller translation minutes exhausted. Session ended.',
                          })
                        );
                        persistentSession.calleeWs.close(4402, 'MINUTES_EXHAUSTED');
                      }
                      finalizeBillingSession(sessionKey);
                      cleanup();
                    }
                  } catch (initialMeterErr) {
                    console.error(`[${clientId}] Initial minute deduction error (fail-closed):`, initialMeterErr.message);
                    if (clientWs.readyState === WebSocket.OPEN) {
                      clientWs.send(
                        JSON.stringify({
                          type: 'error',
                          code: 'METERING_ERROR',
                          message: 'Unable to verify minute balance. Session ended.',
                        })
                      );
                      clientWs.close(4402, 'METERING_ERROR');
                    }
                    if (persistentSession.calleeWs && persistentSession.calleeWs.readyState === WebSocket.OPEN) {
                      persistentSession.calleeWs.send(
                        JSON.stringify({
                          type: 'error',
                          code: 'METERING_ERROR',
                          message: 'Caller billing verification failed. Session ended.',
                        })
                      );
                      persistentSession.calleeWs.close(4402, 'METERING_ERROR');
                    }
                    finalizeBillingSession(sessionKey);
                    cleanup();
                    return;
                  }
                })();
              }
            } else if (isCallee && existingBillingSession) {
              existingBillingSession.calleeWs = clientWs;
              console.log(`[${clientId}] [SaaS Relay Metering] Callee ${authenticatedUid} linked to active call session ${sessionKey}.`);
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

/**
 * Automatically checks and runs one-time User Payment PII Isolation Migration on server boot.
 * Scans all /users documents, moves any legacy financial addresses to
 * users/{userId}/wallet/payment_settings, and scrubs them from the parent user doc.
 * Tracks completion state in _system_migrations/payment_pii_isolation.
 */
async function autoRunPaymentPiiMigrationOnBoot() {
  if (!firestoreDb) return;

  const PAYMENT_FIELDS = [
    'binancePayId',
    'cryptoUsdtTrc20',
    'cryptoUsdtBep20',
    'bkashNumber',
    'nagadNumber',
  ];

  try {
    const migrationRef = firestoreDb.collection('_system_migrations').doc('payment_pii_isolation');
    const doc = await migrationRef.get();
    if (doc.exists && doc.data() && doc.data().completed) {
      console.log(`[Migration] User Payment PII isolation already completed on ${doc.data().completedAt}`);
      return;
    }

    console.log('[Migration] Checking and running one-time User Payment PII Isolation Migration on boot...');
    const usersSnapshot = await firestoreDb.collection('users').get();
    let scannedUsers = 0;
    let migratedUsers = 0;
    let scrubbedUsers = 0;

    for (const userDoc of usersSnapshot.docs) {
      scannedUsers++;
      const userData = userDoc.data();
      const paymentUpdates = {};
      const deleteUpdates = {};
      let hasLegacyPayment = false;

      for (const field of PAYMENT_FIELDS) {
        if (field in userData) {
          hasLegacyPayment = true;
          const val = userData[field];
          if (typeof val === 'string' && val.trim().length > 0) {
            paymentUpdates[field] = val.trim();
          }
          deleteUpdates[field] = FieldValue.delete();
        }
      }

      if (hasLegacyPayment) {
        const batch = firestoreDb.batch();
        if (Object.keys(paymentUpdates).length > 0) {
          const settingsRef = userDoc.ref.collection('wallet').doc('payment_settings');
          paymentUpdates.updatedAt = new Date().toISOString();
          paymentUpdates.migratedFromUserDoc = true;
          batch.set(settingsRef, paymentUpdates, { merge: true });
          migratedUsers++;
        }
        batch.update(userDoc.ref, deleteUpdates);
        await batch.commit();
        scrubbedUsers++;
      }
    }

    await migrationRef.set({
      completed: true,
      completedAt: new Date().toISOString(),
      scannedUsers,
      migratedUsers,
      scrubbedUsers,
      triggeredBy: 'server_boot',
    }, { merge: true });

    console.log(`[Migration] Boot migration complete. Scanned: ${scannedUsers}, Migrated: ${migratedUsers}, Scrubbed: ${scrubbedUsers}`);
  } catch (err) {
    console.warn('[Migration] Note: Payment PII migration boot check skipped or error:', err.message);
  }
}

server.listen(PORT, '0.0.0.0', () => {
  console.log('===============================================================');
  console.log(`🚀 Livocal Gemini Live Relay Gateway running on port ${PORT}`);
  console.log(`🌐 HTTP Health Check: http://0.0.0.0:${PORT}/health`);
  console.log(`⚡ WebSocket URL: ws://0.0.0.0:${PORT}/ws/live-call`);
  console.log(`🔑 Gemini API Key configured: ${Boolean(GEMINI_API_KEY) ? 'YES ✅' : 'NO ⚠️ (Set in .env)'}`);
  console.log(`🎙️ Default Voice Profile: ${DEFAULT_VOICE}`);
  console.log(`🧠 Default Model: ${DEFAULT_MODEL}`);
  console.log('===============================================================');

  // Trigger one-time legacy user payment PII scrub and isolation
  autoRunPaymentPiiMigrationOnBoot();

  // Auto-enforce and verify live Firestore Rules & TTL deployment on boot
  if (serviceAccount) {
    import('./scripts/deploy_firestore_config.cjs')
      .then(({ deployFirestoreConfig }) => {
        deployFirestoreConfig().catch(err => {
          console.warn('[Server Boot] Auto-deploy rules notice:', err.message);
        });
      })
      .catch(err => {
        console.warn('[Server Boot] Could not load deploy_firestore_config:', err.message);
      });
  }
});
