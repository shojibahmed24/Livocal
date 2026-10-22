/**
 * Trigger Render Web Service Deployment via Deploy Hook
 *
 * Usage:
 *   node scripts/trigger_render_deploy.js [optional_hook_url]
 */

import dotenv from 'dotenv';
dotenv.config();

const hookUrl = process.argv[2] || process.env.RENDER_DEPLOY_HOOK_URL;

if (!hookUrl) {
  console.log('========================================================================');
  console.log(' Render Deployment Instructions:');
  console.log('========================================================================');
  console.log('1. Go to your Render Dashboard (https://dashboard.render.com).');
  console.log('2. Open the "livocal-relay" Web Service.');
  console.log('3. In the Settings tab:');
  console.log('   - Verify "Branch" is set to "main" (not master).');
  console.log('   - Under "Auto-Deploy", make sure it is set to "Yes".');
  console.log('   - Look for "Deploy Hook" and copy the URL.');
  console.log('4. In the Environment tab:');
  console.log('   - Verify that GEMINI_API_KEY is set with your active Gemini API key.');
  console.log('5. Trigger Manual Deploy:');
  console.log('   - Click "Manual Deploy" -> "Clear build cache & deploy" to deploy immediately.');
  console.log('   - OR run: node scripts/trigger_render_deploy.js <YOUR_DEPLOY_HOOK_URL>');
  console.log('========================================================================\n');
  process.exit(0);
}

console.log(`[RenderDeploy] Triggering deployment at: ${hookUrl.substring(0, 35)}...`);

try {
  const res = await fetch(hookUrl, { method: 'POST' });
  const text = await res.text();
  console.log(`[RenderDeploy] Status: ${res.status} ${res.statusText}`);
  console.log(`[RenderDeploy] Response:`, text);
  if (res.ok) {
    console.log('[RenderDeploy] SUCCESS: Render build triggered!');
  } else {
    console.error('[RenderDeploy] FAILED: Render returned non-200 status.');
  }
} catch (err) {
  console.error('[RenderDeploy] Error sending request to deploy hook:', err.message);
}
