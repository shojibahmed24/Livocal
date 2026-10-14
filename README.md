# Livocal 🎙️🌐

> **Real-Time AI Voice Translation Calling & End-to-End Encrypted Messaging**  
> Built with Flutter, WebRTC, Firebase, Node.js Gateway, and the Gemini Multimodal Live API.

---

## 🌟 Overview

**Livocal** is an AI-powered voice calling and real-time messaging application designed to break down language barriers across the globe. By combining WebRTC peer-to-peer VoIP with Google's low-latency Gemini Live API, Livocal translates conversational voice between 70+ languages in real time while preserving natural conversation flow.

### Key Highlights
- **🗣️ Real-Time P2P Voice Translation:** Speak in Bengali, English, Spanish, Arabic, Hindi, Japanese, or 70+ other languages — the recipient hears fluent, low-latency translated audio in their own language.
- **⚡ WebRTC Full-Duplex Audio:** Hardware Acoustic Echo Cancellation (AEC), noise suppression, and automatic gain control with 24kHz PCM peer-to-peer audio streaming over WebRTC DataChannel.
- **💬 Real-Time Messaging:** WhatsApp-style instant messaging with message receipts (pending, sent, delivered, read), voice notes, media attachments, and message actions (Copy, Delete for me, Delete for everyone).
- **🔔 Background Wakeup & CallKit:** Native full-screen incoming call UI on Android and iOS via `flutter_callkit_incoming` and high-priority FCM push notifications.
- **👤 Profile & Appearance:** Profile personalization (custom avatar, display name, About status presets) with dynamic Light, Dark, and System Default themes.

---

## 🏗️ Architecture

```
                                  ┌───────────────────────────────┐
                                  │      Firebase Services        │
                                  │  • Auth (Phone OTP)           │
                                  │  • Firestore (Signaling & DB) │
                                  │  • FCM (Wakeup & Calls)       │
                                  │  • Storage (Media Attachments)│
                                  └───────────────┬───────────────┘
                                                  │
                 ┌────────────────────────────────┴──────────────────────────────┐
                 ▼                                                               ▼
        ┌──────────────────┐                                            ┌──────────────────┐
        │  Livocal Caller  │ ◄══════ WebRTC Audio & DataChannel ══════► │  Livocal Callee  │
        │  (Flutter App)   │                                            │  (Flutter App)   │
        └────────┬─────────┘                                            └────────┬─────────┘
                 │                                                               │
                 │ 16kHz PCM Mic Stream                                          │
                 ▼                                                               ▼
        ┌──────────────────────────────────────────────────────────────────────────────────┐
        │                        Livocal Live Relay Gateway (Node.js)                      │
        │                  Proxy & Authentication to Gemini Live API                      │
        └────────────────────────────────────────┬─────────────────────────────────────────┘
                                                 │ WebSocket (Audio in / Translated PCM out)
                                                 ▼
                                ┌──────────────────────────────────┐
                                │   Google Gemini Live API         │
                                │   (Live Audio Interpretation)    │
                                └──────────────────────────────────┘
```

---

## 🚀 Getting Started

### Prerequisites
1. **Flutter SDK:** 3.19.0 or higher (`flutter doctor`)
2. **Dart SDK:** 3.3.0 or higher
3. **Node.js:** v18+ (for the relay backend)
4. **Firebase Account:** Blaze / Pay-As-You-Go plan recommended for FCM and Cloud Storage
5. **Google AI Studio Key:** Gemini API Key

---

### 1. Flutter Client Setup

```bash
# Clone the repository
git clone https://github.com/your-org/livocal.git
cd livocal

# Install dependencies
flutter pub get

# Generate local database models
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

---

### 2. Backend Relay Gateway Setup

The backend serves as a zero-trust proxy for Gemini Live WebSockets and high-priority FCM call wakeup messages:

```bash
cd backend
npm install

# Configure environment variables (.env)
cp .env.example .env
```

**Example `.env` configuration:**
```env
PORT=8080
GEMINI_API_KEY=AIzaSy...
GEMINI_LIVE_MODEL=models/gemini-3.5-live-translate-preview
DEFAULT_VOICE=Aoede
RELAY_API_SECRET=your_super_secret_key_here
FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}
```

Start the backend:
```bash
npm start
```

---

### 3. Firebase Security Rules Deployment

Deploy the hardened Firestore and Storage security rules:

```bash
# Deploy Firestore rules (including WebRTC ICE candidate subcollections)
firebase deploy --only firestore:rules

# Deploy Storage rules (with avatar ownership & file size limits)
firebase deploy --only storage:rules
```

---

## 🔒 Security Best Practices

1. **WebRTC Signaling:** ICE candidate exchanges (`callerCandidates`, `calleeCandidates`) and call sessions are restricted to authenticated participants only.
2. **Live Transcripts:** Real-time call transcripts are isolated strictly to the active caller and callee.
3. **Attachments:** Cloud Storage attachments enforce authenticated access and a 50MB file size ceiling.
4. **Relay Gateway:** The Node.js backend can enforce `RELAY_API_SECRET` to prevent unauthorized consumption of Gemini Live API quotas.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
