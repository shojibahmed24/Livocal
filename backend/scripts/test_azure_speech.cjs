#!/usr/bin/env node
/**
 * Phase-0 proof: Azure speech-to-speech translation.
 *
 * 1. Synthesises a source sentence to raw PCM in memory (no WAV header games).
 * 2. Pushes that PCM into the translation recogniser (voice-to-voice mode).
 * 3. Prints recognised text, translated text and how many audio bytes came back.
 * 4. Writes both clips as playable WAV files.
 *
 * Usage (from the backend folder, with AZURE_SPEECH_KEY/REGION in .env):
 *   node scripts/test_azure_speech.cjs
 *   node scripts/test_azure_speech.cjs --from bn --to en --text "আমি পরের সপ্তাহে কাজ শুরু করতে পারব"
 */
const fs = require('fs');
const path = require('path');

require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

let sdk;
try {
  sdk = require('microsoft-cognitiveservices-speech-sdk');
} catch (err) {
  console.error('Missing SDK. Run: npm install microsoft-cognitiveservices-speech-sdk');
  process.exit(1);
}

const args = process.argv.slice(2);
const arg = (name, fallback) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 && args[i + 1] ? args[i + 1] : fallback;
};

const FROM = arg('from', 'bn');
const TO = arg('to', 'en');
const TEXT = arg('text', 'আমি পরের সপ্তাহে কাজ শুরু করতে পারব');
const OUT_DIR = path.join(__dirname, '..', 'tmp');

const VOICES = {
  bn: { locale: 'bn-IN', voice: 'bn-BD-NabanitaNeural' },
  en: { locale: 'en-US', voice: 'en-US-JennyNeural' },
  hi: { locale: 'hi-IN', voice: 'hi-IN-SwaraNeural' },
  ar: { locale: 'ar-SA', voice: 'ar-SA-ZariyahNeural' },
  es: { locale: 'es-ES', voice: 'es-ES-ElviraNeural' },
  fr: { locale: 'fr-FR', voice: 'fr-FR-DeniseNeural' },
  de: { locale: 'de-DE', voice: 'de-DE-KatjaNeural' },
};

const KEY = (process.env.AZURE_SPEECH_KEY || '').trim();
const REGION = (process.env.AZURE_SPEECH_REGION || '').trim();

if (!KEY || !REGION) {
  console.error('AZURE_SPEECH_KEY / AZURE_SPEECH_REGION missing in backend/.env');
  process.exit(1);
}

const from = VOICES[FROM] || VOICES.bn;
const to = VOICES[TO] || VOICES.en;
fs.mkdirSync(OUT_DIR, { recursive: true });

/** Minimal RIFF header so the clips open in any player. */
function wavFromPcm(pcm, sampleRate, channels = 1, bits = 16) {
  const header = Buffer.alloc(44);
  const byteRate = (sampleRate * channels * bits) / 8;
  const blockAlign = (channels * bits) / 8;
  header.write('RIFF', 0);
  header.writeUInt32LE(36 + pcm.length, 4);
  header.write('WAVE', 8);
  header.write('fmt ', 12);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20);
  header.writeUInt16LE(channels, 22);
  header.writeUInt32LE(sampleRate, 24);
  header.writeUInt32LE(byteRate, 28);
  header.writeUInt16LE(blockAlign, 32);
  header.writeUInt16LE(bits, 34);
  header.write('data', 36);
  header.writeUInt32LE(pcm.length, 40);
  return Buffer.concat([header, pcm]);
}

