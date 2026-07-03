---
name: pattern-pwa-sw-render-drops-aithne-origin
description: PWA service-worker client-render bypasses server-side res.locals injection → empty aithne-origin → dead navbar keepalive → re-login storm; diagnose via /auth/remint calls in router log
metadata:
  type: reference
---

Diagnosing "frequent re-login prompts" on an aithne consumer (first hit lucos_notes#445, 2026-07-03).

**Session model (aithne ADR-0003):** `aithne_session` = 15-min JWT cookie. Silent continuity relies on `lucos_navbar`'s background keepalive doing a credentialed `fetch()` to `aithne.l42.eu/auth/remint` every ~10 min (+ visibilitychange/focus), which re-mints a fresh 15-min cookie. Navbar reads the target from its `aithne-origin` attribute. If that attribute is empty/absent, keepalive NEVER fires → cookie expires every 15 min → middleware 302s to `/auth/login` on next interaction.

**Authoritative diagnostic = the router access log (`docker logs lucos_router` on avalon), NOT the app container log.** Router log persists across app redeploys (app log buffer is cleared on every deploy — the container-restart-log-buffer trap). Count per consumer, over the same window:
- `→ aithne.l42.eu/auth/login` = re-auth bounces (high = symptom)
- `→ aithne.l42.eu/auth/remint` = silent keepalive working (referer field tells you which consumer). **A consumer with 0 remints but many logins = its keepalive is dead.**
notes#445: notes = 553 login / **0 remint**; seinn = 160 remint (all 200), stays logged in. Every other integrated consumer remints; notes was the only one at zero.

**Root cause class — PWA service-worker client render silently drops server-injected template vars.** notes is offline-first: its SW (`src/service-worker/index.js`) intercepts navigations (`/todo/` etc.) and renders `page.mustache` itself via `populateTemplate(stateData)`, where `stateData` is app state with NO `aithne_origin`. So `<lucos-navbar aithne-origin="{{aithne_origin}}">` → `aithne-origin=""`. The correct server-side injection (`res.locals.aithne_origin`, ADR/#148 pattern) only reaches SERVER-rendered responses — a returning PWA user is answered by the SW, so it's bypassed. Server-rendered consumers (seinn) are immune: their navbar attribute is always populated. Fix = make the SW render path supply `aithne_origin` (persist in cached state / a cached config resource so it's available offline).

**Ruling out the JWKS serve-stale gap (#441-class):** if failures are plain token expiry (not JWKS), you'll see NO `JWT/JWKS infrastructure error` correlation and aithne `/_info` signing_key healthy (single key, no rotation thrash). Expiry-driven re-auth tracks the 15-min TTL + missing remint, not intermittent verification failures. Don't conflate the two.

**Env footgun to check:** `AITHNE_ORIGIN` empty-string ("") would ALSO render `aithne-origin=""` because `?? fallback` only catches null/undefined. (Wasn't the cause here — notes' env was correct — but check it before blaming the render path.)

Related: [[pattern_container_restart_log_buffer_artifact]], [[reference_aithne_agent_principal_model]].
