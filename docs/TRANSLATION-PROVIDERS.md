# Translation providers (voice-to-voice)

The relay can run on two engines. Switching is an environment change, not a
code change.

```
TRANSLATION_PROVIDER=azure   # default
TRANSLATION_PROVIDER=gemini  # the previous Gemini Live path
```

Both implementations live in the repo at the same time:

```
backend/services/translation/
  index.js      provider switch + status
  languages.js  app language code -> Azure locale + neural voice
  azure.js      Azure Speech Translation session (voice in -> voice out)
backend/server.js  /ws/live-call  (protocol identical for both providers)
```

## Protocols the app sees (unchanged)

| Message | Meaning |
|---|---|
| `ready` | upstream is live, billing metering started |
| `audio_out` | base64 PCM16 of the translated voice |
| `transcript` | translated text for the subtitle |
| `interrupted` | barge-in |
| `error` | provider error (app falls back to direct voice) |

## Azure specifics

- One `TranslationRecognizer` per speaker direction (Azure allows a single
  target language per recogniser).
- **Voice-to-voice** requires `voiceName`; without it Azure returns text only.
  `services/translation/azure.js` always sets it from `AZURE_LANGUAGES`.
- Output format: raw 24 kHz PCM16 mono (the format the app already plays).
- Input: 16 kHz PCM16 mono pushed into `AudioInputStream`.
- Languages Azure cannot pair (the app has 73, Azure fewer) return
  `LANG_UNSUPPORTED`; the app keeps the call as direct voice.

## Environment

```
TRANSLATION_PROVIDER=azure
AZURE_SPEECH_KEY=...
AZURE_SPEECH_REGION=eastus
# optional: AZURE_SPEECH_ENDPOINT=https://eastus.api.cognitive.microsoft.com/
```

## Proof script

```bash
cd backend
node scripts/test_azure_speech.cjs --from bn --to en
```

It synthesises a Bengali sentence, translates it to English, writes
`tmp/azure-translated-en.wav`, and prints the audio byte count. PASS means the
voice actually came back.

## Going back to Gemini

1. `TRANSLATION_PROVIDER=gemini` in Render → Save (the service restarts).
2. `GEMINI_API_KEY` must be present.
3. Nothing else changes; `azure.js` stays for later.
