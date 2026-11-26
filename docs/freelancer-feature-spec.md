# Livocal for Freelancers — Feature Specification (2026-11-26)

> উদ্দেশ্য: ফ্রিল্যান্সার যেন **বিদেশি ক্লায়েন্টের সাথে নিজের ভাষায় কথা বলে কাজ নিতে** পারে,
> আর পুরো ক্লায়েন্ট-রিলেশনশিপ (নোট, কোট, ইনভয়েস, ফলো-আপ) এক জায়গায় সামলাতে পারে।
> এই ডকুমেন্টে প্রতিটি ফিচারের **কী, কেন, কীভাবে কাজ করবে (ধাপে ধাপে), ডেটা মডেল,
> API/AI, এজ-কেস, নির্ভরতা, খরচ ও গ্রহণযোগ্যতার মান** লেখা আছে।

---

## 0. আজ কী আছে (ভিত্তি)

| বিল্ডিং ব্লক | বর্তমান অবস্থা |
|---|---|
| চ্যাট | ১:১ Firestore (`chats/{uid}/messages`), অ্যাটাচমেন্ট, রিপ্লাই, সার্চ |
| কল | WebRTC direct + Gemini 3.5 Live Translate (রিলে), Minuten billing |
| অনুবাদ | স্পিকার যা বলে → অন্য পাশে তার ভাষায় (TTS নেই; মডেলের নিজের ভয়েস) |
| ট্রান্সক্রিপ্ট | `calls/{id}/transcripts` — **কল শেষে মুছে যায়** (প্রাইভেসি) |
| ওয়ালেট | ট্রায়াল ২০ মিনিট, মিনিট রিচার্জ, P2P ট্রান্সফার |
| কন্টাক্ট | ডিভাইস কন্টাক্ট সিঙ্ক, Livocal ইউজার ম্যাচিং |
| লোকাল ক্যাশ | Isar (messages, users, contacts) + Firestore offline cache |
| প্রোফাইল | নাম, ছবি, About (শুধু ডিভাইসে), ভাষা |
| রিলে | Render + Metered TURN + App Check middleware |

**অভাব:** ক্লায়েন্ট কে, কী কাজ, কত রেট, কী কথা হলো, কত টাকা বাকি — এসব মনে রাখার
কোনো ব্যবস্থা নেই। নিচের ফিচারগুলো ঠিক সেই ফাঁকটাই ভরে।

---

## 1. আর্কিটেকচার নীতি (সব ফিচারে প্রযোজ্য)

1. **লোকাল-ফার্স্ট:** নতুন সব ডেটা আগে Isar-এ, তারপর Firestore sync। অফলাইনেও কাজ করবে।
2. **প্রাইভেসি ডিফল্ট:** ক্লায়েন্টের ডেটা (নোট, রেট) কখনো পাবলিক নয়; শেয়ার লিংক আলাদা ও opt-in।
3. **নো PII অন সার্ভার:** ফোন নাম্বার/নোট সার্ভারে প্লেইনটেক্সটে রাখা যাবে না (বর্তমান নীতি)।
4. **৭ ভাষা:** প্রতিটি নতুন স্ক্রিন/লেবেল `app_localizations.dart`-এ key সহ।
5. **রিলে = AI + ওয়েব:** Gemini কল, PDF/সামারি রেন্ডার, পাবলিক পেজ — সব রিলেতে।
6. **মডেল বদলালে ফিচার ভাঙবে না:** AI আউটপুট সবসময় fallback সহ।

---

## 2. P0 — এগুলো ছাড়া ফ্রিল্যান্সার টুল হিসেবে বিক্রি হবে না

### 2.1 ক্লায়েন্ট CRM (ট্যাগ, নোট, স্টেজ, ফলো-আপ)

**কী:** প্রতিটি কন্টাক্টের সাথে ক্লায়েন্ট-স্টেটাস, ডিল-স্টেজ, নোট আর পরের ফলো-আপ তারিখ।

