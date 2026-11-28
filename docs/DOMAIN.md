# Custom domain — livocal.app

Status: **DNS live, TLS issued, domain verified — 2026-11-28.**

| Check | Result |
|---|---|
| `livocal.app` A | `216.24.57.16`, `216.24.57.18` (Render) |
| `www` | CNAME → `livocal-relay.onrender.com`, Render 301 → apex |
| `https://livocal.app/health` | 200 |
| `/u`, `/book`, `/cv`, `/room`, `/app` | served on the custom domain |
| Render env `PUBLIC_BASE_URL` | optional — the code now defaults to `https://livocal.app` |
| Auto-deploy | **working via `RENDER_DEPLOY_HOOK_URL`** (verified 2026-11-28 03:02) |

- Render service: `livocal-relay` → `https://livocal-relay.onrender.com`
- Public domain: `https://livocal.app` (`www` → same service)
- Old links keep working: HTML pages on `*.onrender.com` return **301** to
  `livocal.app` once `PUBLIC_BASE_URL` is set.

---

## 1. Tell Render about the domain

Render Dashboard → **livocal-relay** → **Settings** → **Custom Domains**

Add both:

```
livocal.app
www.livocal.app
```

Render then shows the exact DNS records to create. They are one of:

| Type | Name | Value |
|---|---|---|
| `A` (or `ALIAS`/`ANAME` if your DNS supports it) | `@` | Render's provided IP / target |
| `CNAME` | `www` | `livocal-relay.onrender.com` |

> Render normally asks for an **A record** on the apex and a **CNAME** on `www`.
> If your DNS provider supports `ALIAS`/`ANAME`/`CNAME flattening`
> (Cloudflare, Namecheap "ALIAS", DNSimple, Route 53 "Alias"), prefer that —
> it survives Render IP changes.

## 2. Add the records at the registrar

Use the values Render shows, not the ones in this doc — Render may rotate the
IP per service.

```
@     A        <Render A record IP>
www   CNAME    livocal-relay.onrender.com
```

Do **not** add MX / TXT mail records unless we start sending email.

## 3. Set the canonical origin on Render

Render → **livocal-relay** → **Environment** → add:

```
PUBLIC_BASE_URL = https://livocal.app
```

This single value:

- makes every generated link (profile, booking, invoice, proposal, CV, guest
  room, `/app` hub) use `https://livocal.app`;
- turns on the 301 redirect from `*.onrender.com` to the custom domain;
- updates the OpenRouter `HTTP-Referer`.

Then **Manual Deploy** the latest commit so the new code is live.

## 4. TLS

Render issues and renews the certificate automatically after DNS verifies
(usually 5–30 minutes). No action needed.

## 5. Verify

```bash
curl -I https://livocal.app/health                 # 200
curl -I https://livocal.app/u/shojibahmed          # 200
curl -I https://livocal.app/app/shojibahmed        # 200
curl -I https://livocal.app/room/shojibahmed       # 200
curl -I https://livocal.app/manifest.webmanifest   # 200, application/manifest+json
curl -I https://livocal-relay.onrender.com/u/shojibahmed   # 301 -> livocal.app
```

## 6. How the app behaves

`AppConfig` tries `https://livocal.app/health` at startup:

- **200** → all API + WebSocket traffic uses the custom domain;
- **DNS/HTTP error** → falls back to `https://livocal-relay.onrender.com`
  automatically, so a DNS mistake can never lock users out;
- **timeout** (free instance asleep) → keeps the custom domain.

Override for local testing:

```bash
flutter run --dart-define=RELAY_URL=http://10.0.2.2:3000
```

## 7. What is still needed from the owner

1. Nothing for the domain — it is live and auto-deploys now.
2. Never disable the Render subdomain — the app uses it as an automatic
   fallback when the domain fails a health check (API and WebSocket routes on
   `*.onrender.com` are never redirected).
3. (Later, before Play release) add `ANDROID_CERT_SHA256` with the release
   keystore fingerprint — `/.well-known/assetlinks.json` starts answering and
   `https://livocal.app/u/<name>` can open the app directly.

## 8. Auto-deploy

Push to `main` → `Deploy Firestore Rules & Trigger Live Sync` →
`RENDER_DEPLOY_HOOK_URL` → Render builds in ~1–3 minutes.
Verified end to end on 2026-11-28; `RENDER_API_KEY` is no longer used.

## 8. SEO / sharing basics now served

| Route | Purpose |
|---|---|
| `/robots.txt` | crawl rules + sitemap pointer |
| `/sitemap.xml` | home, legal pages and every published profile |
| `/favicon.ico` | 301 to the 192px icon |
| `/static/og-image.png` | default 1200×630 social preview |
| `/.well-known/assetlinks.json` | Android App Links (needs the SHA-256 env) |

Profile and CV pages now emit **absolute** `canonical` / `og:url` / `og:image`
values, so link previews resolve on every platform.
