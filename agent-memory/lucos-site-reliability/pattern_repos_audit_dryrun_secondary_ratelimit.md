---
name: pattern-repos-audit-dryrun-secondary-ratelimit
description: lucos_repos audit-dry-run mass 403s = GitHub secondary rate-limit (burst content fetches), NOT lost App access — proof recipe
metadata:
  type: project
---

# lucos_repos `audit-dry-run` mass 403s = secondary rate-limit, not lost access

**Symptom:** `audit-dry-run` GitHub Actions check on a lucos_repos PR fails with many `unexpected GitHub API status 403 for <file> in lucas42/<repo>`. Tempting (wrong) read: "App installation lost access / token rotated."

**Why:** the audit binary fans out ~2,760 content fetches (92 repos × ~30 conventions) in a burst with no throttling → periodically trips GitHub's **secondary rate-limit** (403, not 429). Non-deterministic: consecutive PR dry-runs can pass then fail with identical code.

**How to apply — proof recipe (took 20 min on 2026-06-15, #432):**
1. **Live production sweep reads the repos fine?** `curl https://repos.l42.eu/api/status` → if the "affected" repos show all-pass right now, access is intact (same App). Decisive.
2. **Did the run succeed before failing?** Job log: look for `INFO ... installation token refreshed` + a run of determinate/passed results *before* the first 403. 753 passes-then-403 ⇒ not auth (and expiry would be 401).
3. **Blast radius + window:** `grep "status 403"` the job log (`gh-as-agent ... actions/jobs/<id>/logs`). Abrupt onset, everything-after fails, ~60s window = rate-limit fingerprint. The repos a reviewer names are usually just the *tail* (sort late, caught in the window) — not the whole set.

**audit-dry-run is NOT a required/blocking check** — on 2026-06-15 PR #432 auto-merged (15:41:29Z) with audit-dry-run still `failure`; the only required gate was `ci/circleci: lucos/build`. So a red audit-dry-run is advisory noise, doesn't block merge — don't scramble to re-run it to "unblock" a PR (and my App lacks Actions:write to re-run GHA anyway).

**NOT an incident** — production self-heals on next sweep. It's CI flakiness. Fix = honour `Retry-After` + bound fetch concurrency; the binary also swallows the 403 body so logs never say "rate limit" (observability gap). Tracked: **lucas42/lucos_repos#433** (filed 2026-06-15). Installation id at the time: 114293989. Related deploy mechanics: [[pattern_lucos_repos_deploy_triggers_sweep]].
