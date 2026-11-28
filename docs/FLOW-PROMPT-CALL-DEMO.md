# Google Flow (Veo) prompt — Livocal call demo

Use this to generate the hero/landing video for the call experience. Keep it
**8 seconds**, 16:9, 1080p. The clip is a *simulation* for marketing — it must
never be labelled "real call".

## Prompt (copy-paste)

```
Cinematic close-up of a smartphone on a dark walnut desk. The screen shows a
live video call between two people: a South Asian man in a plain shirt and a
European woman with headphones. A small emerald "translated" badge sits in the
top-right. Live subtitles appear in two styles — Bengali script and English —
switching as each person speaks, with a thin emerald audio waveform pulsing
below them. Soft warm desk-lamp light from the left, deep navy background
(#04070D), emerald accents (#34D399), shallow depth of field, slow camera
push-in, no text overlays outside the app UI, photoreal, 35mm lens, subtle
film grain.
```

## Second shot (optional B-roll)

```
Over-the-shoulder shot of a man holding a phone during a call, his face softly
lit, the phone screen glowing emerald. He nods and speaks; on the screen the
other participant's subtitle changes from English to Bengali. Dark room, single
window light, shallow focus, handheld micro-movement, photoreal, 8 seconds.
```

## Negative prompt

```
no logos of other apps, no fake UI, no watermark, no distorted hands, no text
outside the interface, no bright white rooms, no stock-photo smiles
```

## After generating

1. Download the MP4 (H.264).
2. Trim to 8–12 seconds; keep the subtitle change in frame.
3. Put it at `backend/public/site/media/call-demo.mp4`.
4. Optional poster: `ffmpeg -i call-demo.mp4 -ss 00:00:02 -frames:v 1 -q:v 4 call-demo-poster.jpg`
5. Commit + push → the "Real call" section appears automatically.

> If the clip is AI-generated, change the section copy from
> "This is a real Livocal call" to "See how a Livocal call works" so the page
> never claims something untrue.
