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

Selection rule: lucos-authored → in-app; adopted-with-OIDC → native-patch; adopted-without-OIDC → sidecar.

**Key architectural trade-off:** a sidecar/proxy in the request path is **invisible to the app's own `/_info`** — an app health endpoint can't see a layer in front of it. This made the 2026-07-09 locations outage silent behind a green monitor (oauth2-proxy crash-loop, app healthy). Native-patch and in-app patterns don't carry this blind spot.

Guidance to be documented in aithne `consumer-migration-guide.md` — tracked by lucas42/lucos_aithne#310 (owner: me). Deploy-side detection backstop for the blind-spot class tracked separately on lucas42/lucos#266 (my rec there: adopt A sequencing + build B crash-loop detection keyed on container run-state, lean against C). Surfaced by incident lucas42/lucos#265.

Related: [[project_aithne_migration_guide]], [[reference_docker_healthy_not_reachability]]
