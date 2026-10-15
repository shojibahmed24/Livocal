#!/usr/bin/env node
/**
 * Livocal - Legacy Storage Migration & Cleanup CLI Script
 * Scans legacy root paths (/statuses/{fileName} and /attachments/{fileName})
 * - Deletes expired legacy statuses (>24h old) to eliminate storage quota waste
 * - Backfills authorId/senderId metadata from filenames where detectable
 *
 * Usage:
 *   node backend/scripts/migrate_legacy_storage.js [--dry-run]
 */

import dotenv from 'dotenv';
import { initializeApp, cert } from 'firebase-admin/app';
import { getStorage } from 'firebase-admin/storage';

dotenv.config();

const isDryRun = process.argv.includes('--dry-run');

let serviceAccount = null;
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } catch (e) {
    console.error('Error parsing FIREBASE_SERVICE_ACCOUNT:', e.message);
  }
}

if (!serviceAccount) {
  console.error('ERROR: FIREBASE_SERVICE_ACCOUNT environment variable is required to run migration.');
  process.exit(1);
}

const app = initializeApp({
  credential: cert(serviceAccount),
  projectId: serviceAccount.project_id || 'livocal24',
});

const storage = getStorage(app);
const bucket = storage.bucket();

async function run() {
  console.log(`=== Livocal Legacy Storage Migration [Dry-run: ${isDryRun}] ===\n`);

  const now = Date.now();
  const oneDayAgo = now - 24 * 60 * 60 * 1000;

  let expiredStatuses = 0;
  let backfilledStatuses = 0;
  let backfilledAttachments = 0;

  // 1. Process legacy statuses
  console.log('1. Scanning /statuses/ for legacy ephemeral files...');
  const [statusFiles] = await bucket.getFiles({ prefix: 'statuses/' });
  for (const file of statusFiles) {
    const parts = file.name.split('/');
    if (parts.length === 2 && parts[1]) {
      const [meta] = await file.getMetadata();
      const created = new Date(meta.timeCreated).getTime();

      if (created < oneDayAgo) {
        console.log(`  [DELETE EXPIRED] ${file.name} (Created: ${meta.timeCreated})`);
        if (!isDryRun) {
          await file.delete();
        }
        expiredStatuses++;
      } else {
        const fileName = parts[1];
        const authorMatch = fileName.match(/^([a-zA-Z0-9_-]+)[_.].*/);
        if (authorMatch && (!meta.metadata || !meta.metadata.authorId)) {
          console.log(`  [BACKFILL STATUS] ${file.name} -> authorId: ${authorMatch[1]}`);
          if (!isDryRun) {
            await file.setMetadata({
              metadata: {
                ...(meta.metadata || {}),
                authorId: authorMatch[1],
              },
            });
          }
          backfilledStatuses++;
        }
      }
    }
  }

  // 2. Process legacy attachments
  console.log('\n2. Scanning /attachments/ for legacy files...');
  const [attachFiles] = await bucket.getFiles({ prefix: 'attachments/' });
  for (const file of attachFiles) {
    const parts = file.name.split('/');
    if (parts.length === 2 && parts[1]) {
      const [meta] = await file.getMetadata();
      const fileName = parts[1];
      const senderMatch = fileName.match(/^([a-zA-Z0-9_-]+)[_.].*/);
      if (senderMatch && (!meta.metadata || !meta.metadata.senderId)) {
        console.log(`  [BACKFILL ATTACHMENT] ${file.name} -> senderId: ${senderMatch[1]}`);
        if (!isDryRun) {
          await file.setMetadata({
            metadata: {
              ...(meta.metadata || {}),
              senderId: senderMatch[1],
            },
          });
        }
        backfilledAttachments++;
      }
    }
  }

  console.log('\n=== Summary ===');
  console.log(`Expired legacy statuses deleted: ${expiredStatuses}`);
  console.log(`Legacy statuses backfilled:      ${backfilledStatuses}`);
  console.log(`Legacy attachments backfilled:   ${backfilledAttachments}`);
  console.log('Migration completed successfully.');
  process.exit(0);
}

run().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
