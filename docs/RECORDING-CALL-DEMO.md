# Real call demo — recording guide

The landing page has a "This is a real Livocal call" section that stays
**hidden until the files exist**, so shipping without them is safe.

## Where the files go

```
backend/public/site/media/call-demo.mp4          required
backend/public/site/media/call-demo-poster.jpg   optional (first frame)
```

Both are served from `/site/media/…`. Commit them and push; the section appears
on the next deploy. No code change is needed.

## What to record (20–30 seconds)

Show the product doing the thing it is sold for:

1. Open the app and start a **translated call** to a second phone.
   - Speaker A: Bangla, Speaker B: English (or any pair you like).
2. Say two or three short sentences each — a real exchange:
   - “Can you start next week?” → বাংলায় শোনাচ্ছে
   - “হ্যাঁ, পরের সপ্তাহে শুরু করতে পারব” → in English
3. Let the translation finish each time. Do not talk over the silence.
4. End with the call summary card (if it appears) or the call timer.

Do **not** show: personal chats, phone numbers, wallet balances, another
person's face without permission, or anything you would not put on a billboard.

## How to capture

**Option 1 — Android built-in (recommended)**
1. Swipe down → **Screen recorder** → enable **Microphone** and **Media sounds**
   (some phones call it “Internal audio”).
2. Put the call on **speaker**, start recording, then run the call.
3. Stop, trim the first/last second, export MP4.

**Option 2 — adb (pixel-perfect, no touch markers)**

```bash
adb shell screenrecord --bit-rate 6000000 --time-limit 40 /sdcard/call-demo.mp4
adb pull /sdcard/call-demo.mp4 backend/public/site/media/call-demo.mp4
```

`screenrecord` does not capture internal audio; record the mic separately and
merge, or use Option 1.

## Quality targets

| Item | Target |
|---|---|
| Length | 20–30 s |
| Resolution | 720×1280 or 1080×1920 (portrait is fine) |
| Frame rate | 30 fps |
| File size | ≤ 6 MB |
| Audio | clear, both sides audible |
| Format | MP4 / H.264 + AAC |

Compress if needed:

```bash
ffmpeg -i input.mp4 -vf "scale=720:-2" -c:v libx264 -crf 28 -preset slow \
       -c:a aac -b:a 96k call-demo.mp4
```

## Poster (optional but nice)

```bash
ffmpeg -i call-demo.mp4 -ss 00:00:02 -frames:v 1 -q:v 4 call-demo-poster.jpg
```

Without it the page uses the default `/static/og-image.png` banner.

## Behaviour on the page

- `preload="none"` — the video is not downloaded until the visitor presses play
  (keeps the landing page fast).
- A big **Play the call** button sits over the poster; it hides while playing
  and returns on pause/end.
- The section heading, copy and button label are translated into all 7 UI
  languages.
