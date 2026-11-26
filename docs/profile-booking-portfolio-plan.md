# Freelancer Profile & Booking — Portfolio Redesign + Custom Domain

Status: **Approved direction — decisions recorded, implementation not started**
Owner: Shojib
Repo: `C:\dev\livocal-freelancer` (branch `feat/freelancer`)
Date: 2026-11-26

### Decisions (2026-11-26)
1. **Domain:** start on `livocal-relay.onrender.com/u/<username>`; custom domain is a later phase.
2. **Hosting (when the domain is bought):** builder's call — apex to Render, web app on `app.` subdomain.
3. **Public reviews:** show the latest 3 with first name + initial.
4. **Visual:** dark premium **and** light clean, with a visitor toggle; remember choice.

---

## 1. Why

Today a freelancer can publish a page at
`https://livocal-relay.onrender.com/p/<random-slug>` and a booking page at
`/book/<slug>`. It works, but:

- the address is long, on Render's domain, and looks temporary;
- the slug is auto-generated (`shojib-ahmed-oz8e`) — not a name the freelancer chose;
- the public page is a plain info card, not a portfolio a client would trust;
- the booking page is functional but visually basic;
- changing the link silently breaks previously shared links (just happened:
  `nub4` → `oz8e`).

Goal: a **professional, portfolio-grade public presence** with a **memorable
custom link**, while keeping the app as the place where work happens.

---

## 2. Answers to the open questions

### 2.1 Is the profile on Render? Will it open on my domain?
Yes. Today it is server-rendered by the relay on Render
(`livocal-relay.onrender.com`). It can open on a custom domain, but that needs
three things: a purchased domain, DNS pointed at Render, and a Render "Custom
Domain" entry (TLS is automatic on Render).

Recommended end state:
- `https://livocal.app/u/shojibahmed` — public profile
- `https://livocal.app/book/shojibahmed` — booking page
- `https://livocal.app/p/...` → 301 redirect to `/u/...` (old links never die)

Domain options (decision needed):
| Option | Address | Cost | Notes |
|---|---|---|---|
| **A (recommended)** | `livocal.app/u/<name>` | domain price (~$12–20/yr) | `.app` is HTTPS-only by rule; clean, brandable; apex can point to Render |
| B | `profiles.livocal.app/u/<name>` | same domain | No apex conflict if `livocal.app` is used by a web app elsewhere |
| C | `livocal-relay.onrender.com/u/<name>` | free | No purchase; still says "onrender" |

Constraint found: if `livocal.app` is already attached to Firebase Hosting for
the web app, Firebase cannot proxy `/u/**` to Render. Then either (a) apex →
Render and web app moves to `app.livocal.app`, or (b) a Cloudflare Worker
proxies `/u/*` and `/book/*` to Render. Decide before Phase 5.

### 2.2 Can the profile name be customized?
Yes. Replace the random suffix with a chosen username:
- `username`: 3–24 chars, `a-z 0-9 -`, lowercase, must start/end alphanumeric;
- unique lease in `profiles_slug/{username}` (same transaction pattern we already use);
- reserved words blocked: `admin, api, app, book, u, p, help, support, login, settings, www, mail, root, livocal`;
- changeable later; **old claims are kept**, so previously shared links keep
  resolving (already fixed in code, commit `62cd29f`);
- 404 page shows "This profile link is not active" instead of a blank "Not found".

### 2.3 Should the profile look like a portfolio?
Yes — that is the main upgrade. The current page is a card; clients judge a
freelancer in the first screen. New page (text sketch):

```
┌──────────────────────────────────────────────┐
│  [avatar]  Shojib Ahmed  ✓ Verified          │
│            Flutter & Firebase developer      │
│            ★ 4.9 (12)  ·  Dhaka  ·  EN/BN    │
│            [ Book a call ]  [ Message ]      │
├──────────────────────────────────────────────┤
│  About      short bio, 2–3 lines             │
├──────────────────────────────────────────────┤
│  Services   Web app · Landing page · Fix bugs│
│             (3 cards with starting price)    │
├──────────────────────────────────────────────┤
│  Work       [thumb] [thumb] [thumb]          │
│             portfolio grid (image + link)    │
├──────────────────────────────────────────────┤
│  Skills     Flutter  Firebase  Figma  …      │
│  Languages  Bangla (native) · English (C1)   │
├──────────────────────────────────────────────┤
│  Rate       USD 20 / hour  · Full-time       │
│  Next open  Fri 27 Nov · 09:00–17:00         │
│             [ Book a call ]                  │
├──────────────────────────────────────────────┤
│  Recent reviews  ★★★★★ “Fast and clear.” — R. │
├──────────────────────────────────────────────┤
│  Powered by Livocal                          │
└──────────────────────────────────────────────┘
```

