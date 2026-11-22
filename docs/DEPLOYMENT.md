# Livocal Deployment Checklist

This is the minimum sequence to take the current branch live. It covers the
relay, Firebase rules and the app build. Do not skip the `/health` checks.

## 1. Relay (Render)

Service: `livocal-relay` (root directory `backend`).

Set these Environment variables (Render Dashboard → Environment):

| Key | Required | Notes |
| --- | --- | --- |
| `GEMINI_API_KEY` | **yes** | Google AI Studio key. Never commit it. |
| `GEMINI_LIVE_MODEL` | yes | Default `models/gemini-3.5-live-translate-preview`. Set to a model your key can access. |
| `GEMINI_TEXT_MODEL` | yes | Default `gemini-2.5-flash` for chat translation. |
| `FIREBASE_SERVICE_ACCOUNT` | **yes** | Service-account JSON as a single-line string. |
| `FIREBASE_STORAGE_BUCKET` | yes | `livocal24.firebasestorage.app` (or your project's bucket). |
| `ADMIN_SECRET` | **yes** | 16+ characters; server refuses to start without it. |
| `TURN_URL` | recommended | Comma-separated TURN URLs. |
| `TURN_SECRET` | recommended | Coturn static-auth secret for ephemeral credentials. |
| `SUPER_ADMIN_UID` | optional | Firebase UID allowed to use admin APIs. |

After redeploy, verify:

```bash
curl https://livocal-relay.onrender.com/health
```

Expected:

```json
{
  "status": "ok",
  "hasApiKey": true,
  "hasTurn": true,
  "liveModel": "models/gemini-3.5-live-translate-preview",
  "textModel": "gemini-2.5-flash"
}
```

- `hasApiKey:false` → live translation returns `4403 MISSING_API_KEY`.
- `hasTurn:false` → calls may fail on symmetric NAT / mobile data.
- `uptime` just after deploy is small; the app now warms the relay at startup.

## 2. Firebase rules

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage:rules
```

Deploying rules is required for:

- transcript 24-hour TTL (`firestore.indexes.json`),
- immutable message identity/content and receipt-only updates,
- account-deletion-compatible rules.

## 3. App build

Normal build:

```bash
flutter build apk --release \
  --dart-define=RELAY_URL=https://livocal-relay.onrender.com
```

With App Check (after registering Play Integrity / DeviceCheck in the Firebase
Console and enabling enforcement):

```bash
flutter build apk --release \
  --dart-define=RELAY_URL=https://livocal-relay.onrender.com \
  --dart-define=ENABLE_APP_CHECK=true
```

Debug/QA builds leave App Check off by default.

## 4. Two-device smoke test

Use two Android phones (or one phone + emulator) with two different accounts:

1. Same language (bn↔bn): call connects, audio is direct P2P, no minutes used.
2. Different languages (bn↔en): translated audio is heard on both sides;
   wallet shows 1 minute deducted for the caller.
3. Hang up: call history entry appears, transcript entries are gone from
   Firestore, billing summary is written.
4. Kill the app on the callee, call again: incoming call screen appears
   (Android). On iOS this still depends on PushKit work not yet done.
5. Airplane mode mid-call: app shows reconnecting/poor-network state and
   recovers or ends cleanly.
6. Account deletion: Settings → Account → Delete my account. Confirm that
   `users/{uid}` (including `wallet`), `chats/{uid}`, calls, statuses and
   storage objects are gone and the Auth user is removed.

## 5. Known platform limits

- iOS incoming calls while the app is terminated need PushKit VoIP push; the
  current FCM + CallKit path is reliable only while the app is alive/background.
- Render free instances cold-start; the app warms `/health` at launch and the
  live WS timeout is 15 seconds, but a paid instance is the durable fix.
- Public TURN fallback was removed; configure `TURN_URL`/`TURN_SECRET`.
