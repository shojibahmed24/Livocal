'use strict';

import COPY, { LANGUAGES, RTL_LANGUAGES, pathFor } from './i18n/index.js';

/** Marketing landing page for https://livocal.app (no framework, no build). */

function esc(value) {
  return String(value == null ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/** Languages offered in the hero demo. Any pair works — the model does the rest. */
const DEMO_LANGS = [
  ['auto', 'Auto-detect'],
  ['bn', 'বাংলা'],
  ['en', 'English'],
  ['hi', 'हिन्दी'],
  ['ur', 'اردو'],
  ['ar', 'العربية'],
  ['es', 'Español'],
  ['fr', 'Français'],
  ['de', 'Deutsch'],
  ['pt', 'Português'],
  ['it', 'Italiano'],
  ['ru', 'Русский'],
  ['tr', 'Türkçe'],
  ['zh', '中文'],
  ['ja', '日本語'],
  ['ko', '한국어'],
  ['id', 'Indonesia'],
  ['vi', 'Tiếng Việt'],
  ['th', 'ไทย'],
  ['ta', 'தமிழ்'],
  ['te', 'తెలుగు'],
  ['fil', 'Filipino'],
  ['sw', 'Kiswahili'],
  ['fa', 'فارسی'],
  ['nl', 'Nederlands'],
  ['pl', 'Polski'],
];

const ICONS = {  mic: '<path d="M12 3a3 3 0 0 0-3 3v6a3 3 0 0 0 6 0V6a3 3 0 0 0-3-3z"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>',
  user: '<circle cx="12" cy="8" r="3.5"/><path d="M5 20a7 7 0 0 1 14 0"/>',
  calendar:
    '<rect x="3.5" y="5" width="17" height="15" rx="2.5"/><path d="M8 3v4M16 3v4M3.5 10h17"/>',
  receipt:
    '<path d="M6 3h12v18l-3-2-3 2-3-2-3 2z"/><path d="M9 8h6M9 12h6"/>',
  spark:
    '<path d="M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9z"/>',
  doc: '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5M9 13h6M9 17h4"/>',
  check: '<path d="M4 12.5l5 5L20 6.5"/>',
  arrow: '<path d="M5 12h14M13 6l6 6-6 6"/>',
};

function icon(name, cls = 'ico') {
  return `<svg class="${cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICONS[name] || ''}</svg>`;
}

const A11Y = {
  en: { skip: 'Skip to content', demo: 'Bangla sentence', contact: 'Email or phone' },
  bn: { skip: 'মূল কনটেন্টে যান', demo: 'বাংলা বাক্য', contact: 'ইমেইল বা ফোন' },
  hi: { skip: 'मुख्य सामग्री पर जाएँ', demo: 'बांग्ला वाक्य', contact: 'ईमेल या फ़ोन' },
  ar: { skip: 'انتقل إلى المحتوى', demo: 'جملة بنغالية', contact: 'البريد أو الهاتف' },
  es: { skip: 'Ir al contenido', demo: 'Frase en bengalí', contact: 'Correo o teléfono' },
  fr: { skip: 'Aller au contenu', demo: 'Phrase en bengali', contact: 'E-mail ou téléphone' },
  de: { skip: 'Zum Inhalt springen', demo: 'Bengalischer Satz', contact: 'E-Mail oder Telefon' },
};

// ── Renderer ────────────────────────────────────────────────────────────────
export function renderLanding({ lang, origin }) {
  const language = LANGUAGES.includes(lang) ? lang : 'en';
  const c = COPY[language];
  const dir = RTL_LANGUAGES.includes(language) ? 'rtl' : 'ltr';
  const a11y = A11Y[language] || A11Y.en;
  const base = origin || 'https://livocal.app';
  const canonical = `${base}${pathFor(language)}`;
  const sampleUser = 'shojibahmed';

  const jsonLd = [
    {
      '@context': 'https://schema.org',
      '@type': 'Organization',
      name: 'Livocal',
      url: base,
      logo: `${base}/site/logo.svg`,
      sameAs: [`${base}/u/${sampleUser}`],
    },
    {
      '@context': 'https://schema.org',
      '@type': 'SoftwareApplication',
      name: 'Livocal',
      applicationCategory: 'BusinessApplication',
      operatingSystem: 'Android',
      description: c.hero.sub,
      offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
      url: base,
    },
    {
      '@context': 'https://schema.org',
      '@type': 'FAQPage',
      mainEntity: c.faq.items.map((item) => ({
        '@type': 'Question',
        name: item.q,
        acceptedAnswer: { '@type': 'Answer', text: item.a },
      })),
    },
  ];

  const trustItems = c.trust
    .map((item) => `<span class="marquee__item">${esc(item)}</span>`)
    .join('');

  const problemCards = c.problem.items
    .map(
      (item, index) => `
      <article class="card problem__card reveal" data-delay="${index * 70}">
        <span class="problem__index">0${index + 1}</span>
        <h3>${esc(item.t)}</h3>
        <p>${esc(item.b)}</p>
      </article>`
    )
    .join('');

  const featureCards = c.features.items
    .map(
      (item, index) => `
      <article class="card feature reveal" data-delay="${index * 60}">
        <span class="feature__icon">${icon(item.i)}</span>
        <h3>${esc(item.t)}</h3>
        <p>${esc(item.b)}</p>
      </article>`
    )
    .join('');

  const steps = c.how.steps
    .map(
      (step, index) => `
      <li class="step reveal" data-delay="${index * 90}">
        <span class="step__num">${index + 1}</span>
        <div>
          <h3>${esc(step.t)}</h3>
          <p>${esc(step.b)}</p>
        </div>
      </li>`
    )
    .join('');

  const stats = c.proof.stats
    .map(
      (stat) => `
      <div class="stat">
        <strong class="stat__value">${esc(stat.v)}</strong>
        <span class="stat__label">${esc(stat.l)}</span>
      </div>`
    )
    .join('');

  const plans = c.pricing.plans
    .map(
      (plan, index) => `
      <article class="card plan ${index === 1 ? 'plan--accent' : ''} reveal" data-delay="${index * 80}">
        <span class="pill">${esc(plan.badge)}</span>
        <h3>${esc(plan.name)}</h3>
        <p class="plan__price"><strong>${esc(plan.price)}</strong><span>${esc(plan.period)}</span></p>
        <ul class="plan__features">
          ${plan.features
            .map((f) => `<li>${icon('check', 'ico ico--check')}${esc(f)}</li>`)
            .join('')}
        </ul>
        <a class="btn ${index === 1 ? 'btn--primary' : 'btn--ghost'}" href="#access">${esc(plan.cta)}</a>
      </article>`
    )
    .join('');

  const faqItems = c.faq.items
    .map(
      (item, index) => `
      <details class="faq__item reveal" data-delay="${index * 40}">
        <summary>${esc(item.q)}${icon('arrow', 'ico faq__arrow')}</summary>
        <p>${esc(item.a)}</p>
      </details>`
    )
    .join('');

  const tour = c.tour;
  const tourSection = `
  <section class="section" id="tour">
    <div class="wrap">
      <header class="section__head reveal">
        <span class="kicker"><i>04</i> ${esc(tour.kicker)}</span>
        <h2>${esc(tour.title)}</h2>
        <p>${esc(tour.sub)}</p>
      </header>
      <div class="tour reveal" id="tourWidget">
        <div class="tour__frame">
          <div class="tour__bar"><i></i><i></i><i></i><em>livocal.app</em></div>
          <div class="tour__stage">
            <article class="tour__slide is-active">
              <div class="call">
                <div class="call__head">
                  <span class="call__avatar">S</span>
                  <div class="call__who">
                    <strong>${esc(tour.callName)}</strong>
                    <span><b class="call__dot"></b>${esc(tour.callStatus)}</span>
                  </div>
                  <span class="call__tag">${esc(tour.callTag)}</span>
                </div>
                <div class="call__body">
                  <div class="bubble bubble--in">${esc(tour.callLine1)}</div>
                  <div class="bubble bubble--out">
                    ${esc(tour.callLine2)}
                    <small>${esc(tour.callTranslation)}</small>
                  </div>
                </div>
                <div class="call__wave">
                  ${Array.from({ length: 16 })
                    .map((_, i) => `<span style="--i:${i}"></span>`)
                    .join('')}
                </div>
              </div>
            </article>

            <article class="tour__slide">
              <div class="book">
                <div class="book__head">
                  <strong>${esc(tour.bookTitle)}</strong>
                  <span>${esc(tour.bookDay)}</span>
                </div>
                <div class="book__slots">
                  ${tour.bookSlots
                    .map(
                      (slot, i) =>
                        `<span class="book__slot ${
                          i === tour.bookSlots.length - 1 ? 'is-on' : ''
                        }">${esc(slot)}</span>`
                    )
                    .join('')}
                </div>
                <div class="book__cta">${esc(tour.bookConfirm)}</div>
                <div class="book__done">✓ ${esc(tour.bookDone)}</div>
              </div>
            </article>

            <article class="tour__slide">
              <div class="inv">
                <div class="inv__head">
                  <strong>${esc(tour.invTitle)}</strong>
                  <span class="inv__status">${esc(tour.invStatus)}</span>
                </div>
                ${tour.invRows
                  .map(
                    (row) =>
                      `<div class="inv__row"><span>${esc(
                        row[0]
                      )}</span><b>$${esc(row[1])}</b></div>`
                  )
                  .join('')}
                <div class="inv__total"><span>Total</span><b>$${esc(
                  tour.invTotal
                )}</b></div>
                <div class="inv__link">${esc(tour.invLink)}</div>
              </div>
            </article>
          </div>
        </div>
        <div class="tour__tabs" role="tablist">
          ${tour.tabs
            .map(
              (tab, i) =>
                `<button class="tour__tab ${
                  i === 0 ? 'is-on' : ''
                }" data-tab="${i}" role="tab" aria-selected="${
                  i === 0
                }" type="button">${esc(tab)}</button>`
            )
            .join('')}
        </div>
      </div>
    </div>
  </section>
