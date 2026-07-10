---
name: aithne-integration-patterns
description: Three legitimate ways a system sits behind aithne auth, selection rule, and the sidecar /_info blind-spot
metadata:
  type: reference
---

Three legitimate aithne auth-integration patterns exist across the estate (verified by code sweep 2026-07-10, not memory):

1. **In-app verification** — app verifies the aithne JWT itself via shared lib: `lucosauth` (Django: lucos_contacts, lucos_eolas) or `lucos_aithne_jsclient` (Node, rollout in progress, lucos#264). Fit: lucos-authored services we control.
2. **Sidecar proxy** — oauth2-proxy container + nginx `auth_request` in front. Currently **only** lucos_locations, fronting `owntracks/recorder` (a third-party binary → sidecar was the correct, forced choice). Fit: adopted apps with no usable native OIDC.
3. **Native-OIDC patch** — patch/configure the adopted app's own OIDC client to talk to aithne. lucos_worlds (BookStack, patched for ES256, lucos_worlds ADR-0002). Fit: adopted apps that ship OIDC — cheaper than a sidecar.

Selection rule: lucos-authored → in-app; adopted-with-native-OIDC → configure its native OIDC; adopted-without-OIDC → sidecar. (Patching a third-party app's *auth logic*, e.g. BookStack for ES256, is a last-resort hack, NOT a recommended pattern — lucas42 wanted it kept out of the selection docs entirely, documented only in lucos_worlds decision records.)

**Two per-pattern constraints (both verified against source 2026-07-10):**
- **Pattern 1 (in-app) requires a `*.l42.eu` domain.** It reads the shared `aithne_session` cookie, which aithne sets in prod with `Domain=l42.eu` (`token/token.go` `cookieDomain`) — browser only sends it to `l42.eu` + subdomains; canonical consumer arachne `explore/src/server/auth.js` reads it off the request. Patterns 2 & 3 are NOT domain-bound: they run a standard OAuth2/OIDC redirect and set their OWN session cookie (pattern 3 via `OAUTH2_PROXY_COOKIE_SECRET`).
- **Pattern 2 requires ES256 support.** aithne signs ID tokens ES256-only; an adopted app whose OIDC only does RS256/HS256 can't validate them → use the sidecar (oauth2-proxy sets `OAUTH2_PROXY_OIDC_ENABLED_SIGNING_ALGS=ES256`).

**Key architectural trade-off:** a sidecar/proxy in the request path is **invisible to the app's own `/_info`** — an app health endpoint can't see a layer in front of it. This made the 2026-07-09 locations outage silent behind a green monitor (oauth2-proxy crash-loop, app healthy). Patterns 1 and 2 don't carry this blind spot.

**SHIPPED**: guidance now in aithne `consumer-migration-guide.md` "Choosing an integration pattern" section (lucas42/lucos_aithne#310, PR #312 merged 2026-07-10). Deploy-side detection backstop for the blind-spot class tracked separately on lucas42/lucos#266 (my rec: adopt A sequencing + build B crash-loop detection keyed on container run-state, lean against C). Surfaced by incident lucas42/lucos#265.

Related: [[project_aithne_migration_guide]], [[reference_docker_healthy_not_reachability]]
