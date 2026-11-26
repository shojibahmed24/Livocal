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

function educationCards(items) {
  if (!Array.isArray(items) || items.length === 0) return '';
  return items
    .slice(0, 6)
    .map((item) => {
      const period = `${item.start || ''}${item.start && item.end ? ' – ' : ''}${item.end || ''}`;
      return `<div class="exp"><div class="exp-dot"></div><div class="exp-body">
        <strong>${esc(item.school || '')}</strong>
        ${item.degree ? `<span class="exp-company">${esc(item.degree)}</span>` : ''}
        ${period ? `<span class="exp-when">${esc(period)}</span>` : ''}
      </div></div>`;
    })
    .join('');
}

function certCards(items) {
  if (!Array.isArray(items) || items.length === 0) return '';
  return items
    .slice(0, 8)
    .map(
      (item) => `<div class="cert">
        <strong>${esc(item.name || '')}</strong>
        <span>${esc(item.issuer || '')}${item.year ? ` · ${esc(item.year)}` : ''}</span>
      </div>`
    )
    .join('');
}

function faqCards(items) {
  if (!Array.isArray(items) || items.length === 0) return '';
  return items
    .slice(0, 8)
    .map(
      (item) => `<details class="faq">
        <summary>${esc(item.question || '')}</summary>
        <p>${esc(item.answer || '')}</p>
      </details>`
    )
    .join('');
}

function experienceItems(items) {
  if (!Array.isArray(items) || items.length === 0) return '';
  return items
    .slice(0, 8)
    .map((item) => {
      const period = `${item.start || ''}${item.start && item.end ? ' – ' : ''}${item.end || (item.start ? 'Present' : '')}`;
      return `<div class="exp">
        <div class="exp-dot"></div>
        <div class="exp-body">
          <strong>${esc(item.role || '')}</strong>
          ${item.company ? `<span class="exp-company">${esc(item.company)}</span>` : ''}
          ${period ? `<span class="exp-when">${esc(period)}</span>` : ''}
          ${item.summary ? `<p>${esc(item.summary)}</p>` : ''}
        </div>
      </div>`;
    })
    .join('');
}

function caseCards(items) {
  if (!Array.isArray(items) || items.length === 0) return '';
  return items
    .slice(0, 6)
    .map((item, index) => {
      const tags = String(item.tags || '')
        .split(',')
        .map((tag) => tag.trim())
        .filter(Boolean)
        .slice(0, 5)
        .map((tag) => `<span class="chip">${esc(tag)}</span>`)
        .join('');
      const image = item.imageUrl
        ? `<div class="case-media"><img src="${esc(item.imageUrl)}" alt="${esc(item.title || 'Case study')}" loading="lazy"></div>`
        : '';
      const link = item.url
        ? `<a class="case-link" href="${esc(item.url)}" target="_blank" rel="noopener nofollow">View project →</a>`
        : '';
      return `<article class="case ${index % 2 === 1 ? 'reverse' : ''}">
        <div class="case-body">
          <div class="case-kicker">${esc(item.client || 'Case study')}</div>
          <h3>${esc(item.title || 'Project')}</h3>
          ${item.problem ? `<p><strong>Problem:</strong> ${esc(item.problem)}</p>` : ''}
          ${item.result ? `<p><strong>Result:</strong> ${esc(item.result)}</p>` : ''}
          ${tags ? `<div class="chips">${tags}</div>` : ''}
          ${link}
        </div>
        ${image}
      </article>`;
    })
    .join('');
}

