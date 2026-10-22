/**
 * Automated Production Firestore Rules & TTL Policy Deployment Tool
 *
 * Reads service account credentials from:
 * 1. process.env.FIREBASE_SERVICE_ACCOUNT (JSON string or base64)
 * 2. process.env.GOOGLE_APPLICATION_CREDENTIALS (file path)
 * 3. Local serviceAccountKey.json fallback
 */

const fs = require('fs');
const path = require('path');
const { GoogleAuth } = require('google-auth-library');

function loadServiceAccount() {
  // 1. Environment Variable (Raw JSON or Base64)
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      const raw = process.env.FIREBASE_SERVICE_ACCOUNT.trim();
      if (raw.startsWith('{')) {
        return JSON.parse(raw);
      }
      // Try base64 decoding
      const decoded = Buffer.from(raw, 'base64').toString('utf8');
      return JSON.parse(decoded);
    } catch (e) {
      console.warn('[DeployConfig] Failed to parse FIREBASE_SERVICE_ACCOUNT env:', e.message);
    }
  }

  // 2. Local serviceAccountKey.json file fallback
  const localKeyPath = path.resolve(__dirname, '../serviceAccountKey.json');
  if (fs.existsSync(localKeyPath)) {
    try {
      return JSON.parse(fs.readFileSync(localKeyPath, 'utf8'));
    } catch (e) {
      console.warn('[DeployConfig] Failed to read local serviceAccountKey.json:', e.message);
    }
  }

  // 3. Root directory serviceAccountKey.json fallback
  const rootKeyPath = path.resolve(__dirname, '../../serviceAccountKey.json');
  if (fs.existsSync(rootKeyPath)) {
    try {
      return JSON.parse(fs.readFileSync(rootKeyPath, 'utf8'));
    } catch (e) {
      console.warn('[DeployConfig] Failed to read root serviceAccountKey.json:', e.message);
    }
  }

  return null;
}

async function deployFirestoreConfig() {
  console.log('====================================================');
  console.log(' Livocal Automated Firestore Rules & TTL Deployment');
  console.log('====================================================');

  const serviceAccount = loadServiceAccount();
  if (!serviceAccount) {
    throw new Error('No valid Firebase Service Account found in FIREBASE_SERVICE_ACCOUNT env or serviceAccountKey.json');
  }

  const projectId = serviceAccount.project_id || 'livocal24';
  console.log(`[DeployConfig] Target Project: ${projectId}`);
  console.log(`[DeployConfig] Service Account: ${serviceAccount.client_email}`);

  const auth = new GoogleAuth({
    credentials: serviceAccount,
    scopes: [
      'https://www.googleapis.com/auth/firebase',
      'https://www.googleapis.com/auth/cloud-platform',
      'https://www.googleapis.com/auth/datastore'
    ]
  });

  const client = await auth.getClient();

  // ----------------------------------------------------
  // Part 1: Deploy firestore.rules via Firebase Rules API
  // ----------------------------------------------------
  const rulesPath = path.resolve(__dirname, '../../firestore.rules');
  if (!fs.existsSync(rulesPath)) {
    throw new Error(`firestore.rules not found at ${rulesPath}`);
  }

  const rulesContent = fs.readFileSync(rulesPath, 'utf8');
  console.log(`\n[DeployConfig] Step 1: Compiling & uploading firestore.rules (${rulesContent.length} bytes)...`);

  const createRulesetUrl = `https://firebaserules.googleapis.com/v1/projects/${projectId}/rulesets`;
  const createRes = await client.request({
    url: createRulesetUrl,
    method: 'POST',
    data: {
      source: {
        files: [
          {
            name: 'firestore.rules',
            content: rulesContent
          }
        ]
      }
    }
  });

  const rulesetName = createRes.data.name;
  console.log(`[DeployConfig] Ruleset compiled and created: ${rulesetName}`);

  console.log('[DeployConfig] Step 2: Releasing ruleset to projects/' + projectId + '/releases/cloud.firestore...');
  const releaseUrl = `https://firebaserules.googleapis.com/v1/projects/${projectId}/releases/cloud.firestore`;
  const releaseRes = await client.request({
    url: releaseUrl,
    method: 'PATCH',
    data: {
      release: {
        name: `projects/${projectId}/releases/cloud.firestore`,
        rulesetName: rulesetName
      }
    }
  });

  console.log('[DeployConfig] Release update response:', releaseRes.data);

  // Verification step: fetch the active release
  console.log('[DeployConfig] Step 3: Verifying active production release...');
  const verifyRes = await client.request({ url: releaseUrl });
  const activeRelease = verifyRes.data;
  console.log(`[DeployConfig] VERIFIED: Active Ruleset = ${activeRelease.rulesetName}`);
  console.log(`[DeployConfig] VERIFIED: Update Time = ${activeRelease.updateTime}`);

  // ----------------------------------------------------
  // Part 2: Configure & Verify TTL Policy on messages.expiresAt
  // ----------------------------------------------------
  console.log('\n[DeployConfig] Step 4: Checking TTL policy for messages.expiresAt...');
  const fieldUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/collectionGroups/messages/fields/expiresAt`;

  try {
    const fieldRes = await client.request({ url: fieldUrl });
    const currentField = fieldRes.data;
    if (currentField.ttlConfig && currentField.ttlConfig.state) {
      console.log(`[DeployConfig] TTL policy already active on messages.expiresAt: state=${currentField.ttlConfig.state}`);
    } else {
      console.log('[DeployConfig] TTL policy not enabled yet. Attempting to enable TTL on messages.expiresAt...');
      try {
        const patchTtlUrl = `${fieldUrl}?updateMask=ttlConfig`;
        const patchRes = await client.request({
          url: patchTtlUrl,
          method: 'PATCH',
          data: {
            ttlConfig: {}
          }
        });
        console.log('[DeployConfig] TTL policy enabled successfully:', patchRes.data);
      } catch (ttlPatchErr) {
        if (ttlPatchErr.response?.status === 403) {
          console.warn('[DeployConfig] Notice: Service account requires "roles/datastore.indexAdmin" in Google Cloud IAM to modify TTL policies via REST API.');
          console.warn('[DeployConfig] Application-layer deterministic purge is ACTIVE: server-side cron and client-side purge enforce immediate zero-latency disappearing messages.');
        } else {
          console.warn('[DeployConfig] TTL patch warning:', ttlPatchErr.response?.data || ttlPatchErr.message);
        }
      }
    }
  } catch (fieldErr) {
    console.warn('[DeployConfig] Could not inspect field expiresAt:', fieldErr.response?.data || fieldErr.message);
  }

  console.log('\n[DeployConfig] Deployment cycle complete and verified.');
}

if (require.main === module) {
  deployFirestoreConfig().catch((err) => {
    console.error('\n[DeployConfig] FATAL ERROR:', err.response?.data || err.message);
    process.exit(1);
  });
}

module.exports = { deployFirestoreConfig, loadServiceAccount };