`;

  return `<!DOCTYPE html>
<html lang="${language}" dir="${dir}" class="no-js">
<head>
<meta charset="UTF-8">
<script>document.documentElement.className = 'js';</script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Livocal — ${esc(c.hero.title1)} ${esc(c.hero.title2)}</title>
<meta name="description" content="${esc(c.hero.sub)}">
<link rel="canonical" href="${canonical}">
${LANGUAGES.map(
  (code) =>
    `<link rel="alternate" hreflang="${code}" href="${base}${pathFor(code)}">`
).join('\n')}
<link rel="alternate" hreflang="x-default" href="${base}/">
<meta name="theme-color" content="#04070D">
<meta property="og:type" content="website">
<meta property="og:site_name" content="Livocal">
<meta property="og:title" content="${esc(c.hero.title1)} ${esc(c.hero.title2)}">
<meta property="og:description" content="${esc(c.hero.sub)}">
<meta property="og:url" content="${canonical}">
<meta property="og:image" content="${base}/static/og-image.png">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:image" content="${base}/static/og-image.png">
<link rel="icon" href="/static/icon-192.png" type="image/png">
<link rel="apple-touch-icon" href="/static/icon-192.png">
<link rel="preload" href="/site/fonts/sora-latin.woff2" as="font" type="font/woff2" crossorigin>
${language === 'bn' ? '<link rel="preload" href="/site/fonts/noto-bengali.woff2" as="font" type="font/woff2" crossorigin>' : ''}
<link rel="manifest" href="/manifest.webmanifest">
<style>:root{--bg:#04070D;--surface:#0B1422;--surface-2:#0F1B2D;--text:#F2F6FB;--muted:#8FA0B6;--accent:#34D399;--accent-ink:#04120C;--accent-2:#6366F1;--border:rgba(255,255,255,.08);--radius:18px;--ease:cubic-bezier(.2,.8,.2,1)}*{box-sizing:border-box}html{-webkit-text-size-adjust:100%;scroll-behavior:smooth}body{margin:0;background:var(--bg);color:var(--text);font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Noto Sans Bengali',sans-serif;line-height:1.6;overflow-x:hidden}a{color:inherit}</style>
<link rel="stylesheet" href="/site/landing.css?v=7">
<script type="application/ld+json">${JSON.stringify(jsonLd)}</script>
</head>
<body data-lang="${language}">
<div class="progress" id="progress" aria-hidden="true"></div>
<a class="skip" href="#main">${esc(a11y.skip)}</a>

<header class="nav" id="nav">
  <div class="wrap nav__inner">
    <a class="brand" href="/" aria-label="Livocal">
      <img src="/site/logo.svg" alt="" width="34" height="34">
      <span>Livocal</span>
    </a>
    <nav class="nav__links" aria-label="Primary">
      <a href="#features">${esc(c.nav.features)}</a>
      <a href="#how">${esc(c.nav.how)}</a>
      <a href="#pricing">${esc(c.nav.pricing)}</a>
      <a href="#faq">${esc(c.nav.faq)}</a>
    </nav>
    <div class="nav__actions">
      <label class="sr-only" for="langSelect">Language</label>
      <select class="lang-select" id="langSelect" data-current="${language}">
        ${LANGUAGES.map((code) => `<option value="${code}"${code === language ? ' selected' : ''}>${esc(COPY[code].label)}</option>`).join('')}
      </select>
      <a class="btn btn--primary btn--sm" href="#access">${esc(c.nav.cta)}</a>
    </div>
  </div>
</header>

<main id="main">
  <section class="hero">
    <div class="hero__glow" aria-hidden="true"></div>
    <div class="wrap hero__grid">
      <div class="hero__copy">
        <span class="eyebrow reveal">${esc(c.hero.eyebrow)}</span>
        <h1 class="hero__title">
          <span class="reveal" data-delay="60">${esc(c.hero.title1)}</span>
          <span class="reveal hero__title--accent" data-delay="140">${esc(c.hero.title2)}</span>
        </h1>
        <p class="hero__sub reveal" data-delay="240">${esc(c.hero.sub)}</p>
        <div class="hero__cta reveal" data-delay="320">
          <a class="btn btn--primary" href="#access">${esc(c.hero.cta1)}</a>
          <a class="btn btn--ghost" href="#demo">${esc(c.hero.cta2)}</a>
        </div>
        <p class="hero__micro reveal" data-delay="380">${esc(c.hero.micro)}</p>
      </div>

      <div class="demo reveal" id="demo" data-delay="260">
        <div class="demo__head">
          <span class="dot" aria-hidden="true"></span>
          <strong>${esc(c.hero.demoTitle)}</strong>
          <span class="demo__badge">LIVE</span>
        </div>
        <p class="demo__hint">${esc(c.hero.demoHint)}</p>
        <div class="demo__langs">
          <label class="sr-only" for="demoFrom">${esc(a11y.demo)}</label>
          <select id="demoFrom" aria-label="From">
            ${DEMO_LANGS.map(
              ([code, name]) =>
                `<option value="${code}"${
                  code === (language === 'bn' ? 'bn' : 'auto') ? ' selected' : ''
                }>${esc(name)}</option>`
            ).join('')}
          </select>
          <span aria-hidden="true">→</span>
          <label class="sr-only" for="demoTo">To</label>
          <select id="demoTo" aria-label="To">
            ${DEMO_LANGS.filter(([code]) => code !== 'auto')
              .map(
                ([code, name]) =>
                  `<option value="${code}"${
                    code === 'en' ? ' selected' : ''
                  }>${esc(name)}</option>`
              )
              .join('')}
          </select>
        </div>
        <label class="sr-only" for="demoInput">${esc(a11y.demo)}</label>
        <textarea id="demoInput" class="demo__input" rows="2" maxlength="200" placeholder="${esc(c.hero.demoPlaceholder)}"></textarea>
        <div class="demo__row">
          <button class="btn btn--primary btn--sm" id="demoBtn" type="button">${esc(c.hero.demoBtn)}</button>
          <span class="demo__status" id="demoStatus" role="status" aria-live="polite"></span>
        </div>
        <div class="demo__out" id="demoOut" hidden>
          <span class="demo__label">${esc(c.hero.demoResult)}</span>
          <p id="demoText" class="demo__text"></p>
        </div>
        <p class="demo__sample" id="demoSample">${esc(c.hero.sample)}</p>
        <div class="wave" aria-hidden="true">
          ${Array.from({ length: 22 })
            .map((_, i) => `<span style="--i:${i}"></span>`)
            .join('')}
        </div>
      </div>
    </div>
  </section>

  <section class="marquee" aria-label="Highlights">
    <div class="marquee__track">${trustItems}${trustItems}</div>
  </section>

  <section class="section" id="problem">
    <div class="wrap">
      <header class="section__head reveal">
        <span class="kicker"><i>01</i> ${esc(c.problem.kicker)}</span>
        <h2>${esc(c.problem.title)}</h2>
        <p>${esc(c.problem.sub)}</p>
      </header>
      <div class="grid grid--3">${problemCards}</div>
      <p class="section__note reveal">${esc(c.problem.solution)}</p>
    </div>
  </section>

  <section class="section section--alt" id="features">
    <div class="wrap">
      <header class="section__head reveal">
        <span class="kicker"><i>02</i> ${esc(c.features.kicker)}</span>
        <h2>${esc(c.features.title)}</h2>
        <p>${esc(c.features.sub)}</p>
      </header>
      <div class="grid grid--3 features-grid">${featureCards}</div>
    </div>
  </section>

  <section class="section" id="how">
    <div class="wrap">
      <header class="section__head reveal">
        <span class="kicker"><i>03</i> ${esc(c.how.kicker)}</span>
        <h2>${esc(c.how.title)}</h2>
        <p>${esc(c.how.sub)}</p>
      </header>
      <ol class="steps" id="steps">${steps}</ol>
    </div>
  </section>

  <section class="section section--alt" id="client">
    <div class="wrap client">
      <div class="client__copy reveal">
        <h2>${esc(c.client.title)}</h2>
        <p>${esc(c.client.body)}</p>
        <ul class="client__list">
          ${c.client.bullets
            .map((b) => `<li>${icon('check', 'ico ico--check')}${esc(b)}</li>`)
            .join('')}
        </ul>
        <a class="btn btn--ghost" href="/room/${sampleUser}" target="_blank" rel="noopener">${esc(c.client.cta)}</a>
      </div>
      <div class="phone reveal" aria-hidden="true">
        <div class="phone__notch"></div>
        <div class="phone__screen">
          <span class="phone__badge">livocal.app/join/•••</span>
          <div class="bubble bubble--in">${language === 'bn' ? 'আমি ২০ তারিখে শুরু করতে পারব।' : 'I can start on the 20th.'}</div>
          <div class="bubble bubble--out">${language === 'bn' ? 'I can start on the 20th.' : 'আমি ২০ তারিখে শুরু করতে পারব।'}</div>
          <div class="bubble bubble--in">${language === 'bn' ? 'দামটা কি ফিক্সড?' : 'Is the price fixed?'}</div>
          <div class="bubble bubble--out">${language === 'bn' ? 'Is the price fixed?' : 'দামটা কি ফিক্সড?'}</div>
          <div class="phone__wave"><span></span><span></span><span></span><span></span><span></span></div>
        </div>
      </div>
    </div>
  </section>

${tourSection}

  <section class="section" id="proof">
    <div class="wrap">
      <header class="section__head reveal">
        <span class="kicker"><i>05</i> ${esc(c.proof.kicker)}</span>
        <h2>${esc(c.proof.title)}</h2>
        <p>${esc(c.proof.sub)}</p>
      </header>
      <div class="proof reveal">
        <div class="proof__card">
          <div class="proof__avatar" aria-hidden="true">S</div>
          <div>
            <strong>${esc(c.proof.profileLine)}</strong>
            <span>livocal.app/u/${sampleUser}</span>
          </div>
          <a class="btn btn--ghost btn--sm" href="/u/${sampleUser}" target="_blank" rel="noopener">${esc(c.proof.cta)}</a>
        </div>
        <div class="proof__stats">${stats}</div>
      </div>
    </div>
  </section>

  <section class="section section--alt" id="pricing">
    <div class="wrap">
      <header class="section__head reveal">
        <span class="kicker"><i>06</i> ${esc(c.pricing.kicker)}</span>
        <h2>${esc(c.pricing.title)}</h2>
        <p>${esc(c.pricing.sub)}</p>
      </header>
      <div class="grid grid--2 pricing">${plans}</div>
    </div>
  </section>

  <section class="section" id="faq">
    <div class="wrap wrap--narrow">
      <header class="section__head reveal">
        <span class="kicker"><i>07</i> ${esc(c.faq.kicker)}</span>
        <h2>${esc(c.faq.title)}</h2>
      </header>
      <div class="faq">${faqItems}</div>
    </div>
  </section>

  <section class="section cta" id="access">
    <div class="wrap wrap--narrow">
      <div class="cta__box reveal">
        <h2>${esc(c.final.title)}</h2>
        <p>${esc(c.final.sub)}</p>
        <form class="cta__form" id="waitlistForm" novalidate>
          <label class="sr-only" for="contact">${esc(a11y.contact)}</label>
          <input id="contact" name="contact" type="text" inputmode="email" autocomplete="email"
            placeholder="${esc(c.final.placeholder)}" required>
          <button class="btn btn--primary" type="submit" id="waitlistBtn">${esc(c.final.btn)}</button>
        </form>
        <p class="cta__msg" id="waitlistMsg" role="status" aria-live="polite"></p>
        <p class="cta__note">${esc(c.final.note)}</p>
      </div>
    </div>
  </section>
</main>

<footer class="footer">
  <div class="wrap footer__inner">
    <div class="footer__brand">
      <img src="/site/logo.svg" alt="" width="28" height="28">
      <span>Livocal</span>
      <p>${esc(c.footer.tagline)}</p>
    </div>
    <div class="footer__cols">
      <div>
        <h3>${esc(c.footer.product)}</h3>
        <a href="/u/${sampleUser}">${esc(c.footer.links.profile)}</a>
        <a href="/room/${sampleUser}">${esc(c.footer.links.room)}</a>
        <a href="/app/${sampleUser}">${esc(c.footer.links.app)}</a>
      </div>
      <div>
        <h3>${esc(c.footer.legal)}</h3>
        <a href="/privacy-policy">${esc(c.footer.links.privacy)}</a>
        <a href="/terms-of-service">${esc(c.footer.links.terms)}</a>
        <a href="/delete-account">${esc(c.footer.links.delete)}</a>
      </div>
      <div>
        <h3>${esc(c.footer.support)}</h3>
        <a href="mailto:support@livocal.app">${esc(c.footer.links.mail)}</a>
      </div>
    </div>
  </div>
  <div class="wrap footer__bottom">
    <span>© ${new Date().getFullYear()} Livocal</span>
    <span>livocal.app</span>
  </div>
  <div class="footer__mark" aria-hidden="true">Livocal</div>
</footer>

<script>window.__LV_COPY=${JSON.stringify({
    demoLoading: c.hero.demoLoading,
    demoEmpty: c.hero.demoEmpty,
    demoFail: c.hero.demoFail,
    demoResult: c.hero.demoResult,
    demoSample: c.hero.sample,
    finalSuccess: c.final.success,
    finalError: c.final.error,
    finalBusy: c.final.busy,
    finalBtn: c.final.btn,
    finalBtnBusy: c.final.sending,
  })};window.__LV_LANG=${JSON.stringify(language)};</script>
<script src="/site/landing.js?v=7" defer></script>
</body>
</html>`;
}