function synthesiseSource() {
  return new Promise((resolve, reject) => {
    const config = sdk.SpeechConfig.fromSubscription(KEY, REGION);
    config.speechSynthesisVoiceName = from.voice;
    config.speechSynthesisOutputFormat =
      sdk.SpeechSynthesisOutputFormat.Raw16Khz16BitMonoPcm ||
      sdk.SpeechSynthesisOutputFormat.Riff16Khz16BitMonoPcm;
    // No AudioConfig: the audio comes back in result.audioData.
    const synth = new sdk.SpeechSynthesizer(config);
    synth.speakTextAsync(
      TEXT,
      (result) => {
        synth.close();
        if (result.reason !== sdk.ResultReason.SynthesizingAudioCompleted) {
          reject(new Error(`TTS failed: ${result.errorDetails || result.reason}`));
          return;
        }
        const pcm = Buffer.from(result.audioData || new ArrayBuffer(0));
        if (pcm.length < 1000) {
          reject(new Error(`TTS returned only ${pcm.length} bytes`));
          return;
        }
        const file = path.join(OUT_DIR, `azure-source-${FROM}.wav`);
        fs.writeFileSync(file, wavFromPcm(pcm, 16000));
        console.log(`1. source audio: ${pcm.length} bytes -> ${file}`);
        resolve(pcm);
      },
      (err) => {
        synth.close();
        reject(new Error(String(err)));
      }
    );
  });
}

function translate(pcm) {
  return new Promise((resolve, reject) => {
    const config = sdk.SpeechTranslationConfig.fromSubscription(KEY, REGION);
    config.speechRecognitionLanguage = from.locale;
    config.addTargetLanguage(to.locale.split('-')[0]);
    config.voiceName = to.voice;
    config.speechSynthesisOutputFormat =
      sdk.SpeechSynthesisOutputFormat.Raw24Khz16BitMonoPcm ||
      sdk.SpeechSynthesisOutputFormat.Riff24Khz16BitMonoPcm;

    const pushStream = sdk.AudioInputStream.createPushStream(
      sdk.AudioStreamFormat.getWaveFormatPCM(16000, 16, 1)
    );
    pushStream.write(pcm.buffer.slice(pcm.byteOffset, pcm.byteOffset + pcm.length));
    pushStream.close();

    const rec = new sdk.TranslationRecognizer(
      config,
      sdk.AudioConfig.fromStreamInput(pushStream)
    );

    let recognised = '';
    const chunks = [];

    rec.recognizing = (_s, e) => {
      if (e.result && e.result.text) recognised = e.result.text;
    };
    rec.synthesizing = (_s, e) => {
      if (e.result.audio && e.result.audio.byteLength > 0) {
        chunks.push(Buffer.from(e.result.audio));
      }
    };
    rec.canceled = (_s, e) => {
      reject(new Error(e.errorDetails || 'translation canceled'));
    };

    rec.recognizeOnceAsync(
      (result) => {
        rec.close();
        if (result.reason !== sdk.ResultReason.TranslatedSpeech) {
          reject(new Error(`not translated: ${result.reason}`));
          return;
        }
        const raw = Buffer.concat(chunks);
        // `synthesizing` can return RIFF or raw depending on the SDK build.
        const isRiff = raw.length > 12 && raw.toString('ascii', 0, 4) === 'RIFF';
        resolve({
          recognised: result.text || recognised,
          translated: result.translations.get(to.locale.split('-')[0]) || '',
          audio: isRiff ? raw : wavFromPcm(raw, 24000),
          rawBytes: raw.length,
        });
      },
      (err) => {
        rec.close();
        reject(new Error(String(err)));
      }
    );
  });
}

(async () => {
  console.log(`Azure test: ${FROM} -> ${TO}`);
  try {
    const pcm = await synthesiseSource();
    const result = await translate(pcm);
    const outFile = path.join(OUT_DIR, `azure-translated-${TO}.wav`);
    fs.writeFileSync(outFile, result.audio);

    console.log('2. recognised (source):', result.recognised || '(empty)');
    console.log('3. translated (target):', result.translated || '(empty)');
    console.log(
      `4. voice output: ${result.rawBytes} bytes -> ${outFile}`
    );
    const ok = Boolean(result.translated) && result.rawBytes > 1000;
    console.log(ok ? 'RESULT: PASS (voice-to-voice)' : 'RESULT: FAIL');
    process.exit(ok ? 0 : 2);
  } catch (err) {
    console.error('RESULT: ERROR —', err.message);
    process.exit(3);
  }
})();
