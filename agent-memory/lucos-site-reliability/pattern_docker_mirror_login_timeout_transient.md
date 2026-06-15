---
name: pattern-docker-mirror-login-timeout-transient
description: CircleCI "Docker Login (mirror)" exit 1 = TIMEOUT reaching docker.l42.eu, not a credential failure; transient, re-run after confirming mirror healthy
metadata:
  type: project
---

# CircleCI "Docker Login (mirror)" exit 1 = mirror reachability timeout, NOT bad creds

**Symptom:** CircleCI build step **Docker Login (mirror)** fails exit 1, all retries. Tempting (wrong) read: "Docker registry credential failure."

**Actual log:** `Error response from daemon: Get "https://docker.l42.eu/v2/": context deadline exceeded (Client.Timeout exceeded while awaiting headers)`. The login never got a response from the self-hosted mirror (`lucos_docker_mirror`) — it's a **reachability/latency timeout**, not auth (auth reject would be 401-style, not a client timeout).

**How to triage (CircleCI re-runs are in my domain — user PAT):**
1. Read the failed step log (v1.1 build detail `output_url`) — confirm `context deadline exceeded` reaching docker.l42.eu, not an auth error.
2. **Confirm mirror healthy NOW before re-running** (else re-run just times out again): `curl -o /dev/null -w '%{http_code} %{time_total}' https://docker.l42.eu/v2/` should be **401 in <0.5s** (up, auth-required); `https://docker.l42.eu/_info` registry+upstream `ok:true`.
3. Re-run: `POST /api/v2/workflow/{id}/rerun {"from_failed": true}`, poll `/workflow/{id}` to success.

**2026-06-15 (lucos_repos build 2270, c4-producer-edges, PR #432):** login timed out 15:31:37–15:32:38Z; builds 2266/2268 (same SHA, 26s earlier) passed; mirror responded 401 in 0.08s right after. Coincided with heavy estate activity (#421 9-repo rollout + audit sweeps) — **plausibly mirror saturation under load, unproven**. Re-ran from failed → green, cleared `ci/circleci: lucos/build`.

**Disposition:** single self-recovered transient → did NOT file an issue (cheap recovery = one re-run; no current unhealth). **WATCH:** if mirror-login timeouts recur — especially clustered with high estate load — that's a mirror/router capacity signal worth a real issue. Distinct from the benign [[pattern_docker_mirror_registry_onexpire_benign]] OnExpire noise.