**ধাপে ধাপে UX**
1. চ্যাট খুললে app bar-এর নামের নিচে ছোট ট্যাগ: `Prospect` / `Client` / `Archived`
2. ট্যাগে ট্যাপ → bottom sheet "Client details"
3. Sheet-এ:
   - **Tag**: Prospect / Client / Archived (segmented)
   - **Stage**: New → Negotiating → Active → Paid (chips)
   - **Rate**: পরিমাণ + currency (USD/BDT/…) + প্রতি ঘণ্টা/প্রজেক্ট
   - **Notes**: multiline + timestamp list (শেষ ৫টা দেখা যায়)
   - **Follow-up**: date picker → লোকাল নোটিফিকেশন + হোমে "Due today" কার্ড
4. চ্যাট লিস্টে ট্যাগ-ব্যাজ (Prospect হলে নীল, Client হলে সবুজ)
5. Contacts পিকারে "Clients" ফিল্টার

**ডেটা মডেল**
```text
users/{uid}/crm/{peerUid}
  tag: 'prospect' | 'client' | 'archived'
  stage: 'new' | 'negotiating' | 'active' | 'paid'
  rateAmount: number
  rateCurrency: 'USD' | 'BDT' | ...
  rateBasis: 'hourly' | 'project'
  notes: [{ text: string, at: ISO string }]   // সর্বোচ্চ ৫০টি
  lastContactedAt: ISO | null
  followUpAt: ISO | null
  updatedAt: ISO
```
লোকাল মিরর: Isar `CrmEntry` (নতুন collection) — অফলাইনে পড়া/লেখা।

**নিয়ম**
- শুধু ওই uid-এর নিজের subcollection; rules: `uid == auth.uid`।
- `lastContactedAt` অটো আপডেট হবে ওই চ্যাটে মেসেজ পাঠালে/কল করলে।
- নোট ৫০টির বেশি হলে পুরোনোটা বাদ (или fold)।

**কোড ছোঁয়া:** `chat.dart` app bar, `contact_profile_screen.dart`, `contacts_controller.dart`,
নতুন `crm_service.dart`, `isar_db.dart`।

**খরচ:** ২–৩ দিন · **নির্ভরতা:** কিছু নেই

**গ্রহণযোগ্যতা:** tag বদলালে চ্যাট লিস্টে সাথে সাথে দেখা যায়; অফলাইনে নোট লেখা যায়, অনলাইনে গেলে sync হয়।

---

### 2.2 প্রফেশনাল প্রোফাইল + শেয়ার লিংক (ওয়েবে ক্লায়েন্ট দেখবে)

**কী:** ফ্রিল্যান্সারের স্কিল, রেট, availability, ভাষা, পোর্টফোলিও — একটা পাবলিক পেজ, অ্যাপ ছাড়াই।

**ধাপে ধাপে UX**
1. Settings → "Freelancer profile" → ফর্ম: headline, bio, skills (chip input), languages,
   hourly rate, availability (Full-time / Part-time / Busy), portfolio links
2. "Publish my page" switch (default **off**) → নিশ্চিতকরণ dialog
3. Preview + **Share link** (`https://livocal-relay.onrender.com/p/<slug>`)
4. চ্যাটে/ইনভাইটে পাঠানো যায়; QR কোডও (বর্তমান QR স্ক্রিন পুনর্ব্যবহার)
5. ক্লায়েন্ট ব্রাউজারে খুললে: প্রোফাইল, রেট, "Call / Message" বাটন

**ডেটা মডেল**
```text
profiles/{uid}                      // পাবলিক, rules: আগে auth লাগবে না (শুধু published হলে read)
  slug: string (unique, 6–24 chars)
  displayName, headline, bio
  skills: string[]
  languages: [{ code, level }]
  rate: { amount, currency, basis }
  availability: 'full_time' | 'part_time' | 'busy'
  portfolio: [{ label, url }]
  avatarUrl
  published: bool
  updatedAt
```
**রিলে রুট:** `GET /p/:slug` → HTML (SSR, mobile-friendly, OG tags)। `GET /api/public/profile/:slug` → JSON।
slug অদ্বিতীয় করতে `profiles_slug/{slug}` doc (lease pattern)।

