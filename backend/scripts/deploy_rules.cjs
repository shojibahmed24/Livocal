/**
 * Backward compatibility alias for deploy_firestore_config.cjs
 */
const { deployFirestoreConfig } = require('./deploy_firestore_config.cjs');

deployFirestoreConfig().catch((err) => {
  console.error('[DeployRules] FAILED:', err.response?.data || err.message);
  process.exit(1);
});
