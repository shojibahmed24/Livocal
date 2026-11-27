'use strict';

/** Marketing landing page for https://livocal.app (no framework, no build). */

function esc(value) {
  return String(value == null ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

const ICONS = {
  mic: '<path d="M12 3a3 3 0 0 0-3 3v6a3 3 0 0 0 6 0V6a3 3 0 0 0-3-3z"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>',
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

// ── Copy ────────────────────────────────────────────────────────────────────
const COPY = {
  en: {
    langLabel: 'বাংলা',
    nav: {
      features: 'Features',
      how: 'How it works',
      pricing: 'Pricing',
      faq: 'FAQ',
      cta: 'Get early access',
    },
    hero: {
      eyebrow: 'Built for Bangladeshi freelancers',
      title1: 'Speak Bangla.',
      title2: 'Be understood in English.',
      sub: 'Live voice translation, booking, invoices and a public profile — one workspace for freelancers who work across languages.',
      cta1: 'Get early access',
      cta2: 'Try the translator',
      micro: 'Free while we launch · No card required · 7 languages',
      demoTitle: 'Try it now',
      demoHint: 'Type a sentence, get the English instantly.',
      demoPlaceholder: 'আমি পরের সপ্তাহে কাজ শুরু করতে পারব',
      demoBtn: 'Translate',
      demoLoading: 'Translating…',
      demoEmpty: 'Write something first.',
      demoFail: 'The demo is busy right now — here is a sample.',
      demoResult: 'English',
      sample: 'I can start work next week.',
    },
    trust: [
      'Made in Bangladesh',
      '7 languages',
      'Client needs no app',
      'Invoices + booking',
      'No card required',
      'Guest calls in the browser',
    ],
    problem: {
      kicker: 'The gap',
      title: 'The deal is lost in translation',
      sub: 'Not because of your skill — because of the language barrier inside the call.',
      items: [
        {
          t: '“My client doesn’t understand my accent.”',
          b: 'Calls turn into typing, and typing loses the deal.',
        },
        {
          t: '“I lose hours explaining myself.”',
          b: 'Every new client needs the same long introduction.',
        },
        {
          t: '“My invoices look like screenshots.”',
          b: 'Unprofessional files make clients delay payment.',
        },
      ],
      solution: 'Livocal fixes all three in one app',
    },
    features: {
      kicker: 'The toolkit',
      title: 'Everything a freelancer needs, in one place',
      sub: 'Six tools that used to live in six different apps.',
      items: [
        { i: 'mic', t: 'Translated calls', b: 'Speak your language. Your client hears theirs, in real time.' },
        { i: 'user', t: 'Public profile', b: 'Portfolio, services, reviews and a QR code on one link.' },
        { i: 'calendar', t: 'Booking', b: '60-minute slots, timezone-safe. The client needs no app.' },
        { i: 'receipt', t: 'Invoices', b: 'Line items, tax, due dates, shareable link and PDF.' },
        { i: 'spark', t: 'AI proposals', b: 'A client-ready scope written from a single brief.' },
        { i: 'doc', t: 'CV builder', b: 'One-page PDF with Bangla and English fonts built in.' },
      ],
    },
    how: {
      kicker: 'Three steps',
      title: 'How it works',
      sub: 'Three steps, no setup calls.',
      steps: [
        { t: 'Create your profile', b: 'Add your work, services, rate and portfolio. Publish in one tap.' },
        { t: 'Share one link', b: 'Send livocal.app/u/you. Clients book and join calls from the browser.' },
        { t: 'Talk, invoice, get paid', b: 'Translated voice, then a clean invoice and a reminder.' },
      ],
    },
    client: {
      kicker: 'Zero install',
      title: 'Your client never installs anything',
      body: 'They open a link, allow the microphone and talk. No store, no sign-up, no account.',
      bullets: ['Opens in any browser', 'One-time signed link', 'Microphone permission asked politely'],
      cta: 'See a live room',
    },
    proof: {
      kicker: 'Live proof',
      title: 'A real Livocal profile',
      sub: 'Everything below is live — not a mockup.',
      stats: [
        { v: '7', l: 'languages' },
        { v: '60', l: 'minute slots' },
        { v: '$0', l: 'to start' },
        { v: '1', l: 'link' },
      ],
      cta: 'Open the live profile',
    },
    pricing: {
      kicker: 'Pricing',
      title: 'Simple pricing',
      sub: 'Free while we launch. No card, no trial countdown.',
      plans: [
        {
          name: 'Free',
          price: '$0',
          period: 'forever',
          badge: 'Available now',
          features: ['Profile, booking and invoices', 'AI proposals', 'Voice calls with translation', '7 languages'],
          cta: 'Get early access',
        },
        {
          name: 'Premium',
          price: '$5',
          period: 'per month',
          badge: 'Coming soon',
          features: ['30 voice minutes / month', 'Priority translation', 'Everything in Free'],
          cta: 'Join the waitlist',
        },
      ],
    },
    faq: {
      kicker: 'Questions',
      title: 'Questions, answered',
      items: [
        { q: 'Is Livocal free?', a: 'Yes during launch. Premium will be $5/month later, and you will be told before anything changes.' },
        { q: 'Does the client need the app?', a: 'No. They receive a link and join the call from any browser. Only you install the app.' },
        { q: 'Which languages are supported?', a: 'Bangla, English, Hindi, Arabic, Spanish, French and German today. More are added as voice models improve.' },
        { q: 'Are my calls recorded?', a: 'No. Audio is translated in real time and never stored. Call summaries are text you choose to save.' },
        { q: 'What happens to my data?', a: 'It stays yours. You can delete the account and its data from Settings, or from livocal.app/delete-account.' },
        { q: 'Will it work on a slow connection?', a: 'Voice uses about 24 kbps. If the network drops, the call continues as direct voice without translation.' },
      ],
    },
    final: {
      title: 'Be first when we open',
      sub: 'Leave an email or a phone number. We send one message when your account is ready.',
      placeholder: 'you@example.com or 01XXXXXXXXX',
      btn: 'Request access',
      note: 'No spam. One message, then nothing until you ask.',
      success: 'You are on the list. We will be in touch.',
      error: 'Please enter a valid email or Bangladeshi phone number.',
      busy: 'Too many attempts — try again in a few minutes.',
    },
    footer: {
      tagline: 'Live voice translation for freelancers.',
      product: 'Product',
      legal: 'Legal',
      support: 'Support',
      links: {
        profile: 'Example profile',
        room: 'Guest room',
        app: 'Web hub',
        privacy: 'Privacy policy',
        terms: 'Terms of service',
        delete: 'Delete account',
        mail: 'Contact support',
      },
    },
  },

  bn: {
    langLabel: 'English',
    nav: {
      features: 'ফিচার',
      how: 'কীভাবে কাজ করে',
      pricing: 'দাম',
      faq: 'প্রশ্ন',
      cta: 'আর্লি অ্যাক্সেস',
    },
    hero: {
      eyebrow: 'বাংলাদেশের ফ্রিল্যান্সারদের জন্য',
      title1: 'বাংলায় বলুন।',
      title2: 'ক্লায়েন্ট বুঝবে ইংরেজিতে।',
      sub: 'লাইভ ভয়েস অনুবাদ, বুকিং, ইনভয়েস আর পাবলিক প্রোফাইল — ভিন্ন ভাষায় কাজ করা ফ্রিল্যান্সারদের জন্য একটাই জায়গা।',
      cta1: 'আর্লি অ্যাক্সেস নিন',
      cta2: 'অনুবাদ দেখুন',
      micro: 'লঞ্চ পর্যন্ত ফ্রি · কার্ড লাগবে না · ৭ ভাষা',
      demoTitle: 'এখনই দেখুন',
      demoHint: 'বাংলায় লিখুন, সাথে সাথে ইংরেজি পাবেন।',
      demoPlaceholder: 'আমি পরের সপ্তাহে কাজ শুরু করতে পারব',
      demoBtn: 'অনুবাদ করুন',
      demoLoading: 'অনুবাদ হচ্ছে…',
      demoEmpty: 'আগে কিছু লিখুন।',
      demoFail: 'ডেমো এখন ব্যস্ত — নিচে একটি নমুনা দেখুন।',
      demoResult: 'ইংরেজি',
      sample: 'I can start work next week.',
    },
    trust: [
      'বাংলাদেশে তৈরি',
      '৭ ভাষা',
      'ক্লায়েন্টকে অ্যাপ লাগে না',
      'ইনভয়েস + বুকিং',
      'কার্ড লাগে না',
      'ব্রাউজারেই গেস্ট কল',
    ],
    problem: {
      kicker: 'সমস্যা',
      title: 'ডিলটা নষ্ট হয় ভাষার কারণে',
      sub: 'আপনার দক্ষতার অভাবে না — কলের ভেতরের ভাষা-বাধার কারণে।',
      items: [
        { t: '“ক্লায়েন্ট আমার উচ্চারণ বোঝে না।”', b: 'কল হয়ে যায় টাইপিং, আর টাইপিংয়ে ডিল হারায়।' },
        { t: '“নিজেকে বোঝাতে ঘণ্টা পার হয়।”', b: 'প্রতিটা নতুন ক্লায়েন্টকে একই লম্বা পরিচয় দিতে হয়।' },
        { t: '“আমার ইনভয়েস দেখতে স্ক্রিনশটের মতো।”', b: 'অপেশাদার ফাইলে ক্লায়েন্ট পেমেন্ট দিতে দেরি করে।' },
      ],
      solution: 'Livocal তিনটাই এক অ্যাপে ঠিক করে',
    },
    features: {
      kicker: 'টুলকিট',
      title: 'ফ্রিল্যান্সারের যা যা দরকার, এক জায়গায়',
      sub: 'যে ছয়টা কাজ আগে ছয়টা অ্যাপে হতো।',
      items: [
        { i: 'mic', t: 'অনূদিত কল', b: 'আপনি নিজের ভাষায় বলবেন, ক্লায়েন্ট শুনবে তার ভাষায় — লাইভ।' },
        { i: 'user', t: 'পাবলিক প্রোফাইল', b: 'পোর্টফোলিও, সার্ভিস, রিভিউ আর QR সহ একটা লিংক।' },
        { i: 'calendar', t: 'বুকিং', b: '৬০ মিনিটের স্লট, টাইমজোন-নিরাপদ। ক্লায়েন্টের অ্যাপ লাগে না।' },
        { i: 'receipt', t: 'ইনভয়েস', b: 'লাইন আইটেম, ট্যাক্স, ডিউ ডেট, শেয়ার লিংক আর PDF।' },
        { i: 'spark', t: 'AI প্রপোজাল', b: 'একটা ব্রিফ থেকে ক্লায়েন্ট-রেডি স্কোপ।' },
        { i: 'doc', t: 'CV বিল্ডার', b: 'বাংলা ও ইংরেজি ফন্টসহ এক পাতার PDF।' },
      ],
    },
    how: {
      kicker: 'তিন ধাপ',
      title: 'কীভাবে কাজ করে',
      sub: 'তিন ধাপ, কোনো সেটআপ কল নেই।',
      steps: [
        { t: 'প্রোফাইল বানান', b: 'কাজ, সার্ভিস, রেট আর পোর্টফোলিও দিন। এক ট্যাপে পাবলিশ করুন।' },
        { t: 'একটা লিংক শেয়ার করুন', b: 'livocal.app/u/আপনারনাম পাঠান। ক্লায়েন্ট ব্রাউজার থেকেই বুক করবে আর কলে আসবে।' },
        { t: 'কথা বলুন, ইনভয়েস দিন, টাকা নিন', b: 'অনূদিত ভয়েস, তারপর পরিষ্কার ইনভয়েস আর রিমাইন্ডার।' },
      ],
    },
    client: {
      kicker: 'ইনস্টল ছাড়াই',
      title: 'ক্লায়েন্টকে কিছু ইনস্টল করতে হবে না',
      body: 'লিংক খুলবে, মাইকের অনুমতি দেবে, কথা বলবে। কোনো স্টোর নেই, সাইন-আপ নেই, অ্যাকাউন্ট নেই।',
      bullets: ['যেকোনো ব্রাউজারে খোলে', 'একবার ব্যবহারযোগ্য সাইনড লিংক', 'বিনয়ের সাথে মাইক পারমিশন চাওয়া হয়'],
      cta: 'লাইভ রুম দেখুন',
    },
    proof: {
      kicker: 'লাইভ প্রমাণ',
      title: 'একটা আসল Livocal প্রোফাইল',
      sub: 'নিচের সবকিছু লাইভ — মকআপ না।',
      stats: [
        { v: '৭', l: 'ভাষা' },
        { v: '৬০', l: 'মিনিট স্লট' },
        { v: '০৳', l: 'শুরু করতে' },
        { v: '১', l: 'লিংক' },
      ],
      cta: 'লাইভ প্রোফাইল খুলুন',
    },
    pricing: {
      kicker: 'দাম',
      title: 'সহজ দাম',
      sub: 'লঞ্চ পর্যন্ত ফ্রি। কার্ড নেই, ট্রায়াল কাউন্টডাউন নেই।',
      plans: [
        {
          name: 'Free',
          price: '০৳',
          period: 'সবসময়',
          badge: 'এখনই চালু',
          features: ['প্রোফাইল, বুকিং আর ইনভয়েস', 'AI প্রপোজাল', 'অনুবাদসহ ভয়েস কল', '৭ ভাষা'],
          cta: 'আর্লি অ্যাক্সেস নিন',
        },
        {
          name: 'Premium',
          price: '$5',
          period: 'প্রতি মাস',
          badge: 'শিগগিরই',
          features: ['মাসে ৩০ মিনিট ভয়েস', 'প্রায়োরিটি অনুবাদ', 'Free-এর সবকিছু'],
          cta: 'ওয়েটলিস্টে যোগ দিন',
        },
      ],
    },
    faq: {
      kicker: 'প্রশ্নোত্তর',
      title: 'প্রশ্নের উত্তর',
      items: [
        { q: 'Livocal কি ফ্রি?', a: 'লঞ্চের সময় হ্যাঁ। পরে Premium $5/মাস হবে, আর কিছু বদলানোর আগে আপনাকে জানানো হবে।' },
        { q: 'ক্লায়েন্টের অ্যাপ লাগবে?', a: 'না। একটা লিংক পাবে, যেকোনো ব্রাউজার থেকে কল জয়েন করবে। অ্যাপ শুধু আপনিই ইনস্টল করবেন।' },
        { q: 'কোন কোন ভাষা আছে?', a: 'এখন বাংলা, ইংরেজি, হিন্দি, আরবি, স্প্যানিশ, ফরাসি ও জার্মান। ভয়েস মডেল ভালো হলে আরও যোগ হবে।' },
        { q: 'কল রেকর্ড হয়?', a: 'না। অডিও লাইভ অনুবাদ হয়, কোথাও জমা হয় না। কল সামারি শুধু আপনি চাইলে টেক্সট হিসেবে রাখতে পারেন।' },
        { q: 'আমার ডেটার কী হয়?', a: 'ডেটা আপনারই। Settings থেকে অ্যাকাউন্টসহ সব মুছে ফেলতে পারবেন, অথবা livocal.app/delete-account থেকে।' },
        { q: 'ধীর ইন্টারনেটে চলবে?', a: 'ভয়েস প্রায় ২৪ kbps নেয়। নেটওয়ার্ক পড়ে গেলে কল অনুবাদ ছাড়া সরাসরি ভয়েসে চলতে থাকে।' },
      ],
    },
    final: {
      title: 'আমরা খুললে সবার আগে থাকুন',
      sub: 'ইমেইল বা ফোন নম্বর দিন। অ্যাকাউন্ট রেডি হলে একটাই মেসেজ পাঠাব।',
      placeholder: 'you@example.com বা 01XXXXXXXXX',
      btn: 'অ্যাক্সেস চাই',
      note: 'স্প্যাম নেই। একটা মেসেজ, তারপর আপনি না চাইলে কিছু না।',
      success: 'লিস্টে যোগ হয়েছে। আমরা যোগাযোগ করব।',
      error: 'সঠিক ইমেইল বা বাংলাদেশি ফোন নম্বর দিন।',
      busy: 'অনেকবার চেষ্টা হয়েছে — কয়েক মিনিট পরে আবার দিন।',
    },
    footer: {
      tagline: 'ফ্রিল্যান্সারদের জন্য লাইভ ভয়েস অনুবাদ।',
      product: 'প্রোডাক্ট',
      legal: 'লিগ্যাল',
      support: 'সাপোর্ট',
      links: {
        profile: 'নমুনা প্রোফাইল',
        room: 'গেস্ট রুম',
        app: 'ওয়েব হাব',
        privacy: 'প্রাইভেসি পলিসি',
        terms: 'শর্তাবলি',
        delete: 'অ্যাকাউন্ট মুছুন',
        mail: 'সাপোর্টে লিখুন',
      },
    },
  },
};

// ── Renderer ────────────────────────────────────────────────────────────────
export function renderLanding({ lang, origin }) {
  const language = lang === 'bn' ? 'bn' : 'en';
  const c = COPY[language];
  const base = origin || 'https://livocal.app';
  const canonical = language === 'bn' ? `${base}/bn` : `${base}/`;
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

  return `<!DOCTYPE html>
<html lang="${language}" class="no-js">
<head>
<meta charset="UTF-8">
<script>document.documentElement.className = 'js';</script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${language === 'bn'
    ? 'Livocal — ফ্রিল্যান্সারদের জন্য লাইভ ভয়েস অনুবাদ'
    : 'Livocal — Live voice translation for Bangladeshi freelancers'}</title>
<meta name="description" content="${esc(c.hero.sub)}">
<link rel="canonical" href="${canonical}">
<link rel="alternate" hreflang="en" href="${base}/">
<link rel="alternate" hreflang="bn" href="${base}/bn">
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
<link rel="manifest" href="/manifest.webmanifest">
<style>:root{--bg:#04070D;--surface:#0B1422;--surface-2:#0F1B2D;--text:#F2F6FB;--muted:#8FA0B6;--accent:#34D399;--accent-ink:#04120C;--accent-2:#6366F1;--border:rgba(255,255,255,.08);--radius:18px;--ease:cubic-bezier(.2,.8,.2,1)}*{box-sizing:border-box}html{-webkit-text-size-adjust:100%;scroll-behavior:smooth}body{margin:0;background:var(--bg);color:var(--text);font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Noto Sans Bengali',sans-serif;line-height:1.6;overflow-x:hidden}a{color:inherit}</style>
<link rel="stylesheet" href="/site/landing.css?v=4">
<script type="application/ld+json">${JSON.stringify(jsonLd)}</script>
</head>
<body data-lang="${language}">
<div class="progress" id="progress" aria-hidden="true"></div>
<a class="skip" href="#main">${language === 'bn' ? 'মূল কনটেন্টে যান' : 'Skip to content'}</a>

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
      <a class="nav__lang" href="${language === 'bn' ? '/' : '/bn'}" hreflang="${language === 'bn' ? 'en' : 'bn'}" data-lang-switch>${esc(c.langLabel)}</a>
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
        <label class="sr-only" for="demoInput">${language === 'bn' ? 'বাংলা বাক্য' : 'Bangla sentence'}</label>
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
            <strong>${
              language === 'bn'
                ? 'Shojib Ahmed — ফ্লাটার ও ফায়ারবেস ডেভেলপার'
                : 'Shojib Ahmed — Flutter and Firebase Developer'
            }</strong>
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
          <label class="sr-only" for="contact">${language === 'bn' ? 'ইমেইল বা ফোন' : 'Email or phone'}</label>
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
    finalBtnBusy: language === 'bn' ? 'পাঠানো হচ্ছে…' : 'Sending…',
  })};window.__LV_LANG=${JSON.stringify(language)};</script>
<script src="/site/landing.js?v=4" defer></script>
</body>
</html>`;
}