**নিরাপত্তা/গোপনীয়তা**
- `published=false` হলে 404।
- ফোন/ইমেইল কখনো পাবলিকে নয়; যোগাযোগ শুধু "Call in app" বা booking।
- রেট দেখানো opt-in আলাদা।

**কোড ছোঁয়া:** নতুন `freelancer_profile_screen.dart`, রিলেতে `/p/:slug` + JSON API, Firestore rules।
**খরচ:** ৩–৪ দিন · **নির্ভরতা:** রিলে deploy

**গ্রহণযোগ্যতা:** লিংক ক্লায়েন্টের ব্রাউজারে খোলে, অ্যাপ ছাড়া; unlisted থেকে গেলে 404।

---

### 2.3 কল সামারি + অ্যাকশন আইটেম (Gemini text)

**কী:** অনুবাদিত কল শেষে এক প্যারায় সারাংশ + সিদ্ধান্ত + টাস্ক — ক্লায়েন্টকে পাঠানো যায়।

**ধাপে ধাপে UX**
1. প্রথমবার কল শুরুর আগে (একবারই): "Save call summary after calls?" → Yes/No
2. কল চলাকালীন ট্রান্সক্রিপ্ট মেমরিতে জমা হয় (ইতিমধ্যে হচ্ছে)
3. কল শেষ → end-call sheet-এ নতুন ট্যাব **Summary** (লোডিং → টেক্সট)
4. বাটন: **Copy**, **Share** (চ্যাটে পাঠাও), **Save to CRM** (ক্লায়েন্টের নোটে)
5. চ্যাটের কল-লগ এন্ট্রি থেকেও পরে খোলা যায়

**কীভাবে কাজ করবে (টেকনিক্যাল)**
- কলে transcript ফায়ারস্টোরে লেখা হচ্ছে; কল শেষে ডিলিট হওয়ার **আগে** শেষ ৬০টি এন্ট্রি তুলে নেওয়া
- রিলেতে `POST /api/call/summary` → Gemini text model (বর্তমান `gemini-2.5-flash`)
- প্রম্পট (খসড়া):
  ```
  You are a meeting summarizer. From this translated call transcript, produce:
  1) 3-line summary 2) decisions 3) action items with owner 4) client's budget/timeline hints.
  Output JSON: {summary, decisions[], actionItems[], clientHints}
  Language: Bengali + English both (bilingual output).
  ```
- রেসপন্স `calls/{callId}/summary`-তে সেভ (শুধু সারাংশ, raw ট্রান্সক্রিপ্ট নয়)
- raw transcript আগের মতোই ২৪ ঘণ্টায় মুছে যাবে

**ডেটা মডেল**
```text
calls/{callId}/summary
  summary: string
  decisions: string[]
  actionItems: [{ text, owner: 'me'|'client' }]
  langPair: { a, b }
  durationSeconds: number
  createdAt: ISO
```
rules: `isCallParty(resource.data)`-এর বদলে প্যারেন্ট call-এর participant check (get)।

**এজ-কেস**
- ২০ সেকেন্ডের কল → সারাংশ বানাবে না (< ৬০ সে skip)
- ট্রান্সক্রিপ্ট খালি → "No transcript to summarize"
- AI ফেইল → কাঁচা ট্রান্সক্রিপ্ট কপি করার fallback (মেমরি থেকে)

**খরচ:** ২–৩ দিন · **নির্ভরতা:** 2.5-এর consent UI
**গ্রহণযোগ্যতা:** ২ মিনিটের অনুবাদ কলের পর বাংলা+ইংরেজি সারাংশ, টাস্ক-সহ; কোনো raw ট্রান্সক্রিপ্ট সার্ভারে থাকে না।

---

### 2.4 ট্রান্সক্রিপ্ট এক্সপোর্ট (TXT / PDF)

**বাস্তব সীমা (গুরুত্বপূর্ণ):** বর্তমান ডিজাইনে **কল শেষে ট্রান্সক্রিপ্ট মুছে যায়** (প্রাইভেসির প্রতিশ্রুতি)।
তাই এক্সপোর্ট করতে হলে কল শেষ হওয়ার **আগে/মুহূর্তে** করতে হবে, অথবা ব্যবহারকারীর সম্মতিতে লোকাল কপি রাখতে হবে।

