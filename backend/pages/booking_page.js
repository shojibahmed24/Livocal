'use strict';

/** Public booking page (server-rendered, guest-local times via JS). */

function esc(value) {
  return String(value == null ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function initial(name) {
  const trimmed = String(name || '').trim();
  return trimmed ? Array.from(trimmed)[0].toUpperCase() : 'L';
}

export function renderBookingPage({ profile, days, username }) {
  const p = profile || {};
  const name = p.displayName || 'Freelancer';
  const ratingCount = Number(p.ratingCount || 0);
  const ratingAvg = Number(p.ratingAvg || 0);
  const verified = p.published === true && ratingCount > 0;
  const bookingUrl = `/api/public/book/${encodeURIComponent(username)}`;
  const avatar = p.avatarUrl
    ? `<img class="avatar" src="${esc(p.avatarUrl)}" alt="${esc(name)}">`
    : `<div class="avatar avatar-fallback">${esc(initial(name))}</div>`;

  const dayButtons = (Array.isArray(days) ? days : [])
    .map(
      (day, index) =>
        `<button class="day ${index === 0 ? 'active' : ''}" type="button" data-day="${esc(day.date)}">${esc(day.label)}</button>`
    )
    .join('');

  const daySections = (Array.isArray(days) ? days : [])
    .map((day, index) => {
      const slots = (day.slots || [])
        .map(
          (slot) =>
            `<label class="slot"><input type="radio" name="slot" value="${esc(slot.startAt)}">` +
            `<span data-start="${esc(slot.startAt)}" data-end="${esc(slot.endAt)}">${esc(slot.start)} – ${esc(slot.end)}</span></label>`
        )
        .join('');
      return `<div class="day-panel ${index === 0 ? 'active' : ''}" data-day-panel="${esc(day.date)}">${slots}</div>`;
    })
    .join('');

  return `<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Book a call — ${esc(name)}</title>
<meta name="description" content="Book a call with ${esc(name)}.">
<script>
  try {
    var saved = localStorage.getItem('livocal-theme');
    if (saved === 'light' || saved === 'dark') document.documentElement.setAttribute('data-theme', saved);
  } catch (e) {}
</script>
<style>
  :root {
    --bg:#04070d; --card:#0b1422; --card-2:#0f1b2d; --text:#f2f6fb; --muted:#8fa0b6;
    --border:rgba(255,255,255,.08); --primary:#34d399; --primary-ink:#04120c;
    --shadow:0 18px 50px rgba(0,0,0,.35);
  }
  html[data-theme="light"] {
    --bg:#f6f8fb; --card:#fff; --card-2:#f1f5f9; --text:#0b1220; --muted:#5b6b80;
    --border:rgba(11,18,32,.08); --primary:#0f9d76; --primary-ink:#fff;
    --shadow:0 18px 50px rgba(15,40,70,.10);
  }
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--text);font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Noto Sans Bengali',sans-serif;line-height:1.55}
  .wrap{max-width:640px;margin:0 auto;padding:20px 16px 48px}
  .topbar{display:flex;justify-content:flex-end;margin-bottom:10px}
  .theme-btn{border:1px solid var(--border);background:var(--card);color:var(--text);border-radius:999px;padding:7px 14px;font-size:12px;cursor:pointer}
  .host{display:flex;gap:14px;align-items:center;background:var(--card);border:1px solid var(--border);border-radius:20px;padding:18px;box-shadow:var(--shadow)}
  .avatar{width:64px;height:64px;border-radius:18px;object-fit:cover;flex:0 0 auto;border:1px solid var(--border)}
  .avatar-fallback{display:flex;align-items:center;justify-content:center;font-size:26px;font-weight:800;color:var(--primary-ink);background:linear-gradient(135deg,#34d399,#10b981)}
  h1{font-size:20px;margin:0}
  .sub{color:var(--muted);font-size:12.5px;margin:3px 0 0}
  .meta{display:flex;flex-wrap:wrap;gap:6px;margin-top:6px}
  .pill{padding:3px 9px;border-radius:999px;font-size:10.5px;font-weight:800;color:var(--primary);background:rgba(52,211,153,.12);border:1px solid rgba(52,211,153,.28)}
  .card{background:var(--card);border:1px solid var(--border);border-radius:18px;padding:16px;margin-top:14px}
  h2{font-size:10.5px;letter-spacing:.09em;text-transform:uppercase;color:var(--muted);margin:0 0 10px}
  .days{display:flex;gap:8px;overflow-x:auto;padding-bottom:4px}
  .day{white-space:nowrap;border:1px solid var(--border);background:var(--card-2);color:var(--text);border-radius:999px;padding:8px 13px;font-size:12px;cursor:pointer}
  .day.active{border-color:var(--primary);color:var(--primary);background:rgba(52,211,153,.12)}
  .day-panel{display:none;flex-wrap:wrap;gap:8px;margin-top:12px}
  .day-panel.active{display:flex}
  .slot{display:inline-flex;align-items:center;gap:6px;padding:8px 12px;border:1px solid var(--border);border-radius:10px;font-size:12.5px;cursor:pointer;background:var(--card-2)}
  .slot:has(input:checked){border-color:var(--primary);background:rgba(52,211,153,.12)}
  .slot input{accent-color:var(--primary)}
  .tz{font-size:11px;color:var(--muted);margin-top:8px}
  label.field{display:block;margin:10px 0 4px;font-size:11.5px;color:var(--muted)}
  input[type=text],textarea{width:100%;padding:11px 12px;border-radius:10px;border:1px solid var(--border);background:var(--card-2);color:var(--text);font-size:13px}
  button.primary{width:100%;margin-top:16px;padding:13px;border:0;border-radius:12px;background:var(--primary);color:var(--primary-ink);font-weight:800;font-size:14px;cursor:pointer}
  button.primary:disabled{opacity:.55;cursor:not-allowed}
  .msg{font-size:12px;margin-top:10px}
  .err{color:#ff6b6b;font-weight:700}
  .ok{color:var(--primary);font-weight:700}
  .empty{color:var(--muted);font-size:13px}
  .success{display:none;text-align:center;padding:18px 8px}
  .success.show{display:block}
  .success .big{font-size:40px}
  .success h3{margin:6px 0 4px}
  .success p{color:var(--muted);font-size:12.5px;margin:4px 0 12px}
  .success a{display:inline-block;padding:10px 16px;border-radius:10px;background:var(--primary);color:var(--primary-ink);font-weight:800;font-size:12.5px;text-decoration:none}
  footer{margin-top:22px;text-align:center;color:var(--muted);font-size:11px}
</style>
</head>
<body>
<div class="wrap">
  <div class="topbar"><button class="theme-btn" id="themeToggle" type="button">◐ Theme</button></div>

  <header class="host">
    ${avatar}
    <div>
      <h1>${esc(name)}</h1>
      <p class="sub">${esc(p.headline || 'Book a call')}</p>
      <div class="meta">
        ${verified ? '<span class="pill">✓ Verified</span>' : ''}
        ${ratingCount > 0 ? `<span class="pill">★ ${ratingAvg.toFixed(1)} · ${ratingCount}</span>` : ''}
      </div>
    </div>
  </header>

  <form id="bookingForm">
    <section class="card" id="slotCard">
      <h2>Pick a time</h2>
      ${days.length ? `<div class="days" id="dayTabs">${dayButtons}</div>${daySections}<div class="tz" id="tzLine">Times are shown in your local timezone.</div>` : '<p class="empty">No open slots right now. Please check back later.</p>'}
    </section>

    <section class="card" id="detailsCard">
      <h2>Your details</h2>
      <label class="field" for="guestName">Your name</label>
      <input id="guestName" name="guestName" type="text" maxlength="80" required>
      <label class="field" for="guestContact">WhatsApp or email</label>
      <input id="guestContact" name="guestContact" type="text" maxlength="120" required>
      <label class="field" for="note">Note (optional)</label>
      <textarea id="note" name="note" rows="3" maxlength="500"></textarea>
      <button class="primary" type="submit" ${days.length ? '' : 'disabled'}>Request booking</button>
      <p class="msg" id="formMsg"></p>
    </section>
  </form>

  <section class="card success" id="successCard">
    <div class="big">✅</div>
    <h3>Request sent</h3>
    <p>${esc(name)} will confirm shortly.</p>
    <a id="icsLink" href="#">Add to calendar</a>
  </section>

  <footer>Powered by Livocal · live voice translation for freelancers</footer>
</div>
<script>
  var SLUG = ${JSON.stringify(username)};
  var BOOK_URL = ${JSON.stringify(bookingUrl)};

  document.getElementById('themeToggle').addEventListener('click', function () {
    var root = document.documentElement;
    var next = root.getAttribute('data-theme') === 'light' ? 'dark' : 'light';
    root.setAttribute('data-theme', next);
    try { localStorage.setItem('livocal-theme', next); } catch (e) {}
  });

  function fmt(date) {
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  }
  document.querySelectorAll('span[data-start]').forEach(function (element) {
    var start = new Date(element.getAttribute('data-start'));
    var end = new Date(element.getAttribute('data-end'));
    if (isNaN(start) || isNaN(end)) return;
    element.textContent = fmt(start) + ' – ' + fmt(end);
  });

  var tabs = document.querySelectorAll('.day');
  tabs.forEach(function (tab) {
    tab.addEventListener('click', function () {
      tabs.forEach(function (other) { other.classList.remove('active'); });
      document.querySelectorAll('.day-panel').forEach(function (panel) { panel.classList.remove('active'); });
      tab.classList.add('active');
      var panel = document.querySelector('[data-day-panel="' + tab.getAttribute('data-day') + '"]');
      if (panel) panel.classList.add('active');
    });
  });

  document.getElementById('bookingForm').addEventListener('submit', async function (event) {
    event.preventDefault();
    var form = event.target;
    var msg = document.getElementById('formMsg');
    var slot = form.querySelector('input[name=slot]:checked');
    if (!slot) { msg.className = 'msg err'; msg.textContent = 'Please pick a time slot.'; return; }
    msg.className = 'msg'; msg.textContent = 'Sending...';

    try {
      var response = await fetch(BOOK_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          guestName: form.guestName.value,
          guestContact: form.guestContact.value,
          note: form.note.value,
          slot: slot.value
        })
      });
      var data = await response.json().catch(function () { return {}; });
      if (!response.ok) {
        msg.className = 'msg err';
        msg.textContent = data.error === 'slot_taken'
          ? 'That slot was just taken. Please pick another.'
          : 'Could not send the request. Please try again.';
        return;
      }
      document.getElementById('bookingForm').style.display = 'none';
      document.getElementById('successCard').classList.add('show');
      document.getElementById('icsLink').href = '/book/' + SLUG + '/' + data.id + '.ics';
    } catch (error) {
      msg.className = 'msg err';
      msg.textContent = 'Network error. Please try again.';
    }
  });
</script>
</body>
</html>`;
}

export function bookingIcs({ booking, hostName, hostEmail }) {
  const start = new Date(booking.startAt);
  const end = new Date(booking.endAt);
  const toIcs = (date) =>
    date
      .toISOString()
      .replace(/[-:]/g, '')
      .replace(/\.\d{3}Z$/, 'Z');
  const uid = `${booking.id || 'booking'}@livocal`;
  const summary = `Call with ${hostName || 'Freelancer'}`;
  const description = [
    'Booked via Livocal.',
    booking.guestName ? `Guest: ${booking.guestName}` : '',
    booking.note ? `Note: ${booking.note}` : '',
  ]
    .filter(Boolean)
    .join('\n');

  return [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Livocal//Booking//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'BEGIN:VEVENT',
    `UID:${uid}`,
    `DTSTAMP:${toIcs(new Date())}`,
    `DTSTART:${toIcs(start)}`,
    `DTEND:${toIcs(end)}`,
    `SUMMARY:${summary}`,
    `DESCRIPTION:${description.replace(/\n/g, '\\n')}`,
    hostEmail ? `ORGANIZER:mailto:${hostEmail}` : '',
    'END:VEVENT',
    'END:VCALENDAR',
  ]
    .filter(Boolean)
    .join('\r\n');
}
