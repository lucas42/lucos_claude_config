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

**Same ~75s mirror event hit lucos_contacts build 4684 (pipeline 1608) too** — first attempt got `502 Bad Gateway`, then timeouts. One mirror degradation, multiple concurrent builds failed. lucos_contacts case: failed pipeline 1608 was a DELAYED/out-of-order trigger for an OLDER commit (4 commits behind main HEAD) — its build failing left the monitoring `circleci` check red even though main HEAD had already deployed green via a separate pipeline (1607). **Clearing that red: do NOT re-run the failed pipeline (it'd redeploy the stale ancestor → rollback); instead trigger a FRESH pipeline on main HEAD** (`POST /api/v2/project/gh/lucas42/<repo>/pipeline {"branch":"main"}`) — idempotent re-deploy of running code, becomes latest green workflow, monitoring clears. Monitoring tracks the most-recently-CREATED workflow, not the HEAD commit's — so an out-of-order stale-commit failure can red a system whose HEAD is fine.

**Root-cause nuance (important):** the orb's `Docker Login (mirror)` step ALREADY retries (`max_auto_reruns: 2` / `auto_rerun_delay: 5s` = 3 attempts ~15s) — too short to outlast a ~75s degradation. And it's **fail-CLOSED**: the probe path falls back to direct Hub when the mirror's unreachable, but the login path fails the whole build. **Fix = make mirror-login fail-OPEN like the probe path** (mirror is a pull-through CACHE, must never sink a build). Filed lucas42/lucos_deploy_orb#188. Also: probe treats any non-`000` (incl. 502) as "available".

**Disposition:** one mirror event, two repos' builds failed, both recovered; production never down. Filed the orb fail-open fix (#188) — the cheap high-leverage prevention. Deeper "why does the mirror 502 under estate-rollout load" = mirror-capacity question for the mirror owner if it recurs. Distinct from the benign [[pattern_docker_mirror_registry_onexpire_benign]] OnExpire noise.