**দুই অপশন (সিদ্ধান্ত দরকার, §8 দেখুন)**
- **A (নিরাপদ, প্রস্তাবিত):** শুধু সারাংশ রাখা; সম্পূর্ণ ট্রান্সক্রিপ্ট শুধু কল শেষের স্ক্রিনে "Export once"
  → ফাইল তৈরি হয় ডিভাইসে, সার্ভারে কিছু জমা হয় না।
- **B:** opt-in "Keep transcript on this device for 7 days" → Isar-এ এনক্রিপ্টেড কপি; Settings-এ মুছে ফেলা যায়।

**ফরম্যাট**
```
Livocal call transcript
Date: 26 Nov 2026 · 14:02 · Duration 12:41 · বাংলা ⇄ English
───
[14:02:11] আমি (বাংলা): ...
[14:02:18] Alex (English): ...
```
PDF: রিলেতে `POST /api/export/transcript` (হয় Flutter `pdf` প্যাকেজ লোকালি)।

**খরচ:** ১–২ দিন · **নির্ভরতা:** সিদ্ধান্ত A/B

---

### 2.5 কোটেশন / ইনভয়েস + "Paid" মার্ক

**কী:** কল/চ্যাটেই ক্লায়েন্টকে দাম বলার বদলে পরিষ্কার কোট/ইনভয়েস পাঠানো, আর পেমেন্ট এলে সেটা মিলিয়ে নেওয়া।

**ধাপে ধাপে UX**
1. চ্যাট → ⋮ → **Quote / Invoice**
2. ফর্ম: ক্লায়েন্ট (auto), আইটেম (desc, qty, rate), currency, tax %, discount, due date, notes
3. লাইভ টোটাল; **Preview** (PDF) → **Send in chat**
4. চ্যাটে কার্ড আসে: `INV-2026-014 · $450 · Due 3 Dec` + View/Download
5. ক্লায়েন্ট P2P পেমেন্ট পাঠালে (বর্তমান "💰 Payment sent" মেসেজ) → অ্যাপ amount+note মিলিয়ে
   ইনভয়েস **Paid** মার্ক করার প্রস্তাব দেয় (এক ট্যাপ)
6. "Invoices" স্ক্রিনে ফিল্টার: Draft / Sent / Paid / Overdue

**ডেটা মডেল**
```text
users/{uid}/invoices/{invoiceId}
  number: 'INV-2026-014'
  clientUid
  items: [{ description, qty, rate }]
  currency, taxPct, discount, total
  status: 'draft' | 'sent' | 'paid' | 'void'
  dueDate, notes
  createdAt, sentAt, paidAt
  paymentMsgId?      // কোন P2P মেসেজের সাথে মিলেছে
```
মেসেজে ফাইল: attachment type `document` + `metadata.invoiceId`।

**নিয়ম**
- নাম্বারিং: `users/{uid}/counters/invoice` (transaction increment) — অফলাইনে লোকাল সিকোয়েন্স।
- PDF: একই টেমপ্লেট ক্লায়েন্ট/সার্ভার দুই জায়গায় নয় — **এক জায়গায়** (রিলে) বানিয়ে বাইট পাঠানো।
- Overdue = dueDate + status sent → merah badge।

**খরচ:** ৪–৫ দিন · **নির্ভরতা:** 2.1 CRM, P2P পেমেন্ট ফরম্যাট

**গ্রহণযোগ্যতা:** কোট পাঠানো → ক্লায়েন্ট পেমেন্ট → এক ট্যাপে Paid; PDF দুই প্ল্যাটফর্মে একই।

---

### 2.6 কুইক রিপ্লাই টেমপ্লেট

**কী:** বারবার লেখা লাইনগুলো (পিচ, রেট, availability, ধন্যবাদ) এক ট্যাপে।

**UX**
- Composer-এ ⚡ আইকন → টেমপ্লেট শিট (ক্যাটাগরি: Pitch / Rate / Availability / Closing)
- টেমপ্লেটে ট্যাপ → টেক্সট ইনপুটে বসে (পাঠায় না, এডিট করা যায়)
- সেটিংসে নতুন টেমপ্লেট তৈরি/এডিট/মুছে ফেলা

