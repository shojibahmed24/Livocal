import http from 'http';
import express from 'express';
import { WebSocketServer, WebSocket } from 'ws';
import dotenv from 'dotenv';
import cors from 'cors';

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { initializeApp, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { getFirestore } from 'firebase-admin/firestore';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let firebaseApp = null;
let messagingService = null;
let firestoreDb = null;

let serviceAccount = null;
const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } catch (e) {
    console.error('[Firebase Admin] Error parsing FIREBASE_SERVICE_ACCOUNT env:', e.message);
  }
} else if (fs.existsSync(serviceAccountPath)) {
  try {
    serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
  } catch (e) {
    console.error('[Firebase Admin] Error reading serviceAccountKey.json:', e.message);
  }
}

if (serviceAccount) {
  try {
    firebaseApp = initializeApp({
      credential: cert(serviceAccount),
      projectId: serviceAccount.project_id || 'livocal24',
    });
    messagingService = getMessaging(firebaseApp);
    firestoreDb = getFirestore(firebaseApp);
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

const RELAY_SECRET = process.env.RELAY_API_SECRET?.trim() || 'livocal_relay_secure_v1_2026';

const app = express();
app.use(cors());
app.use(express.json());

function authenticateRequest(req, res, next) {
  if (RELAY_SECRET) {
    const provided =
      req.headers['x-api-secret'] ||
      req.headers['authorization']?.replace('Bearer ', '');
    if (provided !== RELAY_SECRET) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
  }
  next();
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
app.post('/api/call/notify-incoming', authenticateRequest, async (req, res) => {
  if (!firebaseApp || !messagingService) {
    return res.status(503).json({ error: 'Firebase Admin not initialized on server' });
  }

  const { targetToken, targetUserId, callId, callerName, callerNumber } = req.body;
  
  try {
    let token = targetToken;
    if (!token && targetUserId && firestoreDb) {
      const tokenDoc = await firestoreDb.collection('fcmTokens').doc(targetUserId).get();
      if (tokenDoc.exists) {
        token = tokenDoc.data().token;
      }
    }

    if (!token) {
      return res.status(404).json({ error: 'No FCM token found for target user' });
    }

    // High Priority Data Message for waking up Android / CallKit
    const message = {
      token,
      data: {
        type: 'INCOMING_CALL',
        callId: String(callId || ''),
        callerName: String(callerName || 'Caller'),
        callerNumber: String(callerNumber || ''),
        timestamp: String(Date.now()),
      },
      android: {
        priority: 'high',
      },
    };

    const response = await messagingService.send(message);
    res.json({ success: true, messageId: response });
  } catch (err) {
    console.error('FCM Send Error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Send Chat Message Push via FCM
app.post('/api/notify/chat-message', authenticateRequest, async (req, res) => {
  if (!firebaseApp || !messagingService) {
    return res.status(503).json({ error: 'Firebase Admin not initialized on server' });
  }

  const { token, receiverId, messageContent, authorName, authorId, authorAvatar, messageId } = req.body;
  try {
    let targetToken = token;
    if (!targetToken && receiverId && firestoreDb) {
      const doc = await firestoreDb.collection('fcmTokens').doc(receiverId).get();
      if (doc.exists) {
        targetToken = doc.data().token;
      }
    }

    if (!targetToken) {
      return res.status(404).json({ error: 'FCM token not found' });
    }

    const payload = {
      token: targetToken,
      notification: {
        title: authorName || 'New Message',
        body: messageContent || 'Sent a message',
        imageUrl: authorAvatar || undefined,
      },
      data: {
        type: 'CHAT_MESSAGE',
        messageId: String(messageId || ''),
        authorName: String(authorName || ''),
        authorId: String(authorId || ''),
        authorAvatar: String(authorAvatar || ''),
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

  function cleanup() {
    if (isClosing) return;
    isClosing = true;
    clearInterval(heartbeatInterval);

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

        if (RELAY_SECRET) {
          const clientSecret =
            req.headers['x-api-secret'] ||
            req.headers['authorization']?.replace('Bearer ', '') ||
            new URL(req.url, 'http://localhost').searchParams.get('secret') ||
            msg.secret;

          if (clientSecret !== RELAY_SECRET) {
            console.warn(`[${clientId}] Unauthorized WebSocket client. Closing.`);
            clientWs.send(
              JSON.stringify({
                type: 'error',
                code: 'UNAUTHORIZED',
                message: 'Invalid or missing relay secret.',
              })
            );
            clientWs.close(4401, 'Unauthorized');
            return;
          }
        }

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

        sessionConfig = {
          langA: msg.langA || sessionConfig.langA,
          langB: msg.langB || sessionConfig.langB,
          voice: msg.voice || sessionConfig.voice,
          model: msg.model || sessionConfig.model,
          autoDetect: msg.autoDetect !== false,
        };

        await initGeminiSession();
      } else if (msg.type === 'audio_base64') {
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
      } catch (_) {}
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
