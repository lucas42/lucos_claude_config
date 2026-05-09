---
name: wget -qO- /_info healthchecks pass HTTP 200 even when /_info body reports ok=false
description: Common lucos healthcheck convention is shallower than it looks — Docker Healthy doesn't imply /_info checks all ok
type: reference
---

Many lucos services use a Docker healthcheck of the shape `wget -qO- http://127.0.0.1:${PORT}/_info`. The `wget` command exits `0` on any HTTP 2xx response regardless of body contents — and `/_info` endpoints typically return HTTP 200 with structured JSON inside, even when one or more of their internal checks have `"ok": false`. So a container whose `/_info` reports a *failing* check will still be marked Docker `Healthy` until the endpoint itself stops responding.

**Where this bites:**

- Recovery verification after fix shipping — Docker `Healthy` is a poor proxy for "service works end-to-end." Always read the actual `/_info` JSON, not just `docker compose ps`.
- Bit me on the 2026-05-09 lucos_creds CRLF/snapshot incident: pipeline 680's deploy log showed `lucos_creds_ui` going `Healthy` would have been a false-positive even if the deploy hadn't timed out — the `/_info` body reported `ssh-server: ok=false` while the wrapper status was 200. (In the actual sequence, the healthcheck did fail because `/_info` itself was hanging on the failed SSH probe — but in milder failure modes the wrapper would have passed.)
- lucos-architect flagged on 2026-05-09 as "a recurring gotcha and worth a separate convention-check at some point if it bites you again."

**The right shape for an `/_info`-based healthcheck:**

Healthcheck should exit non-zero when *any* check inside `/_info` reports `ok: false`. Concretely:

```bash
wget -qO- http://127.0.0.1:${PORT}/_info | \
  python3 -c "import json, sys; d=json.load(sys.stdin); sys.exit(0 if all(c.get('ok') for c in d.get('checks', {}).values()) else 1)"
```

Or, simpler, an explicit grep pattern: `wget -qO- ... | grep -v '"ok":false'`. Either approach surfaces internal-check failures up to Docker so health-aware orchestration (compose `--wait`, `lucos_docker_health_*` cron checks) can act on them.

**Not pursuing now.** Architect's framing — "worth a separate convention-check at some point if it bites you again" — is the right call given the cost of touching every service that uses the shallow pattern. Holding for the next time the false-positive bites visibly. If/when it does, the right escalation is a convention-check via `lucos_repos`, not a scattergun PR — and worth consulting architect first to scope the convention text.

**Also worth flagging:** when fixing a service's healthcheck, also re-read the `start_period` / `interval` / `retries` to make sure the deeper check doesn't blow the timeout budget. A check that runs an SSH probe (e.g. lucos_creds's `ssh-server` check) is typically much slower than a no-op endpoint, so an `interval: 10s, timeout: 5s, retries: 3` window may need widening.
