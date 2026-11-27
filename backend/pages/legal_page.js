'use strict';

/**
 * Public account-deletion page.
 * Google Play requires an externally reachable URL where users can request
 * deletion of their account and data, even without the app installed.
 */
export function renderDeleteAccountPage({ origin, supportEmail }) {
  const mail = supportEmail || 'support@livocal.app';
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Delete your Livocal account</title>
<meta name="description" content="How to delete your Livocal account and data, or request deletion by email.">
<link rel="canonical" href="${origin}/delete-account">
<meta name="theme-color" content="#04070d">
<style>
  *{box-sizing:border-box}
  body{margin:0;background:#04070d;color:#e7eef7;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Noto Sans Bengali',sans-serif;line-height:1.6}
  .wrap{max-width:720px;margin:0 auto;padding:36px 20px 64px}
  h1{font-size:26px;margin:0 0 6px}
  h2{font-size:16px;margin:26px 0 8px;color:#34d399}
  p,li{font-size:13.5px;color:#c3cfdd}
  .bn{background:#0c1424;border:1px solid rgba(255,255,255,.08);border-radius:14px;padding:16px;margin-top:18px}
  ol{padding-left:20px}
  a{color:#34d399}
  .tag{display:inline-block;font-size:11px;font-weight:700;padding:3px 10px;border-radius:999px;background:rgba(52,211,153,.12);color:#34d399;border:1px solid rgba(52,211,153,.3);margin-bottom:12px}
  .foot{margin-top:30px;font-size:11px;color:#7f8ea3}
</style>
</head>
<body>
<div class="wrap">
  <span class="tag">Livocal · com.livocal.app</span>
  <h1>Delete your Livocal account</h1>
  <p>This page explains how to delete your Livocal account and the data linked to it.</p>

  <h2>Delete from inside the app (fastest)</h2>
  <ol>
    <li>Open Livocal and go to <strong>Settings</strong>.</li>
    <li>Open <strong>Account</strong> → <strong>Delete account</strong>.</li>
    <li>Confirm your phone number. Deletion starts immediately.</li>
  </ol>
  <p>If you cannot sign in, email us from the address or phone number linked to the account.</p>

  <h2>What is deleted</h2>
  <ul>
    <li>Profile, display name, photo, headline, skills and portfolio content</li>
    <li>Chats, contacts, status updates and call summaries stored for you</li>
    <li>Freelancer data: clients, invoices, proposals, bookings, time entries, reviews</li>
    <li>Wallet balance and payment settings</li>
    <li>Your Firebase Authentication record (the sign-in itself)</li>
  </ul>

  <h2>What is kept</h2>
  <ul>
    <li>Financial ledgers required for accounting and tax (call billing, transfers) — kept in anonymised form where the law allows.</li>
    <li>Abuse and safety reports, until the case is closed.</li>
  </ul>
  <p>Nothing else is retained, and retained records are never used for marketing.</p>

  <h2>Email request</h2>
  <p>Send a message to <a href="mailto:${mail}?subject=Delete%20my%20Livocal%20account">${mail}</a>
  with the subject “Delete my Livocal account” and the phone number you signed up with.
  We verify ownership and complete deletion within <strong>7 days</strong>.</p>

  <div class="bn">
    <h2 style="margin-top:0">বাংলায়</h2>
    <p>অ্যাপে <strong>Settings → Account → Delete account</strong> থেকে অ্যাকাউন্ট মুছে ফেলতে পারবেন।
    অ্যাপে ঢুকতে না পারলে উপরের ইমেইলে আপনার ফোন নম্বরসহ লিখুন — ৭ দিনের মধ্যে অ্যাকাউন্ট ও সব ডেটা মুছে ফেলা হবে।</p>
  </div>

  <p class="foot">
    <a href="${origin}/privacy-policy">Privacy Policy</a> ·
    <a href="${origin}/terms-of-service">Terms of Service</a> ·
    <a href="${origin}">Livocal</a>
  </p>
</div>
</body>
</html>`;
}
