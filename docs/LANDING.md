# Landing page — quick map

Everything that renders `livocal.app` lives in three files plus the copy
modules. No build step, no framework.

## Files

| File | What it does |
|---|---|
| `backend/pages/landing_page.js` | Renders the HTML. Sections, the phone call simulation markup, the optional video section. |
| `backend/pages/i18n/*.js` | Copy for each language (`en, bn, hi, ar, es, fr, de`). Same shape everywhere. |
| `backend/public/site/landing.css` | All styles, including RTL (`html[dir="rtl"]`). |
| `backend/public/site/landing.js` | Reveal animations, language menu, call simulation, waitlist form, counters. |
| `backend/public/site/logo.svg` | Brand mark used in the nav and footer. |
| `backend/public/site/fonts/*.woff2` | Sora (Latin) and Noto Sans Bengali. |

## Routes

| Path | Language |
|---|---|
| `/` | English (redirects if `Accept-Language` prefers another) |
| `/bn` `/hi` `/ar` `/es` `/fr` `/de` | other languages |

`?lang=xx` on `/` redirects to the right path. The language menu stores the
choice in `localStorage` (`lv-lang`).

## QA hooks

| URL | What it does |
|---|---|
| `/?sim=ringing` | Holds the call simulation on the incoming-call screen |
| `/?sim=live` | Holds it on the live transcript |
| `/?sim=ended` | Holds it on the call-ended screen |

## Editing copy

1. Open `backend/pages/i18n/<lang>.js`.
2. Change the string — every language file has the same keys.
3. Add the key to **all seven** files, otherwise the page falls back to the
   English value.

The call simulation script is `callScript` (`y` = your lines, `t` = the
client's questions translated). The client always speaks English; on the
English page the roles flip so the translation is still visible.

## The call simulation

`callsim` in `landing_page.js` + `landing.js`:

```
ringing (2.4s) → connecting (0.9s) → live (6 messages) → ended (2.6s) → loop
```

- Pauses when the card leaves the viewport (`IntersectionObserver`).
- `prefers-reduced-motion` → a static transcript is rendered instead.
- An `sr-only` transcript is always in the DOM for screen readers and SEO.

## The real-call video (optional)

`docs/RECORDING-CALL-DEMO.md`. The section is hidden until
`backend/public/site/media/call-demo.mp4` exists, so shipping without it is safe.

## Waitlist

`POST /api/public/waitlist` writes to Firestore:

```
waitlist/{sha256(contact).slice(0,32)}
  contact, locale, source, ipHash, createdAt
```

- Deduplicated by contact hash (submitting twice updates the same doc).
- 3 submissions / 10 min / IP.
- Client reads and writes are denied by Firestore rules; only the server
  (Admin SDK) touches it.

### Where to read it

- **`https://livocal.app/admin/waitlist`** — table view with “Download CSV” and
  “Copy emails”. It asks for the admin secret with HTTP Basic (any username,
  password = `ADMIN_SECRET`).
- **Firebase Console → Firestore → `waitlist`** — raw documents.
- `GET /api/admin/waitlist` with the `x-admin-secret` header — JSON for scripts.

## Adding a new language

1. Copy `backend/pages/i18n/en.js` → `xx.js`, translate every value, set
   `label` and `locale`.
2. Register it in `backend/pages/i18n/index.js` (`LANGUAGES`, `COPY`,
   `LANDING_PATHS`).
3. Add the route list in `server.js` (`LANDING_LANGS`).
4. Add the code to the sitemap array.
