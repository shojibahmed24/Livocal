// Diagnose preview output: are the voices actually different, and is the
// waveform clean (no internal gaps / distortion)?
import fs from 'fs';
import path from 'path';
import { loadPreviewSample, synthesizeLiveVoicePreview } from './lib/voice-preview.js';

const apiKey = process.env.GEMINI_API_KEY;
const lang = 'bn';
const voices = ['Aoede', 'Kore', 'Leda', 'Charon', 'Puck'];
const sample = loadPreviewSample(path.join(process.cwd(), 'assets', 'preview-input-16k.pcm.b64'));

// Mean pitch via autocorrelation on voiced frames (24 kHz mono 16-bit).
function analyseWav(wav) {
  const pcm = wav.subarray(44);
  const frames = Math.floor(pcm.length / 2);
  const values = new Float64Array(frames);
  for (let i = 0; i < frames; i++) values[i] = pcm.readInt16LE(i * 2) / 32768;

  const frameLen = 1024;
  const pitches = [];
  let voicedFrames = 0;
  let energyFrames = 0;
  const silences = [];
  let silenceRun = 0;

  for (let start = 0; start + frameLen < frames; start += 480) {
    let rms = 0;
    for (let i = 0; i < frameLen; i++) rms += values[start + i] * values[start + i];
    rms = Math.sqrt(rms / frameLen);
    if (rms < 0.01) {
      silenceRun += 480;
      continue;
    }
    if (silenceRun > 2400) silences.push(Math.round((silenceRun / 24000) * 1000));
    silenceRun = 0;
    energyFrames++;

    // autocorrelation pitch search 70-400 Hz
    let bestLag = 0;
    let bestCorr = 0;
    for (let lag = 60; lag <= 343; lag++) {
      let corr = 0;
      for (let i = 0; i < frameLen - lag; i += 2) corr += values[start + i] * values[start + i + lag];
      if (corr > bestCorr) { bestCorr = corr; bestLag = lag; }
    }
    if (bestLag > 0 && bestCorr > 0) {
      pitches.push(24000 / bestLag);
      voicedFrames++;
    }
  }

  pitches.sort((a, b) => a - b);
  const median = pitches.length ? pitches[Math.floor(pitches.length / 2)] : 0;
  const p10 = pitches.length ? pitches[Math.floor(pitches.length * 0.1)] : 0;
  const p90 = pitches.length ? pitches[Math.floor(pitches.length * 0.9)] : 0;
  const dataSeconds = frames / 24000;
  const internalGaps = silences.filter((ms) => ms >= 120 && ms <= 1500);

  return {
    seconds: +dataSeconds.toFixed(2),
    medianPitchHz: Math.round(median),
    pitchRange: [Math.round(p10), Math.round(p90)],
    voicedRatio: +(voicedFrames / Math.max(1, energyFrames)).toFixed(2),
    internalGapsMs: internalGaps.slice(0, 8),
    gapCount: internalGaps.length,
  };
}

for (const voice of voices) {
  const t0 = Date.now();
  const wav = await synthesizeLiveVoicePreview({
    apiKey,
    model: 'models/gemini-3.5-live-translate-preview',
    voice,
    langCode: lang,
    sample,
  });
  const file = path.join(process.env.TEMP || '.', `diag_${voice}.wav`);
  fs.writeFileSync(file, wav);
  console.log(JSON.stringify({ voice, ms: Date.now() - t0, bytes: wav.length, ...analyseWav(wav) }));
}
process.exit(0);