Design language: dark premium (same palette as the app), one accent
(emerald/mint), generous spacing, system font + Noto Sans Bengali fallback,
mobile-first, no heavy JS, OG image for WhatsApp/LinkedIn previews.

Booking page redesign:
- host header (avatar, name, verified, rating);
- date strip (next 14 days) → time slot chips in **guest's local time**;
- timezone line: "Times shown in your timezone (GMT+6)";
- 2 fields + note, one primary button; success card with "Add to calendar"
  (`.ics` download) and "Message on Livocal";
- empty state: "No open slots — request a time" (optional follow-up form).

### 2.4 Why "portfolio" matters
A client deciding between two freelancers compares: proof of work, clear
scope, price, availability, and trust signals (verified, rating). The current
page gives only name/headline/skills. The new template gives all six.

---

## 3. Scope

### In scope
- Custom username + `/u/<username>` and `/book/<username>` routes.
- 301 redirects from `/p/<old>` and `/book/<old>` style links.
- Portfolio-grade public profile (SSR HTML, responsive, OG, JSON-LD).
- Redesigned booking page (timezone-correct, calendar, success + `.ics`).
- In-app editor upgrades: username field with availability check, richer
  portfolio items (label, URL, image URL), live "View page" button.
- Domain + DNS + Render custom domain (Phase 5, depends on decision).
- SEO basics: `<title>`, description, canonical, `robots.txt`, `sitemap.xml`,
  favicon, OG image.
- Optional: public reviews list (latest 3) on the profile.

### Out of scope
- Browser-based calls / join links (F7).
- Payments inside the public page.
- Multi-language page switcher (page is bilingual by content, UI stays English
  + Bangla labels where useful).
- Custom themes per freelancer (v1: one premium theme).

### Non-goals
- Do not expose phone/email or any contact data.
- Do not let clients edit or probe other profiles; no listing endpoint.
- Do not break existing links or the app's current flows.

---

## 4. Approaches considered

### A. Extend the current SSR template (recommended)
Keep server-rendered HTML in `backend/server.js`, add `/u/` routes, replace the
template with a portfolio layout, add a small CSS system and OG tags.
- **Pros:** no new infra, fast first paint, works on any browser, SEO-friendly,
  cheap on Render, no app release needed for public pages.
- **Cons:** template lives in `server.js` (large file) → split into
  `backend/public/profile/` templates; editing design needs redeploy.

### B. Flutter Web profile (one codebase)
Build the public page as Flutter Web and host it.
- **Pros:** reuse app widgets.
- **Cons:** heavy JS payload (slow on 3G), worse SEO/OG, big scope, and the
  booking page would need a separate web build. Rejected.

### C. Static generator + per-user JSON
Pre-render pages at publish time.
- **Pros:** fastest possible page.
- **Cons:** cache invalidation on every profile/rate/availability edit; extra
  storage; overkill at current scale. Rejected for v1.

**Pick: A**, with templates split out of `server.js` so design work stays sane.

---

## 5. Phases (each phase is shippable)

### Phase 0 — Decisions (done)
- Domain deferred: ship on `livocal-relay.onrender.com/u/<username>` first.
- Public reviews: latest 3, first name + initial.
- Theme: dark + light, visitor toggle with remembered choice.
- **Deliverable:** decisions recorded here; no code.

### Phase 1 — Custom username + routes (1–2 days)
Backend:
- `profiles.username` (new field, same value as `slug` for compatibility).
- `POST /api/profile/username` (auth): validate, transaction-claim, keep old
  claim, update `profiles/{uid}`.
- Routes: `GET /u/:username` (page), `GET /api/public/profile/:username`
  (JSON), `GET /book/:username`, `GET /api/public/availability/:username`.
- Legacy `GET /p/:slug` → `301 /u/<slug>`; `/api/public/profile/:slug` stays.
- Reserved-word list + friendly 404 page.
App:
- Profile model `username`; editor field "Your link: livocal.app/u/____" with
  live availability check; save via new endpoint; "Open page" button.
Acceptance:
- Chosen username works immediately; duplicate shows "already taken".
- Old link still opens after a rename.
- Invalid/reserved names rejected with a clear message.

### Phase 2 — Portfolio profile redesign (2–3 days)
- Split public pages into `backend/public/site/` (layout, CSS, partials).
- Sections: hero (avatar, name, verified, rating, languages, CTAs), about,
  services, portfolio grid, skills, languages, rate, next availability,
  **reviews (latest 3, first name + initial)**, footer.
