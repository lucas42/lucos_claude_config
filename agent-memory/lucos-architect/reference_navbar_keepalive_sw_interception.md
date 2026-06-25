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
