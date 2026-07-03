---
name: navbar-keepalive-sw-interception
description: navbar's aithne keepalive fires a cross-origin remint POST that consumer service workers can intercept and break; how to exempt it
metadata:
  type: reference
---

`lucos_navbar` `keepalive.js` (`initKeepalive(aithneOrigin)`, gated on the `<lucos-navbar aithne-origin="…">` attribute) fires a **credentialed cross-origin** `POST <aithneOrigin>/auth/remint` (`fetch(url,{method:'POST',credentials:'include'})`) every 10 min + on focus/visibilitychange/submit. Below the 15-min aithne_session TTL.

**Hazard:** a service worker intercepts EVERY fetch from its controlled pages — including cross-origin. So any consumer whose SW `fetch` handler calls `event.respondWith(...)` unconditionally routes the remint through app logic. Failure modes seen (survey navbar#180, 2026-06-25):
- **Hard break** (seinn): SW's `["POST","PUT","DELETE"]` branch queues the remint into the offline write-queue (`restful-queue`) *before* any origin check → remint never reaches aithne. Fires the instant the consumer wires `aithne-origin`.
- **Soft/masking** (notes): SW falls through to `fetch(request)` so happy path works, but a catch-all that returns an HTML error page (status 200) on fetch failure makes keepalive read `resp.ok=true` → false `session-active` (silent session loss, false-green indicator).

**Fix shape:** targeted bypass of the aithne origin (or cross-origin `/auth/*`) as the FIRST statement in the handler — mirroring the `am.l42.eu` escape-hatch SWs already hand-roll for the cross-origin time service. Must sit *before* any method/POST branch. **NOT a blanket cross-origin bypass** — seinn caches cross-origin `track.url`/image URLs for offline playback; a blanket bypass regresses that. The recurring root cause is the same as `am.l42.eu`: SWs naively intercepting cross-origin calls they don't own; a navbar README integration requirement would stop future consumers repeating it.

Estate fact (2026-06-25): of all aithne remint consumers, only `lucos_notes` and `lucos_media_seinn` have an intercepting SW. See [[project_aithne_migration_guide]], [[reference_service_worker_ui_as_system_component]], [[reference_escape_hatch_design_pattern]].

**Third failure mode — keepalive never *initialises* (notes, 2026-07-03, #445/#447).** `initKeepalive` is gated on the `<lucos-navbar aithne-origin="…">` attribute being non-empty. In an offline-first PWA the returning user's page HTML is rendered **client-side by the service worker** (`populateTemplate(data)`), NOT the server — so the server's `res.locals.aithne_origin` injection is bypassed and the attribute renders `aithne-origin=""`. Keepalive never starts → 15-min session expires unrefreshed → login bounce. SRE evidence: 0 remints from notes over 3+ days vs 160 from seinn (server-renders every page), same navbar version + `AITHNE_ORIGIN`. **Generalises: any server-injected `res.locals` global silently renders empty on a SW client-render path** — a server/SW render-parity gap, not specific to aithne. Fix (#447): make the SW render path supply the globals — recommended an unauthenticated dynamic `/config.json` (must be dynamic; `AITHNE_ORIGIN` is env-varying), cached at SW `install`, merged into `populateTemplate` (`{...config, ...data}`). This failure mode is DISTINCT from the interception one above (that's about the remint POST being intercepted once fired; this is the keepalive never firing because the attribute is empty).
