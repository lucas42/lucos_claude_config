---
name: recurring-docker-healthy-not-reachability
description: Recurring estate-wide pattern — Docker container Healthy status doesn't imply end-to-end reachability; healthchecks that don't traverse the failure plane don't detect failures on it
metadata:
  type: reference
---

Docker `(healthy)` status is **not** proof of end-to-end working. It is only proof that the specific bytes the healthcheck command tests are as expected. If the healthcheck command does not traverse the failure plane that is currently broken, the container will report `Healthy` while users see total failure.

**Recurring failure shape:**

- Healthcheck is loopback-internal (e.g. `wget http://localhost:8080/health`, `test -p /var/log/cron.log`).
- The actual failure is on a plane *outside* the loopback — DNS resolution, outbound network, secret read, mounted volume access, downstream service.
- `docker ps` shows `(healthy)` indefinitely while production is broken. Detection comes from a human noticing the contradiction, not from monitoring.

**Confirmed occurrences (2 of last 3 incidents at time of writing, 2026-05-28):**

- **2026-05-09 — lucos_creds CRLF.** `lucos_creds_configy_sync`'s container healthcheck was `test -p /var/log/cron.log`. Reported `Healthy` for hours while the SSH key it depended on was being rejected outright by `libcrypto`. See `docs/incidents/2026-05-09-creds-ssh-key-crlf.md`.
- **2026-05-28 — xwing network flush.** Five of six xwing containers reported `Up X days (healthy)` throughout an outage where every container was orphaned from its Docker network and externally unreachable. The healthchecks were container-internal `wget http://localhost:…` and didn't traverse the broken network plane. See `docs/incidents/2026-05-28-xwing-network-flush-orphaned-containers.md`.

**Architectural significance:**

This is a **systemic** problem with healthcheck-design convention across the estate, not just a runbook gap. The structural failure mode is uniform: healthcheck commands that don't exercise the dependency most likely to fail invisibly. A first-class fix would be an estate-wide convention for healthcheck authors, ideally as a `lucos_repos` convention check alongside the `/_info` spec:

- Does the check exercise the dependency that's most likely to fail invisibly? (DNS / outbound network / secret read / mounted volume access)
- If not, is that dependency exercised somewhere else in a monitored path (e.g. an external monitoring system)?

The SRE follow-up #4 from the xwing incident is targeting this at the SRE-reference level — if it expands into a convention-style rule, that's the architecturally cleaner home for it.

**When this is load-bearing:**

- Reviewing healthcheck designs in `docker-compose.yml` changes.
- Architectural review of monitoring strategies — confirming there's an end-to-end probe somewhere that the in-container healthcheck doesn't substitute for.
- Reviewing incident reports that involve `(healthy)` containers in a broken state — confirm the pattern is reported correctly.

See: [[no-onhost-source-of-truth]] (other systemic observation from the 2026-05-28 incident).