**ডেটা**
```text
users/{uid}/quick_replies/{id}
  title, body, category, language ('bn'|'en'|…)
```
ডিফল্ট সেট অ্যাপে bundled (৭ ভাষা), প্রথম চালুতে import।

**খরচ:** ১–২ দিন · **নির্ভরতা:** কিছু নেই

---

### 2.7 Booking লিংক

**কী:** "কখন কথা বলবেন?" — ক্লায়েন্ট নিজেই স্লট বেছে নেবে, দুই পাশে রিমাইন্ডার।

**UX**
1. Settings → Availability: সপ্তাহের দিন + সময় রেঞ্জ + timezone (ডিভাইস থেকে)
2. Share booking link → `https://livocal-relay.onrender.com/book/<slug>`
3. ক্লায়েন্ট পেজে স্লট বাছবে → নাম + (ঐচ্ছিক) WhatsApp/email → Confirm
4. দুই পাশে FCM: "Rahim wants to talk on 27 Nov, 4:00 PM"
5. অ্যাপে "Bookings" তালিকা → Confirm / Reschedule / Cancel
6. Confirm হলে CRM-এ follow-up সেট হয়

**ডেটা**
```text
users/{uid}/availability/{dayOfWeek}
  slots: [{ start: '09:00', end: '12:00' }]
bookings/{id}
  hostUid, guestName, guestContact, startAt, endAt, status: pending|confirmed|cancelled, createdAt
```
দ্বন্দ্ব (double-booking) প্রতিরোধ: একই সময়ে pending থাকলে block।

**সীমা:** প্রথম ভার্সনে Google Calendar sync নেই (আলাদা OAuth)।
**খরচ:** ৪–৫ দিন · **নির্ভরতা:** 2.2 slug/পাবলিক পেজ

---

## 3. P1 — ডিফারেনশিয়েটর

### 3.1 ক্লায়েন্ট পোর্টাল (ওয়েব, ইনস্টল ছাড়া)

**কী:** ক্লায়েন্ট অ্যাপ ইনস্টল না করেই লিংক থেকে চ্যাট/কল/অনুবাদে যুক্ত হবে — সবচেয়ে বড় কনভার্সন বুস্ট।

**কীভাবে**
- হোস্ট শেয়ার করে **invite link** (একবারের, ২৪ ঘণ্টা): `/join/<token>`
- পেজ: নাম দিয়ে ঢোকে → WebRTC room (রিলে broker) → মাইক পারমিশন → অনুবাদ চালু
- ট্রান্সলেশন একই রিলে পথে; ভয়েস Gemini-র নিজের
- সিকিউরিটি: token এক-ব্যবহার, room-bound, রেট লিমিট; হোস্ট যেকোনো সময় বাতিল

**সীমা/ঝুঁকি:** মোবাইল ব্রাউজারে WebRTC + mic permission; iOS Safari-তে audio quirks।
**খরচ:** ১০–১৫ দিন (আলাদা ওয়েব অ্যাপ) · **নির্ভরতা:** রিলে room broker, TURN

---

### 3.2 বিলেবল টাইম ট্র্যাকিং

**কী:** কোন ক্লায়েন্টে কত মিনিট অনুবাদ/কল খরচ হলো, সপ্তাহে কত আয়।

**কীভাবে**
- `call_billing_records`-এ ইতিমধ্যে callId, minutes, cost আছে → প্রতি কলের peerUid জানা থাকলে
  ক্লায়েন্ট-ভিত্তিক অ্যাগ্রিগেট করা যায়
- Reports স্ক্রিন: This week / This month · per client · total minutes · estimated bill
- CSV export (অ্যাডমিন প্যানেলের মতো)

**ডেটা:** নতুন `users/{uid}/time_entries` (callId, clientUid, minutes, at) — কল শেষে রিলে/ক্লায়েন্ট লিখবে।
**খরচ:** ২–৩ দিন · **নির্ভরতা:** 2.1 CRM

---

### 3.3 রিভিউ / রেটিং + Verified ব্যাজ

