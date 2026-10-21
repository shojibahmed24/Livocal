#!/usr/bin/env node
/**
 * Livocal - Payment Settings PII Isolation Migration Script
 *
 * Scans all documents in the `/users` collection:
 * 1. Identifies any documents with legacy payment fields:
 *    - binancePayId
 *    - cryptoUsdtTrc20
 *    - cryptoUsdtBep20
 *    - bkashNumber
 *    - nagadNumber
 * 2. Migrates non-empty fields into the private subcollection:
 *    `users/{userId}/wallet/payment_settings`
 * 3. Deletes (scrubs) the legacy payment fields from the parent `/users/{userId}` document.
 *
 * This completely eliminates the PII leak from public profile reads (`users/{userId}`),
 * protects user financial addresses, and allows legacy users to update their profile
 * without being blocked by strict Firestore security rules.
 *
 * Usage:
 *   node backend/scripts/migrate_user_payment_fields.js [--dry-run]
 */

import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.join(__dirname, '../.env') });
dotenv.config();

const isDryRun = process.argv.includes('--dry-run');

let serviceAccount = null;
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } catch (e) {
    console.error('Error parsing FIREBASE_SERVICE_ACCOUNT:', e.message);
  }
} else {
  const localKeyPath = path.join(__dirname, '../serviceAccountKey.json');
  if (fs.existsSync(localKeyPath)) {
    try {
      serviceAccount = JSON.parse(fs.readFileSync(localKeyPath, 'utf8'));
    } catch (e) {
      console.error('Error reading serviceAccountKey.json:', e.message);
    }
  }
}

if (!serviceAccount) {
  console.error('ERROR: FIREBASE_SERVICE_ACCOUNT env or serviceAccountKey.json is required.');
  process.exit(1);
}

const app = initializeApp({
  credential: cert(serviceAccount),
  projectId: serviceAccount.project_id || 'livocal24',
});

const firestoreDb = getFirestore(app);

const PAYMENT_FIELDS = [
  'binancePayId',
  'cryptoUsdtTrc20',
  'cryptoUsdtBep20',
  'bkashNumber',
  'nagadNumber',
];

async function runMigration() {
  console.log(`=== Livocal User Payment PII Isolation Migration [Dry-run: ${isDryRun}] ===\n`);

  let scannedCount = 0;
  let migratedCount = 0;
  let scrubbedCount = 0;

  const usersSnapshot = await firestoreDb.collection('users').get();
  console.log(`Found ${usersSnapshot.docs.length} user documents to inspect.\n`);

  for (const userDoc of usersSnapshot.docs) {
    scannedCount++;
    const userId = userDoc.id;
    const userData = userDoc.data();

    // Check if any payment fields exist
    const paymentUpdates = {};
    const deleteUpdates = {};
    let hasLegacyPayment = false;

    for (const field of PAYMENT_FIELDS) {
      if (field in userData) {
        hasLegacyPayment = true;
        const val = userData[field];
        if (typeof val === 'string' && val.trim().length > 0) {
          paymentUpdates[field] = val.trim();
        }
        deleteUpdates[field] = FieldValue.delete();
      }
    }

    if (!hasLegacyPayment) {
      continue;
    }

    console.log(`User ${userId}: Legacy payment fields detected.`);

    if (!isDryRun) {
      const batch = firestoreDb.batch();

      // 1. If any non-empty payment fields exist, ensure they are preserved in wallet/payment_settings
      if (Object.keys(paymentUpdates).length > 0) {
        const settingsRef = userDoc.ref.collection('wallet').doc('payment_settings');
        paymentUpdates.updatedAt = new Date().toISOString();
        paymentUpdates.migratedFromUserDoc = true;
        batch.set(settingsRef, paymentUpdates, { merge: true });
        migratedCount++;
      }

      // 2. Scrub from parent user document
      batch.update(userDoc.ref, deleteUpdates);
      await batch.commit();
      scrubbedCount++;
      console.log(`  -> Successfully migrated to wallet/payment_settings and scrubbed from user doc.`);
    } else {
      console.log(`  -> [DRY-RUN] Would migrate fields:`, Object.keys(paymentUpdates));
      console.log(`  -> [DRY-RUN] Would scrub from parent user doc:`, Object.keys(deleteUpdates));
      migratedCount++;
      scrubbedCount++;
    }
  }

  if (!isDryRun) {
    try {
      await firestoreDb.collection('_system_migrations').doc('payment_pii_isolation').set({
        completed: true,
        completedAt: new Date().toISOString(),
        scannedUsers: scannedCount,
        migratedUsers: migratedCount,
        scrubbedUsers: scrubbedCount,
      }, { merge: true });
      console.log('Saved migration state in _system_migrations/payment_pii_isolation.');
    } catch (saveErr) {
      console.warn('Could not record migration state in _system_migrations:', saveErr.message);
    }
  }

  console.log('\n=== Migration Completed ===');
  console.log(`Scanned Users:  ${scannedCount}`);
  console.log(`Migrated to Wallet: ${migratedCount}`);
  console.log(`Scrubbed from /users: ${scrubbedCount}\n`);
}

runMigration()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Migration failed:', err);
    process.exit(1);
  });
