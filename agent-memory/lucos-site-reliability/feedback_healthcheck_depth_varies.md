---
name: Healthcheck depth varies — don't conflate 'container Healthy' with 'service works end-to-end'
description: Always read the actual healthcheck definition before treating Docker Healthy as proof of recovery
type: feedback
---

When verifying recovery, never assume `docker compose up --wait` reporting `Healthy` means the service works end-to-end. Read the actual `healthcheck.test` in `docker-compose.yml` first. Common shallow healthchecks that I've been fooled by:

- `test -p /var/log/cron.log` — only proves crond initialised the named pipe; says nothing about whether scheduled jobs run successfully
- `nc -z 127.0.0.1 PORT` — only proves something is listening on the port; doesn't probe the application
- `wget -qO- /_info` — passes on HTTP 200, but `/_info` itself can return 200 with `ok: false` inside

**Why:** Bit me on 2026-05-09 in the lucos_creds CRLF/snapshot incident — `lucos_creds_configy_sync` came up `Healthy` in 2.0s during a failed redeploy and I read that as "configy_sync key works." Its healthcheck is `test -p /var/log/cron.log` — entirely uncorrelated with whether the SSH key the cron actually uses is valid.

**How to apply:** When you need positive evidence a service is genuinely working post-fix:
1. Open the healthcheck definition. If shallow, ignore the Healthy signal and find a deeper probe.
2. Prefer end-to-end signals: a successful scheduled-job heartbeat to schedule-tracker, a `metrics.X.value` on `/_info` that requires the failed component to work (e.g. `creds.l42.eu/_info metrics.systems.value` requires SSH to read 50 systems), or an explicit Loganne completion event.
3. If only schedule-tracker `ok=true` is available: check the threshold window (`techDetail` says "most recent within X seconds"). If X is wider than the time since the fix, an OLD success can sustain `ok=true` and you have no positive evidence of post-fix recovery.
