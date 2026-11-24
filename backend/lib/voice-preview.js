import fs from 'fs';
import WebSocket from 'ws';

/** Display names for the languages the picker can preview. */
export const PREVIEW_LANGUAGE_NAMES = {
  en: 'English',
  bn: 'Bengali',
  hi: 'Hindi',
  ar: 'Arabic',
  es: 'Spanish',
  fr: 'French',
  de: 'German',
};

/**
 * Wraps raw 16-bit PCM in a RIFF/WAV container so clients can play the bytes
 * without knowing the sample format.
 */
export function pcmToWav(pcm, { sampleRate = 24000, channels = 1, bitsPerSample = 16 } = {}) {
  const byteRate = (sampleRate * channels * bitsPerSample) / 8;
  const blockAlign = (channels * bitsPerSample) / 8;
  const header = Buffer.alloc(44);
  header.write('RIFF', 0, 'ascii');
  header.writeUInt32LE(36 + pcm.length, 4);
  header.write('WAVE', 8, 'ascii');
  header.write('fmt ', 12, 'ascii');
  header.writeUInt32LE(16, 16); // PCM chunk size
  header.writeUInt16LE(1, 20); // format = PCM
  header.writeUInt16LE(channels, 22);
  header.writeUInt32LE(sampleRate, 24);
  header.writeUInt32LE(byteRate, 28);
  header.writeUInt16LE(blockAlign, 32);
  header.writeUInt16LE(bitsPerSample, 34);
  header.write('data', 36, 'ascii');
  header.writeUInt32LE(pcm.length, 40);
  return Buffer.concat([header, pcm]);
}

/** Returns the peak absolute 16-bit sample value of a buffer. */
function peakOf(pcm) {
  let peak = 0;
  for (let i = 0; i + 1 < pcm.length; i += 2) {
    const value = Math.abs(pcm.readInt16LE(i));
    if (value > peak) peak = value;
  }
  return peak;
}

/**
 * Trims leading/trailing near-silence from 16-bit mono PCM. The translate
 * model keeps streaming silent frames after it finishes speaking, which would
 * otherwise dominate the preview file.
 */
export function trimSilence(pcm, { sampleRate = 24000, threshold = 250, keepMs = 250 } = {}) {
  const sampleCount = Math.floor(pcm.length / 2);
  let first = -1;
  let last = -1;
  for (let i = 0; i < sampleCount; i++) {
    if (Math.abs(pcm.readInt16LE(i * 2)) > threshold) {
      if (first === -1) first = i;
      last = i;
    }
  }
  if (first === -1) return Buffer.alloc(0);

  const keepSamples = Math.floor((sampleRate * keepMs) / 1000);
  const start = Math.max(0, first - keepSamples);
  const end = Math.min(sampleCount, last + keepSamples);
  return pcm.subarray(start * 2, end * 2);
}
export function loadPreviewSample(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8').replace(/\s+/g, '');
  return Buffer.from(raw, 'base64');
}

/**
 * Opens a short Live session, streams the fixed sample, and returns the
 * translated speech as a WAV buffer spoken in `voice`.
 *
 * The translate model is speech-to-speech: it produces nothing for text turns,
 * which is why a real audio sample is streamed instead.
 */
export function synthesizeLiveVoicePreview({
  apiKey,
  model,
  voice,
  langCode,
  sample,
  timeoutMs = 25000,
  maxAudioSeconds = 14,
  onTranscript,
}) {
  const upstreamUrl =
    'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=' +
    apiKey;

  return new Promise((resolve, reject) => {
    const ws = new WebSocket(upstreamUrl);
    const audioChunks = [];
    let settled = false;
    let quietTimer = null;
    let heardSpeech = false;
    let lastSpeechAt = 0;

    const clearTimers = () => {
      clearTimeout(deadline);
      clearTimeout(quietTimer);
    };

    const finish = () => {
      if (settled) return;
      settled = true;
      clearTimers();
      try { ws.close(); } catch {}
      if (!audioChunks.length) {
        reject(new Error('Live model returned no audio'));
        return;
      }
      const pcm = trimSilence(Buffer.concat(audioChunks));
      if (!pcm.length) {
        reject(new Error('Live model returned silence'));
        return;
      }
      resolve(pcmToWav(pcm, { sampleRate: 24000, channels: 1, bitsPerSample: 16 }));
    };

    const fail = (err) => {
      if (settled) return;
      settled = true;
      clearTimers();
      try { ws.close(); } catch {}
      reject(err);
    };

    const deadline = setTimeout(() => {
      if (audioChunks.length) finish();
      else fail(new Error('Live preview timed out'));
    }, timeoutMs);

    ws.on('open', () => {
      ws.send(
        JSON.stringify({
          setup: {
            model,
            generationConfig: {
              responseModalities: ['AUDIO'],
              speechConfig: {
                voiceConfig: { prebuiltVoiceConfig: { voiceName: voice } },
              },
              // Required by the translate model: without it the model keeps
              // translating indefinitely instead of speaking one short turn.
              translationConfig: {
                targetLanguageCode: langCode,
                // Echo when the sample is already in the target language,
                // otherwise the model stays silent.
                echoTargetLanguage: true,
              },
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
        }),
      );
    });

    ws.on('message', (raw) => {
      let msg;
      try { msg = JSON.parse(raw.toString('utf8')); } catch { return; }

      if (msg.setupComplete) {
        // Stream at realtime pace (100 ms chunks); the translator works on a
        // continuous stream, so faster input confuses its voice activity logic.
        const chunkBytes = 3200; // 100 ms of 16 kHz 16-bit mono
        let offset = 0;
        const pump = () => {
          if (settled) return;
          if (offset >= sample.length) {
            // Tell the model the audio stream has ended.
            ws.send(JSON.stringify({ realtimeInput: { audioStreamEnd: true } }));
            return;
          }
          const slice = sample.subarray(offset, Math.min(offset + chunkBytes, sample.length));
          ws.send(
            JSON.stringify({
              realtimeInput: {
                mediaChunks: [{ mimeType: 'audio/pcm;rate=16000', data: slice.toString('base64') }],
              },
            }),
          );
          offset += chunkBytes;
          setTimeout(pump, 100);
        };
        pump();
      }

      const transcript = msg.serverContent?.outputTranscription?.text;
      if (transcript && typeof onTranscript === 'function') onTranscript(transcript);

      for (const part of msg.serverContent?.modelTurn?.parts || []) {
        if (part.text && typeof onTranscript === 'function') onTranscript(part.text);
        if (!part.inlineData?.data) continue;

        const chunk = Buffer.from(part.inlineData.data, 'base64');
        if (peakOf(chunk) > 250) {
          heardSpeech = true;
          lastSpeechAt = Date.now();
          audioChunks.push(chunk);
        } else if (heardSpeech) {
          audioChunks.push(chunk);
          // The model keeps streaming silent frames after the sentence ends;
          // stop as soon as the speech has clearly finished.
          if (Date.now() - lastSpeechAt >= 1200) {
            finish();
            return;
          }
        } else {
          continue; // drop leading silence
        }

        const capturedBytes = audioChunks.reduce((total, item) => total + item.length, 0);
        if (capturedBytes >= maxAudioSeconds * 48000) {
          finish();
          return;
        }
      }

      if (msg.serverContent?.turnComplete && audioChunks.length) {
        finish();
      }
    });

    ws.on('error', (err) => fail(err));
    ws.on('close', (code) => {
      if (settled) return;
      if (audioChunks.length) finish();
      else fail(new Error(`Live session closed (${code})`));
    });
  });
}
