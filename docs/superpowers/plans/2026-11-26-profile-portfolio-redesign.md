# Freelancer Profile & Booking Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (native) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every freelancer a memorable `/u/<username>` portfolio page and a redesigned, timezone-correct booking page, with dark/light themes and public reviews.

**Architecture:** Server-rendered pages stay in the Node relay (fast, SEO-friendly, no app release needed). Page markup moves out of `server.js` into `backend/pages/*.js` render functions. The app gains a customizable username plus richer portfolio fields. Old `/p/` links 301 to `/u/`.

**Tech Stack:** Node 20 + Express (relay), Firestore Admin SDK, Flutter (app), Isar, `pdf`/`share_plus` already present.

**Spec:** `docs/profile-booking-portfolio-plan.md`

## Global Constraints

- Public pages must never expose uid, phone, email, notes, invoices, or call data.
- Username: 3–24 chars, `^[a-z0-9](?:[a-z0-9-]{1,22}[a-z0-9])$`, lowercase; reserved: `admin, api, app, book, u, p, help, support, login, settings, www, mail, root, livocal`.
- Old slug claims are never deleted; renames must keep old links working.
- No new npm packages for the public pages; no client framework.
- Every Dart file stays ≤ 250 lines; analyze 0; tests green.
- Secrets never in code/chat/files.

## Review Focus

- A guest in another timezone must see slot times that match the host's real hours (no UTC shift).
- Renaming a username must not 404 previously shared links.
- Public HTML must remain readable with JavaScript disabled (only theme toggle and time formatting use JS).
- Empty profile fields must degrade gracefully (no broken layout, no “undefined”).
- Rate-limited endpoints must reject duplicate/abusive username and booking attempts.

---

### Task 1: Username backend + `/u/` routes

**Files:**
- Create: `backend/pages/profile_page.js` (render function)
- Create: `backend/pages/booking_page.js` (render function)
- Modify: `backend/server.js` (routes + username endpoint)
- Test: manual curl probes (no Node test runner configured)

**Interfaces:**
- `renderProfilePage({ profile, host, days, reviews, username }) -> string`
- `renderBookingPage({ profile, host, days, username }) -> string`
- `POST /api/profile/username` body `{ username: string }` → `{ ok: true, username }`
- `GET /u/:username`, `GET /book/:username`, `GET /api/public/profile/:username`, `GET /api/public/availability/:username`
- `GET /p/:slug` → 301 `/u/:slug`

- [ ] **Step 1:** Add `PROFILE_RESERVED` set and `normalizeUsername(raw)` in `server.js`; return `{ ok, value }` or `{ ok:false, reason }`.
- [ ] **Step 2:** Add `POST /api/profile/username` (auth + rate limit): validate, run transaction on `profiles_slug/{username}` (allow if unclaimed or same uid), update `profiles/{uid}.username/slug/updatedAt`, return `{ok:true}`. Duplicate → 409.
- [ ] **Step 3:** Add `/u/` aliases by extracting the existing profile/booking handlers into page renderers; keep `/api/public/*` on username. `GET /p/:slug` and `/api/public/profile/:slug` stay working.
- [ ] **Step 4:** Verify: `node --check backend/server.js`; after deploy, curl `/u/<slug>` 200, `/p/<slug>` 301.
- [ ] **Step 5:** Commit.

### Task 2: App username editor

**Files:**
- Modify: `lib/features/freelancer/models/freelancer_profile.dart` (username)
- Modify: `lib/features/freelancer/services/freelancer_profile_service.dart` (`changeUsername`)
- Modify: `lib/features/freelancer/views/freelancer_profile_screen.dart` (field + save)
- Modify: `lib/shared/utils/app_localizations.dart` (keys ×7)
- Test: `flutter analyze`, `flutter test`, device check

**Interfaces:**
- `Future<String?> changeUsername(FreelancerProfile profile, String username)` → `null` on success, otherwise a reason key (`usernameTaken`, `usernameInvalid`).
- `FreelancerProfile.handle` → username when non-empty else slug; `publicUrl` uses it.

