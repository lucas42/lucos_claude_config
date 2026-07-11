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

**audit-dry-run is NOT a required/blocking check** — on 2026-06-15 PR #432 auto-merged (15:41:29Z) with audit-dry-run still `failure`; the only required gate was `ci/circleci: lucos/build`. (lucos_repos/main required checks per branch protection, confirmed by team-lead 2026-06-15: `test`, `Analyze (go)`, `lucos/build` — audit-dry-run absent.) So a red audit-dry-run is advisory noise, doesn't block merge — don't scramble to re-run it to "unblock" a PR (and my App lacks Actions:write to re-run GHA anyway).

**NOT an incident** — production self-heals on next sweep. It's CI flakiness. Fix = honour `Retry-After` + bound fetch concurrency; the binary also swallows the 403 body so logs never say "rate limit" (observability gap). Tracked: **lucas42/lucos_repos#433** (filed 2026-06-15). Installation id at the time: 114293989. Related deploy mechanics: [[pattern_lucos_repos_deploy_triggers_sweep]].

## Two distinct flavours — secondary burst vs PRIMARY hourly-quota contention (2026-07-11, #462)

The above is the **secondary** rate-limit (abuse/burst, ~60s window, self-clears). A **primary** hourly-quota exhaustion looks different and needs a different call:
- **Fingerprint:** `x-ratelimit-remaining=0` + a reset **~20–25 min** away (not 60s). By 2026-07-11 a `RateLimitTransport` exists (`conventions/ratelimit_transport.go`, `rateLimitMaxWait=5m`) so logs now DO say `GitHub rate limit exceeded` (observability gap from #433 partly closed). It waits out secondary limits but a primary reset >5m → gives up → checks `Skipped` → `cmd_audit.go` `os.Exit(2)` (refuses to post an incomplete diff) → CI red.
- **One-off busy hour vs single-sweep structural — the discriminator:** pull the job log and count **how many repos processed cleanly BEFORE the wall**. On 2026-07-11 only the *tail 28* of ~63 were rate-limited (~35 clean first), and the wall hit only ~6.5 min into the sweep → the sweep contributed <~1k calls, i.e. the shared window was ~80% pre-drained by OTHER installation consumers (prod periodic sweep, deploy-triggered sweeps, `/api/rerun`, `/api/sweep`, PR dashboard, C4, every open PR's own dry-run). A lone dry-run is ~1–1.5k calls — does NOT approach 5000 alone. So: **contention on busy estate-rollout hours, not single-sweep overflow.**
- **Fix (proportionate):** longer dry-run max-wait, or auto-retry-after-reset. Do NOT build a cross-run ETag cache — impact is internal + self-heals in ≤1hr, doesn't justify the ephemeral-CI persistence tax. Tracked **lucas42/lucos_repos#462** (my read P3).
- **Re-run path:** `workflow_dispatch` on `audit-dry-run.yml` (present on main; input `pr_number`) needs **actions:write** — my App lacks it; route to **lucos-system-administrator**, don't empty-commit-thrash. Even though a red dry-run doesn't block *merge*, the estate-rollout workflow gates Step 2 on the **diff comment being posted**, so a missing diff genuinely stalls a rollout (process gate ≠ branch-protection gate).
