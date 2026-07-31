---
name: recurring-docker-healthy-not-reachability
description: Recurring estate-wide pattern — Docker Healthy status and a green /_info don't imply a working service; checks that don't traverse the failure plane (or that only probe dependencies) can't detect failures on it
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

- **2026-07-31 — lucos_media_metadata_manager php alpha.** A base-image bump dropped `mbstring`; every field-rendering page 500'd for 6h29m. Container healthy and monitoring 55/55 green throughout. See `lucos/docs/incidents/2026-07-31-media-metadata-manager-php-alpha-mbstring.md`.

**The `/_info` variant — checks that describe dependencies, not self:**

The 2026-07-31 case adds a dimension beyond loopback-vs-failure-plane. `lucos_media_metadata_manager`'s `/_info` declares exactly **one** check, and it probes a *downstream API*. `src/html/_info.php` requires `api.php` and never touches `views/field.php`. So during a total outage of every page on the site, `/_info` correctly returned 200 with `ok: true` — it was reporting on someone else's health.

> A service whose `/_info` checks only describe its dependencies cannot report its own failure.

**Verified trap (2026-07-31):** the intuitive remedy — "CI boots the shipped image and asserts `/_info` is healthy" — would have gone **green** through this outage for exactly the same reason. Check *coverage* is the load-bearing fix; a CI job asserting a dependency-only `/_info` asserts nothing. Sequence the spec change first, the CI rollout second. I nearly recommended the CI job alone; reading `_info.php` at source is what caught it.

Proposed spec direction (my position on lucas42/lucos#273): `/_info` `checks` must include ≥1 check of the service's **own primary function**, cheap and side-effect-free (monitoring's 1s timeout ⇒ stay well under 0.5s). Prefer a check that *exercises the primary path* (e.g. render a view with fixed input, assert markup) over an enumeration of ingredients (e.g. "assert these extensions are loaded") — allowlists rot and only catch the failure you've already had.

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
