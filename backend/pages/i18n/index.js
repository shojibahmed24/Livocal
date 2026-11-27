import en from './en.js';
import bn from './bn.js';
import hi from './hi.js';
import ar from './ar.js';
import es from './es.js';
import fr from './fr.js';
import de from './de.js';

export const LANGUAGES = ['en', 'bn', 'hi', 'ar', 'es', 'fr', 'de'];
export const RTL_LANGUAGES = ['ar'];

export const COPY = { en, bn, hi, ar, es, fr, de };

export const LANDING_PATHS = {
  en: '/',
  bn: '/bn',
  hi: '/hi',
  ar: '/ar',
  es: '/es',
  fr: '/fr',
  de: '/de',
};

export function pathFor(code) {
  return LANDING_PATHS[code] || `/${code}`;
}

export default COPY;
