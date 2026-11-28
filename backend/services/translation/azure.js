import sdk from 'microsoft-cognitiveservices-speech-sdk';

import { azureLanguage } from './languages.js';

const KEY = process.env.AZURE_SPEECH_KEY?.trim() || '';
const REGION = process.env.AZURE_SPEECH_REGION?.trim() || '';

/** Raw 24 kHz PCM16 mono, the format the app already plays. */
const OUTPUT_FORMAT =
  sdk.SpeechSynthesisOutputFormat.Raw24Khz16BitMonoPcm ||
  sdk.SpeechSynthesisOutputFormat.Raw16Khz16BitMonoPcm;

export function azureConfigured() {
  return Boolean(KEY && REGION);
}

export function azureStatus() {
  return {
    configured: azureConfigured(),
    region: REGION || null,
    outputFormat: OUTPUT_FORMAT,
  };
}

/**
 * One Azure Speech Translation session = one speaker direction.
 *
 * Voice-to-voice: the recogniser is configured with a neural `voiceName`, so
 * Azure streams synthesised audio through the `synthesizing` event alongside
 * the translated text. Without `voiceName` Azure returns text only.
 */
export class AzureTranslationSession {
  constructor({
    fromCode,
    toCode,
    onReady,
    onAudio,
    onTranscript,
    onPartial,
    onError,
    onClosed,
  }) {
    this.from = azureLanguage(fromCode);
    this.to = azureLanguage(toCode);
    this.fromCode = fromCode;
    this.toCode = toCode;
    this.onReady = onReady || (() => {});
    this.onAudio = onAudio || (() => {});
    this.onTranscript = onTranscript || (() => {});
    this.onPartial = onPartial || (() => {});
    this.onError = onError || (() => {});
    this.onClosed = onClosed || (() => {});
    this.recognizer = null;
    this.pushStream = null;
    this.ready = false;
    this.closed = false;
    this.audioBytes = 0;
  }

  get supported() {
    return Boolean(this.from && this.to && OUTPUT_FORMAT);
  }

  async start() {
    if (!this.supported) {
      this.onError({
        code: 'AZURE_LANG_UNSUPPORTED',
        message: `Azure cannot translate ${this.fromCode} -> ${this.toCode}`,
      });
      return false;
    }
    if (!azureConfigured()) {
      this.onError({
        code: 'AZURE_NOT_CONFIGURED',
        message: 'AZURE_SPEECH_KEY / AZURE_SPEECH_REGION missing',
      });
      return false;
    }

    const config = sdk.SpeechTranslationConfig.fromSubscription(KEY, REGION);
    config.speechRecognitionLanguage = this.from.locale;
    config.addTargetLanguage(this.to.target);
    // This is what makes it speech-to-speech instead of text-only.
    config.voiceName = this.to.voice;
    config.speechSynthesisOutputFormat = OUTPUT_FORMAT;

    // 16 kHz / 16-bit / mono: exactly what the app streams.
    this.pushStream = sdk.AudioInputStream.createPushStream(
      sdk.AudioStreamFormat.getWaveFormatPCM(16000, 16, 1)
    );
    const audioConfig = sdk.AudioConfig.fromStreamInput(this.pushStream);

    this.recognizer = new sdk.TranslationRecognizer(config, audioConfig);

    this.recognizer.recognizing = (_sender, event) => {
      if (this.closed) return;
      const text = event.result?.text;
      if (text) this.onPartial(text);
    };

    this.recognizer.recognized = (_sender, event) => {
      if (this.closed) return;
      if (event.result?.reason !== sdk.ResultReason.TranslatedSpeech) return;
      const translated = event.result.translations?.get(this.to.target) || '';
      if (translated) this.onTranscript(translated);
    };

    this.recognizer.synthesizing = (_sender, event) => {
      if (this.closed) return;
      const audio = event.result?.audio;
      if (!audio || audio.byteLength === 0) return;
      const buffer = Buffer.from(audio);
      this.audioBytes += buffer.length;
      this.onAudio(buffer);
    };

    this.recognizer.canceled = (_sender, event) => {
      if (this.closed) return;
      const details = event.cancellationDetails || {};
      const reason = details.reason;
      if (reason === sdk.CancellationReason.Error) {
        this.onError({
          code: 'AZURE_CANCELED',
          message: details.errorDetails || 'Azure translation canceled',
        });
      } else {
        this.onClosed(reason);
      }
    };

    await new Promise((resolve, reject) => {
      this.recognizer.startContinuousRecognitionAsync(
        () => resolve(),
        (err) => reject(new Error(String(err)))
      );
    }).catch((err) => {
      this.onError({ code: 'AZURE_START_FAILED', message: err.message });
      return false;
    });

    this.ready = true;
    this.onReady();
    console.log(
      `[Azure] session started ${this.from.locale} -> ${this.to.target} (${this.to.voice})`
    );
    return true;
  }

  /** PCM16 16 kHz mono from the relay. */
  sendAudio(buffer) {
    if (!this.ready || this.closed || !this.pushStream) return;
    try {
      // The Azure push stream expects an ArrayBuffer; a Node Buffer is a view.
      const arrayBuffer = buffer.buffer.slice(
        buffer.byteOffset,
        buffer.byteOffset + buffer.byteLength
      );
      this.pushStream.write(arrayBuffer);
    } catch (err) {
      this.onError({ code: 'AZURE_WRITE_FAILED', message: err.message });
    }
  }

  stop() {
    if (this.closed) return;
    this.closed = true;
    this.ready = false;
    try {
      this.recognizer?.stopContinuousRecognitionAsync(
        () => {},
        () => {}
      );
    } catch (_) {}
    try {
      this.pushStream?.close();
    } catch (_) {}
    setTimeout(() => {
      try {
        this.recognizer?.close();
      } catch (_) {}
      this.recognizer = null;
      this.pushStream = null;
    }, 300);
  }
}
