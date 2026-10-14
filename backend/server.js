import http from 'http';
import express from 'express';
import { WebSocketServer, WebSocket } from 'ws';
import dotenv from 'dotenv';
import cors from 'cors';

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { initializeApp, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let firebaseApp = null;
let messagingService = null;
let firestoreDb = null;
let authService = null;

let serviceAccount = null;

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } catch (e) {
    console.error('[Firebase Admin] Error parsing FIREBASE_SERVICE_ACCOUNT env:', e.message);
  }
} else {
  console.warn('[Firebase Admin] Warning: FIREBASE_SERVICE_ACCOUNT environment variable is not set. Disk key fallbacks are disabled for production security.');
}

// Whitelist of valid Gemini 3.5 Live Translation voices
const ALLOWED_VOICES = new Set(['Puck', 'Charon', 'Kore', 'Fenrir', 'Aoede']);

// Concurrent WebSocket session tracking per user UID (Rate Limiting)
const activeUserSessions = new Map();

if (serviceAccount) {
  try {
    firebaseApp = initializeApp({
      credential: cert(serviceAccount),
      projectId: serviceAccount.project_id || 'livocal24',
    });
    messagingService = getMessaging(firebaseApp);
    firestoreDb = getFirestore(firebaseApp);
    authService = getAuth(firebaseApp);
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
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate limit: 300 requests per 15 min per IP on API endpoints
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests from this IP, please try again later.' },
});
app.use('/api/', apiLimiter);

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
    service: 'Livocal Gemini Live Relay Gateway',
    version: '1.0.0',
    description: 'Zero-Trust Secure Audio Relay for Gemini Multimodal Live API',
    endpoints: {
      health: '/health',
      websocket: '/ws/live-call',
      callNotify: '/api/call/notify-incoming',
    },
    configured: Boolean(GEMINI_API_KEY),
    firebaseAdmin: Boolean(firebaseApp),
  });
});

// Send Full-Screen Incoming Call Wakeup Push via FCM
// Anti-Phishing: Enforces callerId = req.user.uid and pulls verified name/phone from Firestore
app.post('/api/call/notify-incoming', authenticateRequest, async (req, res) => {
  if (!firebaseApp || !messagingService) {
    return res.status(503).json({ error: 'Firebase Admin not initialized on server' });
  }

  const { targetUserId, callId } = req.body;
  if (!targetUserId || !callId) {
    return res.status(400).json({ error: 'targetUserId and callId are required fields' });
  }

  const callerUid = req.user.uid;
  if (targetUserId === callerUid) {
    return res.status(400).json({ error: 'Cannot send call notification to oneself' });
  }

  try {
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
    res.status(500).json({ error: err.message });
  }
});

// Send Chat Message Push via FCM
// Anti-Impersonation: Enforces authorId = req.user.uid and pulls verified name/avatar from Firestore
app.post('/api/notify/chat-message', authenticateRequest, async (req, res) => {
  if (!firebaseApp || !messagingService) {
    return res.status(503).json({ error: 'Firebase Admin not initialized on server' });
  }

  const { receiverId, messageContent, messageId, authorId } = req.body;
  if (!receiverId || !messageId) {
    return res.status(400).json({ error: 'receiverId and messageId are required fields' });
  }

  const callerUid = req.user.uid;
  if (authorId && authorId !== callerUid) {
    return res.status(403).json({ error: 'Forbidden: Cannot send push notifications impersonating another user' });
  }

  try {
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
    res.status(500).json({ error: err.message });
  }
});

// Secure ICE Servers endpoint (Provides STUN / TURN servers)
app.get('/api/webrtc/ice-servers', authenticateRequest, (req, res) => {
  const iceServers = [
    { urls: 'stun:stun.l.google.com:19302' },
    { urls: 'stun:stun1.l.google.com:19302' },
    { urls: 'stun:stun2.l.google.com:19302' },
  ];
  if (process.env.TURN_URL && process.env.TURN_USERNAME && process.env.TURN_CREDENTIAL) {
    iceServers.push({
      urls: process.env.TURN_URL,
      username: process.env.TURN_USERNAME,
      credential: process.env.TURN_CREDENTIAL,
    });
  }
  res.json({ iceServers });
});

