---
name: pattern-locations-oauth2proxy-sidecar-crashloop
description: locations /map 500 while /_info green = oauth2_proxy sidecar crash-looping on missing creds; app is fine, auth sidecar isn't
metadata:
  type: project
---

lucos_locations human map-UI paths (/map, /owntracks/api|ws|view|static|utils) are fronted by an `lucos_locations_oauth2_proxy` sidecar via nginx (`lucos_locations_otfrontend`) `auth_request`, gated on aithne `locations:read` (PR #97, closed/merged 2026-07-09).

**Failure mode (2026-07-10 incident):** oauth2_proxy crash-loops (`Restarting`, exit=1, rising RestartCount) with `main.go:67 invalid configuration: missing setting: cookie-secret / client-secret`. nginx dutifully auth_requests a dead sidecar → **500 on /map/**. Cause: lucas42-only prod creds never set before #97 auto-deployed — `OAUTH2_PROXY_COOKIE_SECRET` + `KEY_LUCOS_AITHNE` (OIDC client secret via prod linked cred lucos_locations/production ⇒ lucos_aithne/production, tracked lucas42/lucos_locations#96).

**Why /_info stays GREEN through it:** /_info is served by the Go app (otrecorder), which is healthy. The sidecar is a separate container. So this is a live case of [[feedback_healthcheck_depth_varies]] / [[pattern_info_endpoint_boundary]] — verify the SIDECAR container state and probe the human path end-to-end; never trust /_info to catch an auth-layer outage.

**Human/device split tell:** device publish `/owntracks/pub` → **401** (separate basic-auth, healthy) and MQTT `:8883` OPEN, while human `/map/` → 500. A 401 on the device path (not 500) confirms only the human auth layer is down and ingestion/data are intact.

**Fix is lucas42-only** (prod creds): set the two creds + redeploy, or fallback-revert #97. SRE can't restore — restarting the proxy is futile without creds.

**Resolution (2026-07-10, ~51min outage):** coordinated CI redeploy, NOT host restarts — a bare `docker restart` reuses the container's old env and won't inject new lucos_creds values; only a fresh deploy re-fetches creds. Order: (1) **aithne** first — its `oidc_clients` reconcile from `CLIENT_KEYS` is **startup-only** (ADR-0004, `reconcileOIDCClients` called once from `main()`), so it must restart to register the new client; confirm via log `oidc client reconcile: upserted client "lucos_locations"`. Redeploying the estate auth SPOF for a linked-cred change is expected/normal (clean convergence). (2) **lucos_locations** — inject the sidecar creds. Both via `POST /api/v2/project/gh/lucas42/<repo>/pipeline {"branch":"main"}`.

**`/map/` unauth returns 403 (a sign-in PAGE), not a 302 — BY DESIGN.** #97's otfrontend nginx uses `error_page 401 =403 /oauth2/sign_in` on gated locations: the auth_request 401 is rewritten to 403 and served the oauth2-proxy sign-in-button page (button → /oauth2/start → 302 → aithne). So a headless `/map/` probe returning 403-with-sign-in-HTML is HEALTHY, not broken. Verify OIDC wiring via `/oauth2/start` → 302 (correct client_id/scope/redirect_uri), not via `/map/` status code.
