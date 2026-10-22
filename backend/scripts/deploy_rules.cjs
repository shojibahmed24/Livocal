const fs = require('fs');
const path = require('path');
const { GoogleAuth } = require('google-auth-library');

async function deployFirestoreRules() {
  const rulesPath = path.resolve(__dirname, '../../firestore.rules');
  const serviceAccountPath = path.resolve(__dirname, '../serviceAccountKey.json');

  if (!fs.existsSync(rulesPath)) {
    throw new Error('firestore.rules not found at ' + rulesPath);
  }
  if (!fs.existsSync(serviceAccountPath)) {
    throw new Error('serviceAccountKey.json not found at ' + serviceAccountPath);
  }

  const rulesContent = fs.readFileSync(rulesPath, 'utf8');
  const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
  const projectId = serviceAccount.project_id || 'livocal24';

  console.log(`[DeployRules] Deploying firestore.rules to project '${projectId}'...`);

  const auth = new GoogleAuth({
    keyFile: serviceAccountPath,
    scopes: [
      'https://www.googleapis.com/auth/firebase',
      'https://www.googleapis.com/auth/cloud-platform'
    ]
  });

  const client = await auth.getClient();

  // 1. Create Ruleset
  console.log('[DeployRules] Step 1: Creating ruleset...');
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
  console.log(`[DeployRules] Ruleset created successfully: ${rulesetName}`);

  // 2. Release Ruleset to cloud.firestore
  console.log('[DeployRules] Step 2: Updating cloud.firestore release...');
  const releaseUrl = `https://firebaserules.googleapis.com/v1/projects/${projectId}/releases/cloud.firestore`;
  const updateRes = await client.request({
    url: releaseUrl,
    method: 'PATCH',
    data: {
      release: {
        name: `projects/${projectId}/releases/cloud.firestore`,
        rulesetName: rulesetName
      }
    }
  });

  console.log(`[DeployRules] Release updated successfully:`, updateRes.data);
  console.log('[DeployRules] Firestore rules are now LIVE in production!');
}

deployFirestoreRules().catch((err) => {
  console.error('[DeployRules] FAILED:', err.response?.data || err.message);
  process.exit(1);
});
