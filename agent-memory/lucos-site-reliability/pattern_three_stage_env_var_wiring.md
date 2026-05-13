---
name: pattern-three-stage-env-var-wiring
description: Adding a new env var in lucos requires three coordinated edits (code read, compose passthrough, lucos_creds value); missing any one produces a silent runtime failure
metadata:
  type: feedback
---

Adding a new env var in any lucos service requires three coordinated edits — missing any one produces a silent broken deploy:

1. **Application code reads it.** `os:getenv("X", default)` / `os.environ["X"]` / `process.env.X` etc.
2. **`docker-compose.yml`'s `environment:` block forwards it from the host into the container.** Compose only forwards listed variables; an entry that exists in the host env (or `.env`) but is not in this block is *invisible* to the running container.
3. **lucos_creds holds the value** for each environment (`{repo}/development/.env`, `{repo}/production/.env`). Agents are read-only on lucos_creds; lucas42 is the only writer.

**Why:** When step 2 (or step 3) is missing, the read in step 1 returns the empty string. If the code then concatenates the empty string with a path (e.g. `"" ++ "/jobs"` → `"/jobs"`), `httpc:request` or equivalent returns `{error, no_scheme}` once per poll cycle — a quiet recurring warning rather than a startup crash. The service appears to be running fine; monitoring stays green; the broken behaviour is only visible if someone looks at the actual downstream consequences.

**How to apply:** Whenever code touches `os:getenv` (or any language equivalent) for a *new* variable, all three stages must be verified before treating the deploy as functional. CI today doesn't enforce this — proposal filed as [`lucas42/lucos_repos#387`](https://github.com/lucas42/lucos_repos/issues/387) for a build-time convention check.

**Related convention**: see [reference-endpoint-vs-origin-convention](reference_endpoint_vs_origin_convention.md) — when naming the variable, `*_ENDPOINT` means full URL with path; `*_ORIGIN` means origin only.

**Detection signature for SRE diagnosis**: a service's container logs show recurring warnings like `transport error … {no_scheme}` or `connection refused` at 1/min cadence, with no startup-time error in the deploy log. First diagnostic step: `docker exec <container> printenv VAR_NAME`. If empty, the wiring is broken at step 2 or step 3.

Grounding: 2026-05-13 scheduled-jobs monitoring blackout — see `lucos/docs/incidents/2026-05-13-scheduled-jobs-monitoring-blackout.md`. ~7h 20m of monitoring blind spot before lucas42 visually noticed.