**কী:** কাজ শেষে ক্লায়েন্ট ১–৫ স্টার + কমেন্ট; প্রোফাইলে দেখায়।

**নিয়ম**
- রিভিউ দেওয়া যাবে শুধু **সম্পন্ন কল** (≥ ২ মিনিট) থাকলে — সার্ভার যাচাই করবে
- একই ক্লায়েন্ট একই ফ্রিল্যান্সারকে ৩০ দিনে একবার
- Verified = ফোন ভেরিফায়েড (আছে) + অন্তত ১টি রিভিউ + প্রোফাইল published

**ডেটা:** `reviews/{id}` {raterUid, targetUid, callId, rating, comment, createdAt}; aggregate `profiles/{uid}.ratingAvg/ratingCount`।
**খরচ:** ৩ দিন · **নির্ভরতা:** 2.2, 2.3

---

### 3.4 জব পাইপলাইন (Prospect → Negotiating → Active → Paid)

**কী:** CRM স্টেজগুলোর কানবান ভিউ — কে কোথায় আছে এক নজরে।

**UX**
- Freelance ট্যাব → ৪ কলাম, কার্ডে নাম + রেট + শেষ কথা
- ড্র্যাগ/ট্যাপে স্টেজ বদল (ট্যাপ নিরাপদ)
- ফিল্টার: due follow-up, biggest rate

**ডেটা:** একই `users/{uid}/crm/*` — stage ফিল্ডই ভিত্তি।
**খরচ:** ২–৩ দিন · **নির্ভরতা:** 2.1

---

### 3.5 ফলো-আপ রিমাইন্ডার

**কী:** "৩ দিন ধরে রিপ্লাই নেই" — অ্যাপ নিজেই মনে করিয়ে দেবে।

**কীভাবে**
- local: `followUpAt` + device notification (নির্ভরযোগ্য, অফলাইনেও)
- server: দিনে একবার digest (ঐচ্ছিক) — cron দরকার (Render paid) বা অ্যাপ খোলার সময় চেক
**খরচ:** ১–২ দিন · **নির্ভরতা:** 2.1

---

### 3.6 AI প্রপোজাল অ্যাসিস্ট্যান্ট

**কী:** কল সামারি + প্রোফাইল + ক্লায়েন্টের চাহিদা → ড্রাফট প্রপোজাল/কভার লেটার।

**কীভাবে**
- `POST /api/ai/proposal` → ইনপুট: summary, rate, skills, clientHints
- আউটপুট: প্রপোজাল (headline, scope, timeline, price, terms) দুই ভাষায়
- ইউজার এডিট করে PDF/চ্যাটে পাঠাবে (2.5-এর ইনভয়েস টেমপ্লেট পুনর্ব্যবহার)

**খরচ:** ২–৩ দিন · **নির্ভরতা:** 2.3, 2.5

---

## 4. P2 — পরে

| ফিচার | সারমর্ম | খরচ |
|---|---|---|
| টিম/এজেন্সি | workspace, সদস্য, শেয়ার্ড ইনবক্স/ক্লায়েন্ট | ১০+ দিন |
| অ্যানালিটিক্স | রেসপন্স টাইম, কল→ডিল কনভার্সন, প্রতি ক্লায়েন্টে মিনিট | ৩–৪ দিন |
| উইথড্রয়াল/ট্যাক্স | P2P আয়ের বিবৃতি, CSV/PDF, সময়ভিত্তিক সারাংশ | ২–৩ দিন |

---

## 5. ধাপে ধাপে রোডম্যাপ

| ধাপ | কী | দিন | নির্ভরতা |
|---|---|---|---|
| **F1** | CRM (2.1) + কুইক রিপ্লাই (2.6) | ৪–৫ | — |
| **F2** | প্রফাইল + শেয়ার লিংক (2.2) | ৩–৪ | রিলে |
| **F3** | কল সামারি (2.3) + ট্রান্সক্রিপ্ট নীতি (2.4) | ৩–৪ | F1 |
| **F4** | কোট/ইনভয়েস (2.5) | ৪–৫ | F1 |
| **F5** | Booking (2.7) + পাইপলাইন (3.4) + ফলো-আপ (3.5) | ৬–৭ | F1, F2 |
| **F6** | টাইম ট্র্যাকিং (3.2) + রিভিউ (3.3) | ৫ | F3 |
| **F7** | ক্লায়েন্ট পোর্টাল (3.1) | ১০–১৫ | TURN, রিলে |
| **F8** | AI প্রপোজাল (3.6) | ২–৩ | F3, F4 |

