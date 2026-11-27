# Custom domain — livocal.app

Status: domain purchased 2026-11-28. Code is ready; DNS + Render settings
still need one manual step each.

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

1. Registrar name (so the exact DNS screen can be written down).
2. The A/CNAME values Render displays for the service.
3. Confirm `www` should redirect to the apex (recommended).
