'use strict';

/**
 * Public freelancer portfolio page (server-rendered).
 * No client framework; theme toggle is the only JS.
 */

export function esc(value) {
  return String(value == null ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function initial(name) {
  const trimmed = String(name || '').trim();
  if (!trimmed) return 'L';
  return Array.from(trimmed)[0].toUpperCase();
}

function rateLine(rate) {
  if (!rate || !(Number(rate.amount) > 0)) return '';
  const basis = rate.basis === 'project' ? 'project' : 'hour';
  return `${esc(rate.currency || 'USD')} ${esc(rate.amount)} / ${basis}`;
}

function portfolioCards(items) {
  if (!Array.isArray(items) || items.length === 0) return '';
  return items
    .map((item, index) => {
      const label = esc(item.label || 'Project');
      const url = esc(item.url || '#');
      const image = esc(item.imageUrl || '');
      const hue = (index * 47 + 160) % 360;
      const thumb = image
        ? `<img src="${image}" alt="${label}" loading="lazy">`
        : `<div class="thumb-fallback" style="--hue:${hue}">${esc(
            Array.from(String(item.label || 'P'))[0].toUpperCase()
          )}</div>`;
      return `<a class="work-card" href="${url}" target="_blank" rel="noopener nofollow">
        <div class="work-thumb">${thumb}</div>
        <div class="work-body"><strong>${label}</strong><span>View project →</span></div>
      </a>`;
    })
    .join('');
}

function serviceCards(services, rate) {
  if (Array.isArray(services) && services.length > 0) {
    return services
      .slice(0, 6)
      .map(
        (service) => `<div class="service">
          <strong>${esc(service.title || 'Service')}</strong>
          ${Number(service.from) > 0 ? `<span>from ${esc(rate?.currency || 'USD')} ${esc(service.from)}</span>` : ''}
        </div>`
      )
      .join('');
  }
  const line = rateLine(rate);
  if (!line) return '';
  return `<div class="service"><strong>Custom project</strong><span>${line}</span></div>`;
}

function reviewCards(reviews) {
  if (!Array.isArray(reviews) || reviews.length === 0) return '';
  return reviews
    .map((review) => {
      const stars = '★'.repeat(Math.max(1, Math.min(5, Number(review.rating) || 5)));
      return `<figure class="review">
        <div class="stars">${stars}</div>
        ${review.comment ? `<blockquote>${esc(review.comment)}</blockquote>` : ''}
        <figcaption>— ${esc(review.name || 'Client')}</figcaption>
      </figure>`;
    })
    .join('');
}

function nextAvailability(days) {
  if (!Array.isArray(days) || days.length === 0) return '';
  const first = days[0];
  const slot = first.slots[0];
  if (!slot) return '';
  const time = String(slot.start || '').slice(0, 5);
  const end = String(slot.end || '').slice(0, 5);
  return `<div class="next-open"><span class="dot"></span> Next open: <strong>${esc(
    first.label
  )}</strong>, ${esc(time)}–${esc(end)}</div>`;
}

export function renderProfilePage({ profile, username, days, reviews }) {
  const p = profile || {};
  const name = p.displayName || 'Freelancer';
  const headline = p.headline || 'Freelancer on Livocal';
  const ratingCount = Number(p.ratingCount || 0);
  const ratingAvg = Number(p.ratingAvg || 0);
  const verified = p.published === true && ratingCount > 0;
  const rate = rateLine(p.rate);
  const skills = (Array.isArray(p.skills) ? p.skills : [])
    .slice(0, 12)
    .map((skill) => `<span class="chip">${esc(skill)}</span>`)
    .join('');
  const languages = (Array.isArray(p.languages) ? p.languages : [])
    .map(
      (lang) =>
        `<span class="chip">${esc(lang.code || lang)}${lang.level ? ` · ${esc(lang.level)}` : ''}</span>`
    )
    .join('');
  const services = serviceCards(p.services, p.rate);
  const work = portfolioCards(p.portfolio);
  const reviewList = reviewCards(reviews);
  const availability = nextAvailability(days);
  const bookingUrl = `/book/${encodeURIComponent(username)}`;
  const avatar = p.avatarUrl
    ? `<img class="avatar" src="${esc(p.avatarUrl)}" alt="${esc(name)}">`
    : `<div class="avatar avatar-fallback">${esc(initial(name))}</div>`;

  const responsePill = p.responseTime
    ? `<span class="pill neutral">⏱ ${esc(p.responseTime)}</span>`
    : '';

  const stats = [
    [p.projectsDone, 'projects'],
    [p.yearsExperience, 'years'],
    [p.clientsCount, 'clients'],
  ]
    .filter((row) => Number(row[0]) > 0)
    .map(
      (row) =>
        `<div class="stat"><strong>${esc(row[0])}+</strong><span>${row[1]}</span></div>`
    )
    .join('');

  const socials = [
    p.githubUrl
      ? `<a class="social" href="${esc(p.githubUrl)}" target="_blank" rel="noopener nofollow">GitHub</a>`
      : '',
    p.linkedinUrl
      ? `<a class="social" href="${esc(p.linkedinUrl)}" target="_blank" rel="noopener nofollow">LinkedIn</a>`
      : '',
    p.websiteUrl
      ? `<a class="social" href="${esc(p.websiteUrl)}" target="_blank" rel="noopener nofollow">Website</a>`
      : '',
    p.cvUrl
      ? `<a class="social social-cv" href="${esc(p.cvUrl)}" target="_blank" rel="noopener nofollow">Download CV</a>`
      : '',
  ]
    .filter(Boolean)
    .join('');

  const heroStyle = p.coverUrl
    ? ` style="background-image:linear-gradient(rgba(4,7,13,.72),var(--card)),url('${esc(p.coverUrl)}');background-size:cover;background-position:center;"`
    : '';

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Person',
    name,
    jobTitle: p.headline || undefined,
    description: p.bio || undefined,
    image: p.avatarUrl || undefined,
    sameAs: [p.githubUrl, p.linkedinUrl, p.websiteUrl].filter(Boolean),
    knowsLanguage: (Array.isArray(p.languages) ? p.languages : []).map(
      (item) => item.code || item
    ),
    makesOffer: rate
      ? {
          '@type': 'Offer',
          priceCurrency: p.rate?.currency || 'USD',
          price: p.rate?.amount || undefined,
        }
      : undefined,
  };

  return `<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${esc(name)} — ${esc(headline)}</title>
<meta name="description" content="${esc(p.bio || headline)}">
<link rel="canonical" href="/u/${esc(username)}">
<meta property="og:type" content="profile">
<meta property="og:title" content="${esc(name)} — ${esc(headline)}">
<meta property="og:description" content="${esc(p.bio || headline)}">
<meta property="og:url" content="/u/${esc(username)}">
${p.avatarUrl ? `<meta property="og:image" content="${esc(p.avatarUrl)}">` : ''}
<meta name="twitter:card" content="summary">
<script type="application/ld+json">${JSON.stringify(jsonLd)}</script>
<script>
  try {
    var saved = localStorage.getItem('livocal-theme');
    if (saved === 'light' || saved === 'dark') {
      document.documentElement.setAttribute('data-theme', saved);
    }
  } catch (e) {}
</script>
<style>
  :root {
    --bg: #04070d; --card: #0b1422; --card-2: #0f1b2d; --text: #f2f6fb;
    --muted: #8fa0b6; --border: rgba(255,255,255,.08); --primary: #34d399;
    --primary-ink: #04120c; --shadow: 0 18px 50px rgba(0,0,0,.35);
  }
  html[data-theme="light"] {
    --bg: #f6f8fb; --card: #ffffff; --card-2: #f1f5f9; --text: #0b1220;
    --muted: #5b6b80; --border: rgba(11,18,32,.08); --primary: #0f9d76;
    --primary-ink: #ffffff; --shadow: 0 18px 50px rgba(15,40,70,.10);
  }
  * { box-sizing: border-box; }
  body {
    margin: 0; background: var(--bg); color: var(--text);
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Noto Sans Bengali', sans-serif;
    line-height: 1.6; -webkit-font-smoothing: antialiased;
  }
  a { color: var(--primary); }
  .wrap { max-width: 880px; margin: 0 auto; padding: 22px 18px 56px; }
  .topbar { display: flex; justify-content: flex-end; gap: 10px; }
  .theme-btn {
    border: 1px solid var(--border); background: var(--card); color: var(--text);
    border-radius: 999px; padding: 7px 14px; font-size: 12px; cursor: pointer;
  }
  .hero {
    margin-top: 14px; background: var(--card); border: 1px solid var(--border);
    border-radius: 24px; padding: 26px; box-shadow: var(--shadow);
    display: flex; gap: 22px; align-items: center;
  }
  .avatar {
    width: 96px; height: 96px; border-radius: 24px; object-fit: cover;
    border: 1px solid var(--border); flex: 0 0 auto;
  }
  .avatar-fallback {
    display: flex; align-items: center; justify-content: center;
    font-size: 38px; font-weight: 800; color: var(--primary-ink);
    background: linear-gradient(135deg, #34d399, #10b981);
  }
  h1 { font-size: 30px; margin: 0 0 4px; letter-spacing: -0.4px; }
  .headline { color: var(--muted); margin: 0; font-size: 14.5px; }
  .meta { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 10px; align-items: center; }
  .pill {
    display: inline-flex; align-items: center; gap: 4px; padding: 4px 10px;
    border-radius: 999px; font-size: 11px; font-weight: 700;
    color: var(--primary); background: rgba(52,211,153,.12);
    border: 1px solid rgba(52,211,153,.28);
  }
  .pill.neutral { color: var(--muted); background: var(--card-2); border-color: var(--border); }
  .cta-row { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 16px; align-items: center; }
  .stats { display: flex; flex-wrap: wrap; gap: 18px; margin-top: 14px; }
  .stat { display: flex; flex-direction: column; }
  .stat strong { font-size: 18px; color: var(--text); letter-spacing: -0.3px; }
  .stat span { font-size: 10.5px; text-transform: uppercase; letter-spacing: .08em; color: var(--muted); }
  .social {
    display: inline-flex; align-items: center; padding: 9px 13px; border-radius: 10px;
    border: 1px solid var(--border); background: transparent; color: var(--text);
    font-size: 12px; font-weight: 700; text-decoration: none;
  }
  .social:hover { border-color: var(--primary); color: var(--primary); }
  .social-cv { background: var(--primary); color: var(--primary-ink); border-color: var(--primary); }
  .btn {
    display: inline-flex; align-items: center; justify-content: center;
    gap: 8px; padding: 12px 18px; border-radius: 12px; font-weight: 800;
    font-size: 13.5px; text-decoration: none; border: 1px solid transparent;
  }
  .btn-primary { background: var(--primary); color: var(--primary-ink); }
  .btn-ghost { border-color: var(--border); color: var(--text); background: var(--card-2); }
  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-top: 18px; }
  .card { background: var(--card); border: 1px solid var(--border); border-radius: 18px; padding: 18px; }
  .card h2 {
    font-size: 11px; letter-spacing: .09em; text-transform: uppercase;
    color: var(--muted); margin: 0 0 10px; font-weight: 800;
  }
  .card p { margin: 0; font-size: 13.5px; }
  .chips { display: flex; flex-wrap: wrap; gap: 7px; }
  .chip {
    padding: 5px 10px; border-radius: 999px; font-size: 12px;
    background: var(--card-2); border: 1px solid var(--border);
  }
  .rate { font-size: 26px; font-weight: 800; color: var(--primary); }
  .next-open { margin-top: 8px; font-size: 12px; color: var(--muted); }
  .dot { display: inline-block; width: 7px; height: 7px; border-radius: 50%; background: var(--primary); margin-right: 6px; }
  .services { display: grid; grid-template-columns: repeat(auto-fit,minmax(170px,1fr)); gap: 10px; }
  .service {
    padding: 12px; border-radius: 12px; background: var(--card-2);
    border: 1px solid var(--border); display: flex; flex-direction: column; gap: 3px;
  }
  .service span { font-size: 11.5px; color: var(--muted); }
  .work-grid { display: grid; grid-template-columns: repeat(auto-fit,minmax(200px,1fr)); gap: 12px; }
  .work-card {
    text-decoration: none; color: var(--text); border: 1px solid var(--border);
    border-radius: 14px; overflow: hidden; background: var(--card-2);
  }
  .work-thumb { height: 118px; overflow: hidden; }
  .work-thumb img { width: 100%; height: 100%; object-fit: cover; display: block; }
  .thumb-fallback {
    height: 100%; display: flex; align-items: center; justify-content: center;
    font-size: 34px; font-weight: 800; color: var(--primary-ink);
    background: linear-gradient(135deg, hsl(var(--hue) 70% 62%), hsl(calc(var(--hue) + 40) 70% 45%));
  }
  .work-body { padding: 10px 12px; display: flex; flex-direction: column; gap: 2px; }
  .work-body strong { font-size: 13px; }
  .work-body span { font-size: 11px; color: var(--muted); }
  .reviews { display: grid; gap: 10px; }
  .review { margin: 0; padding: 12px; border-radius: 12px; background: var(--card-2); border: 1px solid var(--border); }
  .review .stars { color: #fbbf24; font-size: 13px; letter-spacing: 1px; }
  .review blockquote { margin: 6px 0 4px; font-size: 12.5px; }
  .review figcaption { font-size: 11px; color: var(--muted); }
  footer { margin-top: 26px; text-align: center; color: var(--muted); font-size: 11.5px; }
  @media (max-width: 640px) {
    .hero { flex-direction: column; text-align: center; padding: 22px 18px; }
    .meta { justify-content: center; }
    .cta-row { justify-content: center; }
    .grid { grid-template-columns: 1fr; }
    h1 { font-size: 25px; }
  }
</style>
</head>
<body>
<div class="wrap">
  <div class="topbar">
    <button class="theme-btn" id="themeToggle" type="button">◐ Theme</button>
  </div>

  <header class="hero"${heroStyle}>
    ${avatar}
    <div>
      <h1>${esc(name)}</h1>
      <p class="headline">${esc(headline)}</p>
      <div class="meta">
        ${verified ? '<span class="pill">✓ Verified</span>' : ''}
        ${ratingCount > 0 ? `<span class="pill neutral">★ ${ratingAvg.toFixed(1)} · ${ratingCount}</span>` : ''}
        ${languages ? `<span class="pill neutral">${languages.split('</span>').length - 1} languages</span>` : ''}
        ${responsePill}
      </div>
      ${stats ? `<div class="stats">${stats}</div>` : ''}
      <div class="cta-row">
        <a class="btn btn-primary" href="${bookingUrl}">Book a call</a>
        <button class="btn btn-ghost" id="shareBtn" type="button">Share profile</button>
        ${socials}
      </div>
    </div>
  </header>

  <main>
    ${p.bio ? `<section class="card" style="margin-top:16px"><h2>About</h2><p>${esc(p.bio)}</p></section>` : ''}

    ${services ? `<section class="card" style="margin-top:16px"><h2>Services</h2><div class="services">${services}</div></section>` : ''}

    <div class="grid">
      <section class="card">
        <h2>Rate</h2>
        <div class="rate">${rate || 'Ask for a quote'}</div>
        ${availability}
      </section>
      <section class="card">
        <h2>Languages</h2>
        <div class="chips">${languages || '<span class="chip">English</span>'}</div>
      </section>
    </div>

    ${work ? `<section class="card" style="margin-top:16px"><h2>Work</h2><div class="work-grid">${work}</div></section>` : ''}

    ${skills ? `<section class="card" style="margin-top:16px"><h2>Skills</h2><div class="chips">${skills}</div></section>` : ''}

    ${reviewList ? `<section class="card" style="margin-top:16px"><h2>Recent reviews</h2><div class="reviews">${reviewList}</div></section>` : ''}
  </main>

  <footer>Powered by Livocal · live voice translation for freelancers</footer>
</div>
<script>
  document.getElementById('themeToggle').addEventListener('click', function () {
    var root = document.documentElement;
    var next = root.getAttribute('data-theme') === 'light' ? 'dark' : 'light';
    root.setAttribute('data-theme', next);
    try { localStorage.setItem('livocal-theme', next); } catch (e) {}
  });
  document.getElementById('shareBtn').addEventListener('click', async function () {
    var data = { title: ${JSON.stringify(name)}, text: ${JSON.stringify(headline)}, url: location.href };
    try {
      if (navigator.share) { await navigator.share(data); return; }
      await navigator.clipboard.writeText(location.href);
      this.textContent = 'Link copied';
    } catch (e) {}
  });
</script>
</body>
</html>`;
}