মোট P0+P1 ≈ ৬–৮ সপ্তাহ (এক ডেভেলপার)।

---

## 6. ক্রস-কাটিং সিদ্ধান্ত

### 6.1 প্রাইভেসি ও সম্মতি
- CRM নোট/রেট **শুধু মালিক** দেখবে; রিলেতে কোনো নোট যায় না (AI প্রপোজালে শুধু যা ব্যবহারকারী দেবে)
- কল সামারি সেভ করার আগে **প্রথমবার জিজ্ঞাসা**
- ট্রান্সক্রিপ্ট ডিফল্ট ephemeral (বর্তমান নীতি বজায়)

### 6.2 i18n
প্রতিটি নতুন স্ক্রিনের টেক্সট ৭ ভাষায় key; AI আউটপুট বাংলা+ইংরেজি।

### 6.3 অফলাইন
CRM, কুইক রিপ্লাই, ইনভয়েস ড্রাফট — Isar-এ; sync queue।

### 6.4 মনিটাইজেশন
- অনুবাদ মিনিট = বিদ্যমান ওয়ালেট
- ফ্রিল্যান্সার টুল (CRM/ইনভয়েস) ফ্রি রাখা যায় → ডিফারেনশিয়েটর
- ভবিষ্যতে Pro (আনলিমিটেড ক্লায়েন্ট/ইনভয়েস) — Play Billing দরকার

### 6.5 অ্যাডমিন
- নতুন `reviews`, `bookings`, `invoices` counters অ্যাডমিনে ভিজিবল করা (Reports/Users ট্যাবে পরে)

---

## 7. KPIs (সফলতা মাপার উপায়)

1. **Activation:** ইনস্টল → প্রথম CRM ট্যাগ বা প্রোফাইল publish
2. **Value:** প্রতি ইউজারে ট্রান্সলেটেড কল মিনিট / সপ্তাহ
3. **Retention:** সপ্তাহে ফিরে আসা ফ্রিল্যান্সার
4. **Conversion:** প্রোফাইল শেয়ার → ক্লায়েন্ট পেজ ভিজিট → বুকিং/কল
5. **Money:** ইনভয়েস Sent → Paid রেশিও

---

## 8. খোলা সিদ্ধান্ত (আপনার)

1. **ট্রান্সক্রিপ্ট নীতি** — (A) শুধু সারাংশ + একবার এক্সপোর্ট, নাকি (B) ৭ দিন লোকাল কপি?
2. **রেট পাবলিকে দেখাবেন?** — প্রোফাইল পেজে রেট opt-in করবেন কি?
3. **ইনভয়েস PDF** — রিলেতে বানাবেন (এক টেমপ্লেট) নাকি ডিভাইসে?
4. **ক্লায়েন্ট পোর্টাল** — এখনই (১–২ সপ্তাহ) নাকি P0 শেষ করে?
5. **Booking**-এ Google Calendar sync দরকার কি না (অতিরিক্ত OAuth)?

---

## 9. ঝুঁকি

| ঝুঁকি | প্রভাব | প্রশমন |
|---|---|---|
| AI সামারি ভুল/বেশি লম্বা | বিশ্বাস নষ্ট | প্রম্পটে JSON schema + দৈর্ঘ্য সীমা + এডিটযোগ্য |
| ফ্রি Render cold start | booking/সামারি দেরি | paid instance বা warm-up |
| ওয়েব পোর্টালে ব্রাউজার অডিও | কল ব্যর্থ | TURN + fallback "phone call" |
| ইনভয়েস ভুল টোটাল | টাকা ভুল | সার্ভার-সাইড হিসাব + ইউনিট টেস্ট |
| ডেটা বাড়লে Firestore খরচ | বিল বাড়ে | pagination, TTL, লোকাল ক্যাশ |