- [ ] **Step 1:** Add `username` to model + fromMap/toMap (`username` defaults to slug).
- [ ] **Step 2:** Add service call to `POST /api/profile/username` with bearer token; on success update local row.
- [ ] **Step 3:** Editor: “Your link” field (`livocal-relay.onrender.com/u/______`) with save button, inline error, and successful URL refresh.
- [ ] **Step 4:** Run analyze/tests; commit.

### Task 3: Portfolio profile page

**Files:**
- Create: `backend/pages/profile_page.js` (full template + CSS variables + theme toggle)
- Modify: `backend/server.js` (use renderer; fetch reviews)
- Modify: `firestore.rules` only if reviews read needs a server path (server uses Admin SDK; no change expected)
- Test: curl HTML; browser checks at 360/1280; WhatsApp OG preview

**Interfaces:**
- `renderProfilePage` consumes `profile` (displayName, headline, bio, skills, languages, rate, availability, portfolio, avatarUrl, ratingAvg, ratingCount), `reviews` `[{ name, rating, comment }]`, `username`.

- [ ] **Step 1:** Layout: hero (avatar/name/verified/rating/languages/CTAs) → about → services (rate fallback) → portfolio grid → skills → languages → rate + next availability → latest 3 reviews → footer.
- [ ] **Step 2:** CSS variables + `[data-theme=light]`; header toggle remembered in `localStorage`; no flash script in `<head>`.
- [ ] **Step 3:** SEO: title/description/canonical/OG/Twitter/JSON-LD; graceful empty sections.
- [ ] **Step 4:** Server: load latest 3 reviews (where targetUid == uid, sort in JS), map rater display name → “First L.”.
- [ ] **Step 5:** Verify HTML size, no PII, mobile scroll; commit.

### Task 4: Booking page redesign

**Files:**
- Create: `backend/pages/booking_page.js`
- Modify: `backend/server.js` (renderer + `.ics` endpoint `GET /book/:username/:bookingId.ics`)
- Test: create + cancel booking; check both timezones

**Interfaces:**
- `renderBookingPage({ profile, host, days, username })` — `days[].slots[].startAt/endAt` ISO instants.
- `GET /book/:username/:bookingId.ics` → `text/calendar`.

- [ ] **Step 1:** Host header, 14-day date strip, slot chips (guest-local labels), timezone line.
- [ ] **Step 2:** Sticky form: name, contact, note; success card with booking ref + “Add to calendar”.
- [ ] **Step 3:** Error states (`slot_taken`, closed day, past slot) as inline messages; progressive enhancement.
- [ ] **Step 4:** `.ics` endpoint returns a valid event for that booking id (host-only lookup not required; id unguessable).
- [ ] **Step 5:** Verify with two device timezones; commit.

### Task 5: App portfolio fields + preview

**Files:**
- Modify: `lib/features/freelancer/widgets/profile_form_fields.dart` (services, portfolio image URL)
- Modify: `lib/features/freelancer/widgets/portfolio_dialog.dart` (image URL)
- Modify: model `FreelancerProfile` (`services: [{title, from}]`, `portfolio` image)
- Modify: profile screen (Open page button)
- Test: analyze/tests/device

- [ ] **Step 1:** Add services editor (3 rows: title + starting price).
- [ ] **Step 2:** Portfolio dialog gains optional image URL; grid shows thumbnail on the public page.
- [ ] **Step 3:** “Open page” uses `_launchUrl(publicUrl)`; share text uses `/u/` URL.
- [ ] **Step 4:** Localization keys ×7; analyze/tests; commit.

### Task 6: QA + rollout

- [ ] Device pass: username change, publish, availability, booking, invoice, proposal.
- [ ] Public pass: Chrome/Safari/Firefox, 360/768/1280, JS-off profile.
- [ ] Security: no PII, rate limits, reserved names, duplicate claims.
- [ ] Merge backend to main (`backend/pages/*`, `server.js`), Manual Deploy, verify `/health` + `/u/`.
- [ ] Update `docs/freelancer-feature-spec.md` status.

---

## Sequencing
Task 1 → 2 can ship together (username works while design unchanged). Task 3 → 4 are pure backend and can ship independently. Task 5 depends on 2. Task 6 last.

## Rollback
Each task is one commit on `feat/freelancer`; backend deploys are additive. If a page renderer misbehaves, revert that commit and redeploy; `/p/` routes remain functional.
