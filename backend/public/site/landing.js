/* Livocal landing — reveal, counters, demo, waitlist. No dependencies. */
(function () {
  'use strict';

  var COPY = window.__LV_COPY || {};
  var LANG = window.__LV_LANG || 'en';
  var reduceMotion =
    window.matchMedia &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ── 1. Language memory ─────────────────────────────────────────────── */
  var LANDING_PATHS = ['/', '/bn', '/hi', '/ar', '/es', '/fr', '/de'];
  var pathOf = function (code) {
    return code === 'en' ? '/' : '/' + code;
  };
  try {
    var stored = localStorage.getItem('lv-lang');
    var path = location.pathname;
    if (
      stored &&
      stored !== LANG &&
      LANDING_PATHS.indexOf(path) !== -1 &&
      !sessionStorage.getItem('lv-redirected')
    ) {
      sessionStorage.setItem('lv-redirected', '1');
      location.replace(pathOf(stored));
      return;
    }
    var langSelect = document.getElementById('langSelect');
    if (langSelect) {
      langSelect.value = LANG;
      langSelect.addEventListener('change', function (event) {
        var next = event.target.value;
        try {
          localStorage.setItem('lv-lang', next);
        } catch (err) {}
        location.href = pathOf(next);
      });
    }
  } catch (e) {}

  /* ── 2. Reveal on scroll ────────────────────────────────────────────── */
  var revealables = Array.prototype.slice.call(document.querySelectorAll('.reveal'));
  revealables.forEach(function (el) {
    var delay = parseInt(el.getAttribute('data-delay') || '0', 10);
    if (delay) el.style.setProperty('--d', delay + 'ms');
  });

  if (reduceMotion || !('IntersectionObserver' in window)) {
    revealables.forEach(function (el) {
      el.classList.add('is-in');
    });
  } else {
    var revealObserver = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;
          entry.target.classList.add('is-in');
          revealObserver.unobserve(entry.target);
        });
      },
      { threshold: 0.18, rootMargin: '0px 0px -40px 0px' }
    );
    revealables.forEach(function (el) {
      revealObserver.observe(el);
    });
  }

  /* ── 3. Sticky nav ──────────────────────────────────────────────────── */
  var nav = document.getElementById('nav');
  var progressEl = document.getElementById('progress');
  var ticking = false;
  function onScroll() {
    if (ticking) return;
    ticking = true;
    requestAnimationFrame(function () {
      if (nav) nav.classList.toggle('is-stuck', window.scrollY > 12);
      if (progressEl) {
        var max = document.documentElement.scrollHeight - window.innerHeight;
        var ratio = max > 0 ? window.scrollY / max : 0;
        progressEl.style.width = Math.min(100, Math.max(0, ratio * 100)) + '%';
      }
      updateSteps();
      ticking = false;
    });
  }
  window.addEventListener('scroll', onScroll, { passive: true });

  /* ── 4. Steps progress line ─────────────────────────────────────────── */
  var steps = document.getElementById('steps');
  function updateSteps() {
    if (!steps) return;
    var rect = steps.getBoundingClientRect();
    var viewport = window.innerHeight;
    var total = rect.height;
    var visible = Math.min(Math.max(viewport * 0.7 - rect.top, 0), total);
    steps.style.setProperty('--steps-progress', Math.round(visible) + 'px');
  }
  updateSteps();

  /* ── 5. Demo translator ─────────────────────────────────────────────── */
  var input = document.getElementById('demoInput');
  var demoBtn = document.getElementById('demoBtn');
  var demoStatus = document.getElementById('demoStatus');
  var demoOut = document.getElementById('demoOut');
  var demoText = document.getElementById('demoText');
  var demoBusy = false;

  function showSample(message) {
    if (!demoOut || !demoText) return;
    demoText.textContent = COPY.demoSample || '';
    demoOut.hidden = false;
    if (demoStatus && message) demoStatus.textContent = message;
  }

  function translateDemo() {
    if (demoBusy || !input) return;
    var text = input.value.trim();
    if (!text) {
      if (demoStatus) demoStatus.textContent = COPY.demoEmpty || '';
      return;
    }
    demoBusy = true;
    if (demoBtn) demoBtn.disabled = true;
    if (demoStatus) demoStatus.textContent = COPY.demoLoading || '';

    fetch('/api/public/demo-translate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: text.slice(0, 200), from: LANG }),
    })
      .then(function (res) {
        return res.json().then(function (data) {
          return { ok: res.ok, status: res.status, data: data };
        });
      })
      .then(function (result) {
        var data = result.data || {};
        var translated = data.ok && data.text ? String(data.text).trim() : '';
        if (translated) {
          demoText.textContent = translated;
          demoOut.hidden = false;
          if (demoStatus) demoStatus.textContent = '';
          track('demo');
        } else {
          showSample(COPY.demoFail);
        }
      })
      .catch(function () {
        showSample(COPY.demoFail);
      })
      .then(function () {
        demoBusy = false;
        if (demoBtn) demoBtn.disabled = false;
      });
  }

  if (demoBtn) demoBtn.addEventListener('click', translateDemo);
  if (input) {
    input.addEventListener('keydown', function (event) {
      if ((event.metaKey || event.ctrlKey) && event.key === 'Enter') {
        translateDemo();
      }
    });
  }

  /* ── 6. Waitlist ────────────────────────────────────────────────────── */
  var form = document.getElementById('waitlistForm');
  var contact = document.getElementById('contact');
  var waitlistMsg = document.getElementById('waitlistMsg');
  var waitlistBtn = document.getElementById('waitlistBtn');
  var sending = false;

  var EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
  var PHONE = /^(\+?880|0)1[3-9]\d{8}$/;

  function normalisePhone(value) {
    var digits = value.replace(/[\s-]/g, '');
    if (/^01[3-9]\d{8}$/.test(digits)) return '+88' + digits;
    if (/^\+?8801[3-9]\d{8}$/.test(digits)) return '+' + digits.replace(/^\+?/, '');
    return digits;
  }

  function setMsg(text, kind) {
    if (!waitlistMsg) return;
    waitlistMsg.textContent = text || '';
    waitlistMsg.className = 'cta__msg' + (kind ? ' is-' + kind : '');
  }

  if (form) {
    form.addEventListener('submit', function (event) {
      event.preventDefault();
      if (sending || !contact) return;
      var raw = contact.value.trim();
      var value = '';

      if (EMAIL.test(raw)) {
        value = raw.toLowerCase();
      } else if (PHONE.test(raw.replace(/[\s-]/g, ''))) {
        value = normalisePhone(raw);
      } else {
        setMsg(COPY.finalError || '', 'err');
        contact.focus();
        return;
      }

      sending = true;
      if (waitlistBtn) {
        waitlistBtn.disabled = true;
        waitlistBtn.textContent = COPY.finalBtnBusy || '...';
      }
      setMsg('', '');

      fetch('/api/public/waitlist', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contact: value,
          locale: LANG,
          source: 'landing',
        }),
      })
        .then(function (res) {
          return res.json().then(function (data) {
            return { ok: res.ok, status: res.status, data: data };
          });
        })
        .then(function (result) {
          if (result.ok && result.data && result.data.ok) {
            setMsg(COPY.finalSuccess || '', 'ok');
            contact.value = '';
            track('waitlist');
          } else if (result.status === 429) {
            setMsg(COPY.finalBusy || '', 'err');
          } else {
            setMsg(COPY.finalError || '', 'err');
          }
        })
        .catch(function () {
          setMsg(COPY.finalError || '', 'err');
        })
        .then(function () {
          sending = false;
          if (waitlistBtn) {
            waitlistBtn.disabled = false;
            waitlistBtn.textContent = COPY.finalBtn || 'Send';
          }
        });
    });
  }

  /* ── 7. Anonymous counters (no cookies, no identifiers) ─────────────── */
  var sent = {};
  function track(type) {
    if (sent[type]) return;
    sent[type] = true;
    try {
      var payload = JSON.stringify({ type: type, lang: LANG });
      if (navigator.sendBeacon) {
        var blob = new Blob([payload], { type: 'application/json' });
        navigator.sendBeacon('/api/public/landing-event', blob);
      } else {
        fetch('/api/public/landing-event', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: payload,
          keepalive: true,
        });
      }
    } catch (e) {}
  }

  if (!sessionStorage.getItem('lv-counted')) {
    try {
      sessionStorage.setItem('lv-counted', '1');
    } catch (e) {}
    track('view');
  }

  // Safety net: never leave content hidden if the observer misbehaves.
  setTimeout(function () {
    revealables.forEach(function (el) {
      el.classList.add('is-in');
    });
  }, 2500);

  Array.prototype.forEach.call(
    document.querySelectorAll('a[href="#access"]'),
    function (link) {
      link.addEventListener('click', function () {
        track('cta');
      });
    }
  );

  /* ── 8. Product tour ────────────────────────────────────────────────── */
  var tour = document.getElementById('tourWidget');
  if (tour) {
    var slides = tour.querySelectorAll('.tour__slide');
    var tabs = tour.querySelectorAll('.tour__tab');
    var active = 0;
    var tourTimer = null;

    var showSlide = function (index) {
      active = index;
      Array.prototype.forEach.call(slides, function (slide, i) {
        slide.classList.toggle('is-active', i === index);
      });
      Array.prototype.forEach.call(tabs, function (tab, i) {
        tab.classList.toggle('is-on', i === index);
        tab.setAttribute('aria-selected', i === index ? 'true' : 'false');
      });
    };

    var stopTour = function () {
      if (tourTimer) {
        clearInterval(tourTimer);
        tourTimer = null;
      }
    };

    var playTour = function () {
      if (reduceMotion) return;
      stopTour();
      tourTimer = setInterval(function () {
        showSlide((active + 1) % slides.length);
      }, 4200);
    };

    Array.prototype.forEach.call(tabs, function (tab, i) {
      tab.addEventListener('click', function () {
        showSlide(i);
        playTour();
      });
    });
    tour.addEventListener('mouseenter', stopTour);
    tour.addEventListener('mouseleave', playTour);
    tour.addEventListener('focusin', stopTour);

    var param = parseInt(
      new URLSearchParams(location.search).get('tour') || '',
      10
    );
    if (!isNaN(param) && param >= 0 && param < slides.length) {
      showSlide(param);
    } else {
      playTour();
    }
  }

  /* ── 9. Cursor spotlight on cards (desktop pointers only) ───────────── */
  if (!reduceMotion && window.matchMedia('(pointer: fine)').matches) {
    Array.prototype.forEach.call(document.querySelectorAll('.card'), function (card) {
      card.addEventListener('pointermove', function (event) {
        var rect = card.getBoundingClientRect();
        card.style.setProperty('--mx', (event.clientX - rect.left) + 'px');
        card.style.setProperty('--my', (event.clientY - rect.top) + 'px');
      });
    });
  }

  onScroll();
})();
