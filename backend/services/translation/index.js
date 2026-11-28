import { azureConfigured, AzureTranslationSession, azureStatus } from './azure.js';
import { azureLanguage, azurePairSupported } from './languages.js';

export const PROVIDERS = ['azure', 'gemini'];

/** Which translation engine the relay should use for new calls. */
export function activeProvider() {
  const raw = (process.env.TRANSLATION_PROVIDER || 'azure').trim().toLowerCase();
  return PROVIDERS.includes(raw) ? raw : 'azure';
}

export function providerStatus() {
  return {
    provider: activeProvider(),
    azure: azureStatus(),
    geminiConfigured: Boolean(process.env.GEMINI_API_KEY?.trim()),
  };
}

export {
  AzureTranslationSession,
  azureConfigured,
  azureLanguage,
  azurePairSupported,
};
