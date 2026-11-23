# Premium chat, contact discovery, and phone entry — design

Date: 2026-11-23
Status: approved by owner ("sob issue gula solve koro, tmr recommended gula implement koro")

## Intent

The chat still reads as a WhatsApp clone: the bubble tail, the doodle wallpaper,
one flat bubble colour and no depth. Livocal's differentiator is live AI
translation, but the chat shows none of it. At the same time two daily-use
frictions remain: phone entry rejects a leading `0` (`+880 01775-290702`), and
the contact picker silently shows nothing when device-contacts permission has
not been granted — so contact discovery feels broken.

Owner goal: a chat that is recognisably Livocal (not WhatsApp), accepts phone
numbers with or without the trunk `0`, and lists Livocal users first with a
working invite path for everyone else.

## Goals

1. Chat identity: glass/gradient "Livocal" look in dark **and** light, no
   WhatsApp tail, no doodle wallpaper by default.
2. Translation visible where it matters: the inline translation ribbon becomes
   a first-class part of the bubble (it already exists; it gets the new skin).
3. Phone input: `01775-290702`, `+8801775290702`, `+880 01775-290702`,
   `8801775290702` all resolve to the same E.164 `+8801775290702`.
4. Contacts: permission requested explicitly, registered users listed first
   (name + avatar), unregistered device contacts listed under "Invite", with
   per-row invite action.
5. Keep every existing feature: wallpapers chosen by the user, chat translation
   settings, disappear timer, attachments, payments, call logs, search, pinned.

## Non-goals

- No E2E encryption claims (not implemented, and previously removed).
- No voice/TTS read-out of translated text in chat (no TTS dependency today).
- No rewrite of the message data model or Firestore schema.
- No iOS PushKit / call work in this change.

## Anti-goals

- A reskin that keeps the tail and wallpaper and only changes the accent colour.
- Accepting an invalid number silently by "guessing" the country.
- Breaking the offline chat cache when permission is denied.

## Constraints

- Existing Isar cache and Firestore message shape stay unchanged.
- `flutter analyze` must stay at 0 errors/0 warnings; `flutter test` green.
- Two-phone calls and translation paths must not be touched by chat styling.

## Approaches considered

A. **Minimal / Signal-like** — drop wallpaper, muted flat bubbles, brand accent
   only on outgoing. Cheap and calm, but reads as "plain", no identity.
B. **Livocal Glass** *(chosen)* — gradient mesh backdrop, translucent bubbles
   with a 1px edge, grouped message runs, floating glass composer, translation
   ribbon under the original text. Matches the product (translation) rather than
   imitating WhatsApp.
C. **Editorial / bubble-less** — avatar gutter cards, large date separators.
   Distinctive but breaks chat muscle memory and is the most work.

Approach A's restraint is kept inside B: no heavy shadows, no neon.

## Design

### 1. Phone normalisation (`lib/shared/utils/phone_normalizer.dart`)

Pure, testable helpers:

- `digitsOnly(raw)` — strip everything but digits.
- `toE164({required String countryCode, required String input})`
  1. strip formatting characters;
  2. if input starts with `+`: strip country code prefix when present, otherwise
     keep as-is and validate;
  3. if input already starts with the country code and the remainder does not
     start with `0`, treat as international;
  4. strip one leading trunk `0` (`01775…` → `1775…`);
  5. return `+<cc><national>`, or `null` when 8–15 digits are not satisfied.
- `nationalNumber(...)` — the part after the country code (stored in `Phone.number`).
- `candidates(raw)` — every matching key form (`+8801…`, `8801…`, `01…`, `1…`)
  used for contact/call lookups.

Wired into: login compose + validation, direct dial (call/chat), contact
matching, call-invite phone candidates, block-service candidates. A single
normaliser replaces the four ad-hoc `replaceAll('0')` code paths.

### 2. Contact discovery

Repository already returns both registered (`userId != null`) and unregistered
device contacts — it just never reaches the screen when permission is refused.
Changes:

- Picker requests permission on first build and exposes a permission state.
- Three states: `denied` (CTA "Allow contacts access"), `loading` (skeleton),
  `ready`.
- Sections: **On Livocal** (registered first, A–Z, avatar + language badge +
  online dot) and **Invite to Livocal** (device-only, phone shown, invite
  button sending the existing `shareMsg` via SMS/share).
- Registered rows open the chat; unregistered rows never create a dead chat.
- No `0`-duplicate phone strings: display uses `PhoneNormalizer.formatDisplay`.

### 3. Chat visual system

New widgets (kept small and reusable):

- `chat_backdrop.dart` — `ChatBackdrop`: dark = deep ink base with indigo/aqua
  radial blooms (~6% opacity); light = soft white with faint indigo blooms.
  User-selected wallpaper/colour preference still overrides it.
- `chat_bubble_shell.dart` — `ChatBubbleShell(isMe, roundTop, roundBottom)`:
  - outgoing: indigo→indigo-deep gradient, white text, 1px light edge;
  - incoming: translucent surface (white 8% dark / white 70% light) with a 1px
    border and no shadow stack;
  - radii: 20 all round, 6 on the side where the run continues
    (first/last of a run), no tail.
- `chat_composer.dart` — floating pill: emoji, field, attach, payment, mic/send
  in one translucent surface with a hairline border; keeps every existing
  callback from `ChatField`.
- `chat_date.dart` — date chip becomes a small glass pill.
- App bar: translucent surface + blur instead of solid indigo, title with
  avatar ring and status dot.

Bubble grouping: `ChatStream.buildMessageCard` already computes "first of a
run" (`special`); it additionally computes "last of a run" so the shell can
round the correct corners.

Translation ribbon: reuse the existing `_translatedContent` state and
`TranslationService.translateText`; restyle as a glass strip with a translate
icon, target-language label, and a copy action. Auto-translate behaviour based
on the existing per-chat preferences stays unchanged.

### 4. Verification

- `test/unit/phone_normalizer_test.dart` — BD/international/leading-zero/paste
  cases, invalid input, candidate generation.
- `test/unit/contact_sections_test.dart` — pure grouping/sorting helper:
  registered first, alphabetical, self excluded.
- `flutter analyze` (no errors/warnings) and `flutter test` green.
- Manual: chat in dark + light, permission-denied picker, phone login with and
  without leading `0`. Device behaviour is verified by the owner on the phone.

## Left to the builder

- Exact bloom positions/opacities and the bubble blur amount.
- Whether the composer shows mic or send by default (keeps current behaviour).
- Icon choices inside the new shells.
