---
name: pattern-deploy-window-boundary-crossprobe-flap
description: Media cross-probe flaps during a coordinated media rollout are usually LEGITIMATE 401 auth-failures during creds key-rotation convergence — NOT spurious deploy-window noise. Check before suppressing.
metadata:
  type: project
---

When ops-check Check 2 surfaces brief media cross-probe flaps (weightings `media-api-reachable`, metadata-manager `metadata-api`) clustered around a burst of media-stack deploys, **do NOT assume they're spurious deploy-window noise.** They are usually a GENUINE cross-system auth-failure window and the alerts are CORRECT.

**Confirmed root cause (2026-06-14 cluster, evidence-based):** a lucos_creds **scope/key rotation** of `KEY_LUCOS_MEDIA_METADATA_API` preceded the deploys. During convergence the CLIENTS redeploy with the new key BEFORE the SERVER redeploys to accept it (updated `CLIENT_KEYS`), so for ~2 min the server returns **401 Unauthorized** to the clients. Real inter-service calls fail too, not just the monitoring probe.

**How to tell (the diagnostic order):**
1. Loganne `credentialUpdated` events (source `lucos_creds`) for the API key around the deploy time → confirms a rotation.
2. The `monitoringAlert` `failingChecks[].debug` — `HTTPError: 401 ... Unauthorized` = auth rejection from a LIVE server (legit). A connection-refused/timeout would instead suggest unreachability.
3. Router access log (`media-api.l42.eu ... 401`) during the window, with `/_info` still 200 → server up, actively rejecting the rotated key.

**Disposition:** do NOT suppress via `failThreshold`/`dependsOn` — that masks real auth outages on every future rotation. The fix belongs in the **key-rotation convergence sequence** (server accepts old+new key during a grace window, OR order the server's CLIENT_KEYS redeploy before clients). 

**HISTORY — my refuted first guess:** on 2026-06-15 I initially filed lucos_monitoring#286 claiming this was a "deploy-window boundary gap" (media-api briefly unreachable before its deploy window) and proposed monitoring suppression. lucas42 challenged it; the evidence (401s + the rotation events) **refuted my hypothesis** — I'd reverse-engineered it from alert/deploy timing rather than checking what the probe actually saw. #286 to be closed as misdiagnosed. Lesson: for any flap, read the alert `debug`/failure-mode BEFORE theorising a cause. Related: [[reference_lucos_creds_key_rotation]], [[pattern_scope_cutover_convergence_and_enumeration_gap]], [[pattern_dependson_deploy_window_only]].