/**
 * POST /api/contacts/match
 * Securely matches user's local phonebook against registered users in Firestore.
 * Prevents client-side scraping of /users collection while enabling instant contact discovery.
 */
app.post('/api/contacts/match', apiLimiter, authenticateRequest, async (req, res) => {
  try {
    const { phoneNumbers } = req.body;
    if (!Array.isArray(phoneNumbers) || phoneNumbers.length === 0) {
      return res.status(400).json({ error: 'phoneNumbers must be a non-empty array' });
    }

    if (!firestoreDb) {
      return res.status(503).json({ error: 'Firestore database service is currently unavailable' });
    }

    const sanitizedNumbers = phoneNumbers
      .slice(0, 500)
      .map((p) => String(p).trim().replace(/[\s\-\(\)\+]/g, ''))
      .filter((n) => n.length >= 6);

    const lookupSet = new Set(sanitizedNumbers);
    const snap = await firestoreDb.collection('users').get();
    const matches = [];

    snap.forEach((doc) => {
      const data = doc.data();
      const phone = data.phone;
      if (!phone) return;

      const raw = (phone.rawNumber || '').replace(/[\s\-\(\)\+]/g, '');
      const num = (phone.number || '').replace(/[\s\-\(\)\+]/g, '');
      const code = (phone.code || '').replace(/[\s\-\(\)\+]/g, '');
      const codeNum = code + num;

      if (lookupSet.has(raw) || lookupSet.has(num) || lookupSet.has(codeNum)) {
        matches.push({
          id: data.id || doc.id,
          name: data.name || '',
          avatarUrl: data.avatarUrl || '',
          phone: data.phone,
          activityStatus: data.activityStatus || 'offline',
        });
      }
    });

    res.json({ matches });
  } catch (err) {
    console.error('[Contacts] Error matching contacts:', err);
    res.status(500).json({ error: 'Internal error matching contacts' });
  }
});

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
  activeSessionsCount++;
  const clientId = `client_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
  console.log(`[${clientId}] Client connected from ${req.socket.remoteAddress}`);

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
    clearInterval(heartbeatInterval);
    clearTimeout(sessionLimitTimer);

    if (authenticatedUid && activeUserSessions.has(authenticatedUid)) {
      const userSessions = activeUserSessions.get(authenticatedUid);
      userSessions.delete(clientWs);
      if (userSessions.size === 0) {
        activeUserSessions.delete(authenticatedUid);
      }
    }

    if (geminiWs && geminiWs.readyState === WebSocket.OPEN) {
      console.log(`[${clientId}] Closing upstream Gemini session`);
      geminiWs.close(1000, 'Client closed');
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
      // 1. Binary Audio Chunks (Raw 16kHz PCM16 Mono from phone microphone)
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

      // 2. JSON Control Messages
      const text = data.toString('utf8');
      const msg = JSON.parse(text);

      if (msg.type === 'setup') {
        console.log(`[${clientId}] Received setup handshake:`, msg);

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

        await initGeminiSession();
      } else if (msg.type === 'audio_base64') {
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
            clientWs.send(
              JSON.stringify({
                type: 'ready',
                state: 'ready',
                voice: sessionConfig.voice,
                languages: `${sessionConfig.langA.englishName} ⇄ ${sessionConfig.langB.englishName}`,
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
          clientWs.send(
            JSON.stringify({
              type: 'error',
              code: 'GEMINI_UPSTREAM_ERROR',
              message: String(err?.message || err),
            })
          );
        }
      });

      geminiWs.on('close', (code, reason) => {
        console.log(`[${clientId}] Gemini upstream closed (${code}: ${reason || 'normal'})`);
        isGeminiReady = false;
        if (clientWs.readyState === WebSocket.OPEN) {
          clientWs.send(
            JSON.stringify({
              type: 'status',
              state: 'disconnected',
              message: 'Gemini Live session disconnected',
            })
          );
        }
      });
    } catch (err) {
      console.error(`[${clientId}] Failed to connect to Gemini:`, err);
      clientWs.send(
        JSON.stringify({
          type: 'error',
          code: 'CONNECTION_FAILED',
          message: String(err),
        })
      );
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
