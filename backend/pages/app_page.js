'use strict';

/** Installable mobile web hub for one freelancer (F7 / Phase-5 light). */

function esc(value) {
  return String(value == null ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export function renderAppHub({ slug, displayName, headline, avatarUrl }) {
  const name = esc(displayName || 'Livocal');
  const sub = esc(headline || 'Freelancer on Livocal');
  const root = `/${encodeURIComponent(slug)}`;
  const cards = [
    {
      href: `/u/${esc(slug)}`,
      title: 'Public profile',
      desc: 'Portfolio, services, experience and reviews',
      icon: '👤',
    },
    {
      href: `/book/${esc(slug)}`,
      title: 'Book a call',
      desc: 'Pick a time that works for you',
      icon: '📅',
    },
    {
      href: `/room/${esc(slug)}`,
      title: 'Guest call room',
      desc: 'Talk in the browser — no app install',
      icon: '🎙️',
    },
    {
      href: `/cv/${esc(slug)}`,
      title: 'CV',
      desc: 'Downloadable one-page resume',
      icon: '📄',
    },
  ];

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
<title>${name} · Livocal</title>
<meta name="theme-color" content="#04070d">
<link rel="manifest" href="/manifest.webmanifest?slug=${encodeURIComponent(slug)}">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<style>
  *{box-sizing:border-box}
  body{margin:0;background:#04070d;color:#f1f5f9;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;padding:20px 16px 40px;max-width:560px;margin:0 auto}
  .top{display:flex;align-items:center;gap:12px;margin-bottom:18px}
  .avatar{width:56px;height:56px;border-radius:16px;background:#12203a;display:flex;align-items:center;justify-content:center;font-size:22px;font-weight:800;color:#34d399;overflow:hidden}
  .avatar img{width:100%;height:100%;object-fit:cover}
  h1{font-size:19px;margin:0}
  .sub{font-size:12px;color:#8b98ad;margin-top:3px}
  .grid{display:grid;gap:10px}
  a.card{display:flex;align-items:center;gap:12px;padding:14px;border-radius:16px;background:#0c1424;border:1px solid rgba(255,255,255,.08);text-decoration:none;color:inherit}
  a.card:active{transform:scale(.99)}
  .ico{width:38px;height:38px;border-radius:11px;background:rgba(52,211,153,.12);display:flex;align-items:center;justify-content:center;font-size:18px}
  .t{font-size:13.5px;font-weight:700}
  .d{font-size:11px;color:#8b98ad;margin-top:2px}
  .foot{margin-top:22px;text-align:center;font-size:10.5px;color:#64748b}
  .foot a{color:#34d399;text-decoration:none}
</style>
</head>
<body>
  <div class="top">
    <div class="avatar">${
      avatarUrl
        ? `<img src="${esc(avatarUrl)}" alt="">`
        : esc((displayName || 'L').slice(0, 1).toUpperCase())
    }</div>
    <div>
      <h1>${name}</h1>
      <div class="sub">${sub}</div>
    </div>
  </div>
  <div class="grid">
    ${cards
      .map(
        (card) => `<a class="card" href="${card.href}">
      <div class="ico">${card.icon}</div>
      <div><div class="t">${card.title}</div><div class="d">${card.desc}</div></div>
    </a>`
      )
      .join('\n    ')}
  </div>
  <div class="foot">
    Add to home screen for one-tap access ·
    <a href="${root}">livocal</a>
  </div>
</body>
</html>`;
}
