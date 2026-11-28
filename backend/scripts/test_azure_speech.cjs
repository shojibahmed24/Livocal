#!/usr/bin/env node
/**
 * Phase-0 proof: Azure speech-to-speech translation.
 *
 * 1. Synthesises a source sentence with a neural voice (so no recording needed).
 * 2. Feeds that WAV into the translation recogniser (voice-to-voice mode).
 * 3. Prints recognised text, translated text and how many audio bytes came back.
 * 4. Writes the translated speech to a WAV file you can play.
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

function synthesiseSource() {
  return new Promise((resolve, reject) => {
    const file = path.join(OUT_DIR, `azure-source-${FROM}.wav`);
    const config = sdk.SpeechConfig.fromSubscription(KEY, REGION);
    config.speechSynthesisVoiceName = from.voice;
    config.speechSynthesisOutputFormat =
      sdk.SpeechSynthesisOutputFormat.Riff16Khz16BitMonoPcm;
    const audio = sdk.AudioConfig.fromAudioFileOutput(file);
    const synth = new sdk.SpeechSynthesizer(config, audio);
    synth.speakTextAsync(
      TEXT,
      (result) => {
        synth.close();
        if (result.reason !== sdk.ResultReason.SynthesizingAudioCompleted) {
          reject(new Error(`TTS failed: ${result.errorDetails || result.reason}`));
          return;
        }
        console.log(`1. source audio written: ${file}`);
        resolve(file);
      },
      (err) => {
        synth.close();
        reject(new Error(String(err)));
      }
    );
  });
}

function translate(sourceFile) {
  return new Promise((resolve, reject) => {
    const config = sdk.SpeechTranslationConfig.fromSubscription(KEY, REGION);
    config.speechRecognitionLanguage = from.locale;
    config.addTargetLanguage(to.locale.split('-')[0]);
    config.voiceName = to.voice;
    config.speechSynthesisOutputFormat =
      sdk.SpeechSynthesisOutputFormat.Riff24Khz16BitMonoPcm;

    const audio = sdk.AudioConfig.fromWavFileInput(fs.readFileSync(sourceFile));
    const rec = new sdk.TranslationRecognizer(config, audio);

    let recognised = '';
    let translated = '';
    const chunks = [];

    rec.recognizing = (_s, e) => {
      if (e.result && e.result.text) recognised = e.result.text;
    };
    rec.recognized = (_s, e) => {
      if (e.result.reason === sdk.ResultReason.TranslatedSpeech) {
        recognised = e.result.text || recognised;
        translated =
          e.result.translations.get(to.locale.split('-')[0]) || translated;
      }
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
        resolve({
          recognised: result.text || recognised,
          translated:
            result.translations.get(to.locale.split('-')[0]) || translated,
          audio: Buffer.concat(chunks),
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
    const source = await synthesiseSource();
    const result = await translate(source);
    const outFile = path.join(OUT_DIR, `azure-translated-${TO}.wav`);
    fs.writeFileSync(outFile, result.audio);

    console.log('2. recognised (source):', result.recognised || '(empty)');
    console.log('3. translated (target):', result.translated || '(empty)');
    console.log(
      `4. voice output: ${result.audio.length} bytes -> ${outFile}`
    );
    const ok = Boolean(result.translated) && result.audio.length > 1000;
    console.log(ok ? 'RESULT: PASS (voice-to-voice)' : 'RESULT: FAIL');
    process.exit(ok ? 0 : 2);
  } catch (err) {
    console.error('RESULT: ERROR —', err.message);
    process.exit(3);
  }
})();
