/**
 * App language code -> Azure Speech locale + neural voice.
 *
 * - `locale` is used for speech recognition (source language).
 * - `voice`  is used for speech synthesis (target language, voice-to-voice).
 * - `target` is the short code passed to addTargetLanguage().
 *
 * Only languages that Azure can both recognise and speak are listed. Anything
 * missing here falls back to direct voice in the app instead of failing.
 */
export const AZURE_LANGUAGES = {
  en: { locale: 'en-US', target: 'en', voice: 'en-US-JennyNeural' },
  bn: { locale: 'bn-IN', target: 'bn', voice: 'bn-BD-NabanitaNeural' },
  hi: { locale: 'hi-IN', target: 'hi', voice: 'hi-IN-SwaraNeural' },
  ur: { locale: 'ur-PK', target: 'ur', voice: 'ur-PK-UzmaNeural' },
  ar: { locale: 'ar-SA', target: 'ar', voice: 'ar-SA-ZariyahNeural' },
  es: { locale: 'es-ES', target: 'es', voice: 'es-ES-ElviraNeural' },
  fr: { locale: 'fr-FR', target: 'fr', voice: 'fr-FR-DeniseNeural' },
  de: { locale: 'de-DE', target: 'de', voice: 'de-DE-KatjaNeural' },
  it: { locale: 'it-IT', target: 'it', voice: 'it-IT-ElsaNeural' },
  pt: { locale: 'pt-BR', target: 'pt', voice: 'pt-BR-FranciscaNeural' },
  ru: { locale: 'ru-RU', target: 'ru', voice: 'ru-RU-SvetlanaNeural' },
  tr: { locale: 'tr-TR', target: 'tr', voice: 'tr-TR-EmelNeural' },
  zh: { locale: 'zh-CN', target: 'zh-Hans', voice: 'zh-CN-XiaoxiaoNeural' },
  ja: { locale: 'ja-JP', target: 'ja', voice: 'ja-JP-NanamiNeural' },
  ko: { locale: 'ko-KR', target: 'ko', voice: 'ko-KR-SunHiNeural' },
  id: { locale: 'id-ID', target: 'id', voice: 'id-ID-GadisNeural' },
  vi: { locale: 'vi-VN', target: 'vi', voice: 'vi-VN-HoaiMyNeural' },
  th: { locale: 'th-TH', target: 'th', voice: 'th-TH-PremwadeeNeural' },
  ta: { locale: 'ta-IN', target: 'ta', voice: 'ta-IN-PallaviNeural' },
  te: { locale: 'te-IN', target: 'te', voice: 'te-IN-ShrutiNeural' },
  nl: { locale: 'nl-NL', target: 'nl', voice: 'nl-NL-ColetteNeural' },
  pl: { locale: 'pl-PL', target: 'pl', voice: 'pl-PL-ZofiaNeural' },
  sw: { locale: 'sw-KE', target: 'sw', voice: 'sw-KE-ZuriNeural' },
  fa: { locale: 'fa-IR', target: 'fa', voice: 'fa-IR-DilaraNeural' },
  fil: { locale: 'fil-PH', target: 'fil', voice: 'fil-PH-BlessicaNeural' },
};

/** Normalises an app code (`bn`, `bn-BD`, `en-GB`) to a two-letter key. */
export function normaliseCode(code) {
  return String(code || '')
    .trim()
    .toLowerCase()
    .split('-')[0];
}

/** Returns { locale, target, voice } or null when Azure cannot handle it. */
export function azureLanguage(code) {
  return AZURE_LANGUAGES[normaliseCode(code)] || null;
}

/** True when both directions of a pair can be recognised and spoken. */
export function azurePairSupported(fromCode, toCode) {
  return Boolean(azureLanguage(fromCode) && azureLanguage(toCode));
}