function reviewCards(reviews) {  if (!Array.isArray(reviews) || reviews.length === 0) return '';
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
  const cases = caseCards(p.caseStudies);
  const experience = experienceItems(p.experience);
  const education = educationCards(p.education);
  const certifications = certCards(p.certifications);
  const faqs = faqCards(p.faq);
  const accentHex =
    {
      emerald: '#34d399',
      blue: '#60a5fa',
      violet: '#a78bfa',
      amber: '#fbbf24',
      rose: '#fb7185',
    }[p.accentColor] || '#34d399';
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

  const sections = {
    about: p.bio
      ? `<section class="card" style="margin-top:16px"><h2>About</h2><p>${esc(p.bio)}</p></section>`
      : '',
    experience: experience
      ? `<section class="card" style="margin-top:16px"><h2>Experience</h2><div class="timeline">${experience}</div></section>`
      : '',
    services: services
      ? `<section class="card" style="margin-top:16px"><h2>Services</h2><div class="services">${services}</div></section>`
      : '',
    work: work
      ? `<section class="card" style="margin-top:16px"><h2>Work</h2><div class="work-grid">${work}</div></section>`
      : '',
    cases: cases
      ? `<section class="card" style="margin-top:16px"><h2>Case studies</h2><div class="cases">${cases}</div></section>`
      : '',
    skills: skills
      ? `<section class="card" style="margin-top:16px"><h2>Skills</h2><div class="chips">${skills}</div></section>`
      : '',
    education: education
      ? `<section class="card" style="margin-top:16px"><h2>Education</h2><div class="timeline">${education}</div></section>`
      : '',
    certifications: certifications
      ? `<section class="card" style="margin-top:16px"><h2>Certifications</h2><div class="certs">${certifications}</div></section>`
      : '',
    reviews: reviewList
      ? `<section class="card" style="margin-top:16px"><h2>Recent reviews</h2><div class="reviews">${reviewList}</div></section>`
      : '',
    faq: faqs
      ? `<section class="card" style="margin-top:16px"><h2>FAQ</h2><div class="faqs">${faqs}</div></section>`
      : '',
  };
  const defaultOrder = [
    'about', 'experience', 'services', 'work', 'cases', 'skills',
    'education', 'certifications', 'reviews', 'faq',
  ];
  const order =
    Array.isArray(p.sectionOrder) && p.sectionOrder.length > 0
      ? p.sectionOrder
      : defaultOrder;
  const sectionsHtml = order.map((key) => sections[key] || '').join('');

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
<html lang="en" data-theme="dark" style="--accent:${accentHex}">
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
    --muted: #8fa0b6; --border: rgba(255,255,255,.08); --primary: var(--accent, #34d399);
    --primary-ink: #04120c; --shadow: 0 18px 50px rgba(0,0,0,.35);
  }
  html[data-theme="light"] {
    --bg: #f6f8fb; --card: #ffffff; --card-2: #f1f5f9; --text: #0b1220;
    --muted: #5b6b80; --border: rgba(11,18,32,.08); --primary: var(--accent, #0f9d76);
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
  .certs { display: grid; gap: 8px; grid-template-columns: repeat(auto-fit,minmax(180px,1fr)); }
  .cert { padding: 10px 12px; border-radius: 12px; background: var(--card-2); border: 1px solid var(--border); display: flex; flex-direction: column; gap: 1px; }
  .cert strong { font-size: 12px; }
  .cert span { font-size: 10.5px; color: var(--muted); }
  .faqs { display: grid; gap: 8px; }
  .faq { border: 1px solid var(--border); border-radius: 12px; padding: 10px 12px; background: var(--card-2); }
  .faq summary { cursor: pointer; font-size: 12.5px; font-weight: 700; list-style: none; }
  .faq summary::-webkit-details-marker { display: none; }
  .faq p { margin: 6px 0 0; font-size: 12px; color: var(--muted); }
  .timeline { display: flex; flex-direction: column; gap: 12px; }
  .exp { display: flex; gap: 10px; }
  .exp-dot { width: 9px; height: 9px; border-radius: 50%; background: var(--primary); margin-top: 5px; flex: 0 0 auto; box-shadow: 0 0 0 3px rgba(52,211,153,.15); }
  .exp-body { display: flex; flex-direction: column; gap: 1px; }
  .exp-body strong { font-size: 13px; }
  .exp-company { font-size: 11px; color: var(--muted); }
  .exp-when { font-size: 10.5px; color: var(--primary); font-weight: 700; }
  .exp-body p { margin: 2px 0 0; font-size: 11.5px; color: var(--muted); }
  .cases { display: flex; flex-direction: column; gap: 12px; }
  .case {
    display: grid; grid-template-columns: 1.2fr .8fr; gap: 14px;
    background: var(--card-2); border: 1px solid var(--border);
    border-radius: 14px; overflow: hidden;
  }
  .case.reverse { grid-template-columns: .8fr 1.2fr; }
  .case.reverse .case-body { order: 2; }
  .case.reverse .case-media { order: 1; }
  .case-body { padding: 14px; display: flex; flex-direction: column; gap: 6px; }
  .case-kicker { font-size: 10px; letter-spacing: .08em; text-transform: uppercase; color: var(--primary); font-weight: 800; }
  .case-body h3 { margin: 0; font-size: 16px; }
  .case-body p { margin: 0; font-size: 12px; color: var(--muted); }
  .case-body strong { color: var(--text); }
  .case-media { min-height: 130px; }
  .case-media img { width: 100%; height: 100%; object-fit: cover; display: block; }
  .case-link { font-size: 12px; font-weight: 700; margin-top: 2px; }
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
    .case, .case.reverse { grid-template-columns: 1fr; }
    .case.reverse .case-body { order: 1; }
    .case.reverse .case-media { order: 2; }
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
        <a class="btn btn-ghost" href="/cv/${esc(username)}">View CV</a>
        ${socials}
      </div>
    </div>
  </header>

  <main>
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

    ${sectionsHtml}
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



export function renderCvPage({ profile, username }) {
  const p = profile || {};
  const name = p.displayName || 'Freelancer';
  const rate = rateLine(p.rate);
  const skills = (Array.isArray(p.skills) ? p.skills : []).join(' · ');
  const languages = (Array.isArray(p.languages) ? p.languages : [])
    .map((l) => `${l.code || l}${l.level ? ` (${l.level})` : ''}`)
    .join(' · ');

  const block = (title, body) =>
    body
      ? `<section><h2>${esc(title)}</h2>${body}</section>`
      : '';

  const experienceHtml = (Array.isArray(p.experience) ? p.experience : [])
    .map((item) => `<div class="row">
      <div><strong>${esc(item.role || '')}</strong>${item.company ? ` — ${esc(item.company)}` : ''}</div>
      <div class="when">${esc(item.start || '')}${item.start && item.end ? ' – ' : ''}${esc(item.end || (item.start ? 'Present' : ''))}</div>
      ${item.summary ? `<p>${esc(item.summary)}</p>` : ''}
    </div>`)
    .join('');

  const educationHtml = (Array.isArray(p.education) ? p.education : [])
    .map((item) => `<div class="row">
      <div><strong>${esc(item.school || '')}</strong>${item.degree ? ` — ${esc(item.degree)}` : ''}</div>
      <div class="when">${esc(item.start || '')}${item.start && item.end ? ' – ' : ''}${esc(item.end || '')}</div>
    </div>`)
    .join('');

  const certHtml = (Array.isArray(p.certifications) ? p.certifications : [])
    .map((item) => `<li>${esc(item.name || '')}${item.issuer ? ` — ${esc(item.issuer)}` : ''}${item.year ? ` (${esc(item.year)})` : ''}</li>`)
    .join('');

  const workHtml = (Array.isArray(p.caseStudies) ? p.caseStudies : [])
    .map((item) => `<div class="row">
      <div><strong>${esc(item.title || '')}</strong>${item.client ? ` — ${esc(item.client)}` : ''}</div>
      ${item.result ? `<p>${esc(item.result)}</p>` : ''}
    </div>`)
    .join('');

  const links = (Array.isArray(p.portfolio) ? p.portfolio : [])
    .map((item) => `${esc(item.label || '')}${item.url ? ` — ${esc(item.url)}` : ''}`)
    .join('<br>');

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${esc(name)} — CV</title>
<style>
  *{box-sizing:border-box}
  body{margin:0;background:#eef2f7;color:#0b1220;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Noto Sans Bengali',sans-serif;line-height:1.55}
  .sheet{max-width:820px;margin:24px auto;background:#fff;border-radius:14px;padding:36px;box-shadow:0 12px 40px rgba(15,40,70,.12)}
  header{display:flex;justify-content:space-between;gap:16px;align-items:flex-start;border-bottom:2px solid #0f766e;padding-bottom:14px}
  h1{font-size:30px;margin:0;letter-spacing:-.5px}
  .headline{color:#0f766e;font-weight:700;font-size:13px;margin:2px 0 0}
  .meta{color:#64748b;font-size:11.5px;text-align:right}
  section{margin-top:18px}
  h2{font-size:10px;letter-spacing:.12em;text-transform:uppercase;color:#0f766e;margin:0 0 8px;border-bottom:1px solid #e2e8f0;padding-bottom:4px}
  p{margin:4px 0 0;font-size:12px}
  .row{margin-bottom:10px}
  .row strong{font-size:13px}
  .when{color:#64748b;font-size:11px}
  ul{margin:0;padding-left:16px;font-size:12px}
  .skills{font-size:12px}
  .actions{display:flex;gap:10px;margin-bottom:8px}
  .btn{border:0;background:#0f9d76;color:#fff;border-radius:10px;padding:10px 16px;font-weight:800;font-size:12.5px;cursor:pointer;text-decoration:none}
  footer{margin-top:22px;text-align:center;color:#94a3b8;font-size:10.5px}
  @media(max-width:600px){.sheet{margin:10px;padding:20px}header{flex-direction:column}.meta{text-align:left}h1{font-size:24px}}
  @media print{body{background:#fff}.sheet{box-shadow:none;margin:0;border-radius:0;padding:0}.actions{display:none}}
</style>
</head>
<body>
<div class="sheet">
  <div class="actions">
    <button class="btn" onclick="window.print()">Print / Save PDF</button>
    <a class="btn" style="background:#0b1220" href="/u/${esc(username)}">View profile</a>
  </div>
  <header>
    <div>
      <h1>${esc(name)}</h1>
      <p class="headline">${esc(p.headline || '')}</p>
    </div>
    <div class="meta">
      ${esc(`livocal.app/u/${username}`)}<br>
      ${rate ? `${esc(rate)}<br>` : ''}
      ${p.githubUrl ? `${esc(p.githubUrl)}<br>` : ''}
      ${p.linkedinUrl ? `${esc(p.linkedinUrl)}<br>` : ''}
      ${p.websiteUrl ? esc(p.websiteUrl) : ''}
    </div>
  </header>

  ${block('Summary', p.bio ? `<p>${esc(p.bio)}</p>` : '')}
  ${block('Skills', skills ? `<p class="skills">${esc(skills)}</p>` : '')}
  ${block('Experience', experienceHtml)}
  ${block('Education', educationHtml)}
  ${block('Certifications', certHtml ? `<ul>${certHtml}</ul>` : '')}
  ${block('Selected work', workHtml)}
  ${block('Links', links ? `<p>${links}</p>` : '')}
  ${block('Languages', languages ? `<p>${esc(languages)}</p>` : '')}

  <footer>Generated from Livocal · livocal.app/u/${esc(username)}</footer>
</div>
</body>
</html>`;
}