- Theme toggle (dark ⇄ light) in the header, remembered in `localStorage`,
  default dark; no flash on load.
- Responsive 360px → desktop; print-friendly.
- OG/Twitter meta + JSON-LD `Person`/`Offer`; canonical; favicon.
- Optional "Message on Livocal" deep link (`livocal://chat/<uid>` or web
  fallback) and QR button.
Acceptance:
- Lighthouse mobile ≥ 90 performance/SEO (no JS on profile).
- Sharing on WhatsApp shows name + headline + OG image.
- No phone/email in HTML or JSON.

### Phase 3 — Booking page redesign (2 days)
- Hero host card; 14-day date strip; slot chips; guest-local times with
  timezone line; sticky summary on mobile.
- Success state + `.ics` download + booking reference.
- Error states: slot taken, closed day, past slot.
- Keep the existing API contracts (`slot` = ISO instant).
Acceptance:
- Same slot shows the host's local hours on the host side and the guest's
  local hours on the guest side.
- Double-booking still blocked (409) with a friendly message.
- Page works with JS disabled up to the form (progressive enhancement).

### Phase 4 — App editor upgrades (1–2 days)
- Username field + validation + preview.
- Portfolio items: label, URL, image URL (grid thumbnails).
- Services: 3 items with title + starting price (new field).
- "View public page" and "Share" with the new `/u/` URL.
- Localization keys for all new labels (7 locales).
Acceptance:
- Analyze 0, tests green; edits reflect on the public page within ~1 min
  (cache-control 60s).

### Phase 5 — Domain + SEO + launch (deferred until a domain is bought)
- Buy domain (if not owned), add to Render, verify TLS.
- Builder's call: apex (`livocal.app`) → Render; web app to `app.` subdomain.
- `robots.txt`, `sitemap.xml` (generated from published usernames),
  `security.txt`, favicon set.
- Update app copy to the custom URL once live.
Acceptance:
- `https://livocal.app/u/<username>` 200, `http` → `https`, `www` → apex.
- Old `onrender.com/p/...` links 301 to the new URL.
- No mixed-content warnings.

### Phase 6 — QA & rollout (1 day)
- Device pass (TECNO KM6) on profile editor, booking, share sheet.
- Public page pass in Chrome/Safari/Firefox at 360/768/1280.
- Security review: no PII leak, rate limits on booking + username endpoints,
  reserved words, spam guard.
- Deploy via Render (main backend) and confirm `/health`.
- Update `docs/freelancer-feature-spec.md` status.

---

## 6. Technical notes

### Data model changes
```
profiles/{uid}
  username: string            // same as slug, chosen by user
  slug: string                // kept in sync for compatibility
  services: [{ title, from }] // optional, Phase 2
  portfolio: [{ label, url, imageUrl }]
profiles_slug/{name}          // lease: { uid }, old names never deleted
```

### Routes (final)
```
GET  /u/:username                     public profile (HTML)
GET  /api/public/profile/:username    public profile (JSON)
GET  /book/:username                  booking page (HTML)
GET  /api/public/availability/:username
POST /api/public/book/:username
POST /api/profile/username            change username (auth)
GET  /p/:slug                         301 → /u/:slug
```

### Security
- Username changes: auth + transaction claim + reserved list + rate limit.
- Public JSON whitelist only (no uid, phone, email, notes, invoices).
- Booking: 10 req/min/IP, availability + overlap checks server-side.
- HTML escaping already used in the current template; keep one `esc()` helper.

### Performance
- Inline critical CSS, no framework, system fonts; target < 60 KB HTML.
- Cache-Control: profile 60s, availability `no-store`.
- Render free tier cold start: keep `/health` warm or upgrade later.

---

## 7. Risks & mitigations
| Risk | Mitigation |
|---|---|
| `livocal.app` unavailable | fall back to `.io`/`.com`; links are generated from config |
| Firebase Hosting blocks `/u/**` proxy | move apex to Render or add Cloudflare Worker |
| Old links break on rename | never delete `profiles_slug` claims; 301 from `/p/` |
| Template bloat in `server.js` | split templates/CSS into `backend/public/site/` |
| Public reviews leak identity | show first name + initial only; opt-in flag |
| Cold starts on free Render | upgrade plan or move to a paid instance before launch |

---

## 8. Decisions status
1. **Domain:** deferred — ship on `livocal-relay.onrender.com/u/<username>` now.
2. **Hosting:** builder's call when the domain is bought (apex → Render).
3. **Reviews public:** yes — latest 3, first name + initial only.
4. **Visual:** both — dark premium default + light toggle.

Only Phase 5 (custom domain) stays blocked on a domain purchase. Phases 1–4,
6 can proceed now.
