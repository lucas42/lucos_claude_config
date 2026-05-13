---
name: review-envvar-wiring
description: Three-stage env-var wiring check — flag any new os:getenv/os.environ/process.env read that lacks a matching compose environment: entry or lucos_creds value
metadata:
  type: feedback
---

Any PR that introduces a new environment-variable read in application code must wire it at all three levels:

1. **Code** — reads the var (`os:getenv`, `os.environ.get`, `process.env.X`, etc.)
2. **`docker-compose.yml` `environment:` block** — forwards the var from the host into the container (passthrough format, no `=`)
3. **lucos_creds** — holds the actual value for each environment

Missing step 2 means the container never sees the var, even if the host has it. Missing step 3 means the host has nothing to forward. Both produce silent failures (empty string default rather than a startup crash).

**Why:** The 2026-05-13 scheduled-jobs monitoring blackout was caused exactly by this: `fetcher_scheduled_jobs.erl` added `os:getenv("SCHEDULE_TRACKER_ENDPOINT", "")` (step 1) but the compose `environment:` entry (step 2) and lucos_creds value (step 3) were never added. The container got an empty string, logged `{no_scheme}` warnings once per minute, and cast zero monitoring updates for ~7h 20m. Source: `docs/incidents/2026-05-13-scheduled-jobs-monitoring-blackout.md`.

**How to apply:** When reviewing any PR that adds a new env-var read:
- Check `docker-compose.yml` for a matching `environment:` entry (no `=`, just the var name).
- If missing, flag as REQUEST_CHANGES — this is a deployment correctness issue, not a style nit.
- Note that agents cannot write to lucos_creds production (only lucas42 can); mention in review that a matching cred write is required alongside the code change.
- Until `lucas42/lucos_repos#387` lands as an automated convention check, this is a manual review responsibility.

**`_ENDPOINT` / path-append code smell:** If a var is named `*_ENDPOINT` but the code does string concatenation on it before use (e.g. `Endpoint ++ "/jobs"`, `f"{URL}/path"`), that is a convention violation. `_ENDPOINT` vars must hold the full URL including path and be used verbatim. `_ORIGIN` vars hold just the origin and may have paths appended. Flag the mismatch and ask the author to either rename the var or move the path into the env-var value.

**Related:** [[docker-conventions]]
