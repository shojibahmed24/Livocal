# Freelancer profile, CV and AI summary

Last updated: 2026-11-28

## What changed

### 1. Keyboard no longer closes while typing

Cause: the editor passed `ValueKey(profile.updatedAt…)` to `ProfileProFields`.
The 450 ms autosave updates `updatedAt`, the key changed, Flutter rebuilt the
widget from scratch and the focused `TextField` was replaced — the keyboard
closed.

Fix:

- `ProfileProFields` has no changing key (`freelancer_profile_screen.dart`).
- The "Saved" badge is a `ValueNotifier`, so autosave no longer calls
  `setState` on the whole editor.
- Every field uses `scrollPadding`, `textInputAction.next` and
  `keyboardDismissBehavior: onDrag`.
- A pending debounced save is flushed when the screen closes.
- Regression test: `test/freelancer_profile_focus_test.dart`.

### 2. Editing is possible everywhere

Experience, education, certifications, FAQ, case studies, services and
portfolio rows now support:

- tap the row or the pencil → the same dialog, prefilled (`existing:`)
- delete → instant remove with an **Undo** snackbar
- empty-state text per section
- dialog titles switch between Add and Edit

Shared row widget: `lib/features/freelancer/widgets/editable_entry_tile.dart`.

### 3. CV redesign (app PDF + public web page)

- `lib/features/freelancer/services/cv_pdf_service.dart` — A4, bold Noto Sans,
  photo on the right, emerald accent, summary, skill chips, right-aligned
  dates, footer with the public link.
- `backend/pages/profile_page.js` → `renderCvPage` — the same layout in HTML
  with `@page { size: A4; margin: 14mm }` print rules.
- Photo source: `FreelancerProfile.avatarUrl` (field **Profile photo URL** in
  *Professional details*). It is hidden when empty.
- PDF smoke test: `test/freelancer_cv_pdf_test.dart` (builds a real PDF with
  every section and checks the `%PDF` header).

### 4. AI summary (English only)

Server: `POST /api/ai/summary` in `backend/server.js`.

```
Authorization: Bearer <Firebase ID token>
{ displayName, headline, skills[], experience[], education[], services[],
  languages[], yearsExperience, rate?, tone: "professional"|"concise"|"friendly" }
→ { text, source, reason }
```

- Provider order: OpenRouter → Gemini → template.
- The prompt allows only facts from the profile; it never invents clients,
  degrees, metrics or years.
- Limit: 2–3 sentences, 55 words, first person, plain text.
- Rate limited by `translateLimiter`; nothing is stored.

App: `lib/features/freelancer/services/ai_summary_service.dart` and the
`Write with AI` sheet (`widgets/summary_sheet.dart`). The result fills the bio
field, which the CV prints as **Summary**. The user can edit it afterwards.

## Not done yet (deferred by the user)

- Image upload (profile photo, cover, portfolio) needs storage. The user chose
  Supabase Storage, to be built after this task. Until then a public image URL
  is used, and `avatarUrl` will stay the same field.
- Phone OTP without Blaze (custom token + local SMS gateway) is also later.
- CV reorder of entries, URL validation messages and unsaved-changes prompts
  are nice-to-haves, not blockers.

## Verification

- `flutter analyze`: 0 errors, 0 warnings (132 pre-existing info notices).
- `flutter test`: 182 passing (includes focus and PDF smoke tests).
- Public CV sample rendered and checked in a browser at desktop width.
