---
name: pattern-lucos-repos-deploy-triggers-sweep
description: lucos_repos container startup auto-triggers an audit sweep via Start() → TriggerSweep(); recovery cadence after a deploy is ~17min, not the 6h scheduled cadence
metadata:
  type: reference
---

# lucos_repos: deploy auto-triggers a fresh audit sweep

## Mechanism

`lucos_repos` container startup calls `AuditSweeper.Start()`, which in turn calls `TriggerSweep()` (see commit `18b4931` "Fix concurrency: Start() now calls TriggerSweep() not runSweep() directly"). So every deploy of `lucos_repos`:

1. Container restarts → 09:20:49 `Audit sweep starting`
2. Deploy event fires → 09:20:57 `deploySystem`
3. Sweep runs for ~17min → 09:38:45 `Audit sweep completed successfully`
4. App reports to schedule_tracker → monitoring's synthesised `audit` check refreshes
5. Recovery fires → 09:39:09 `monitoringRecovery`

End-to-end deploy → recovery is **~17–18 minutes**, not 6 hours. This is the time-to-clear an `audit` alert via a deploy, regardless of the next scheduled sweep slot (01:00, 07:00, 13:00, 19:00 UTC).

## Why I got this wrong on 2026-05-28

When triaging the audit failure at 07:30 UTC, I told team-lead "the next scheduled sweep at 13:00 UTC will recover the check" — implicit assumption: only the cron triggers sweeps. lucas42 expected faster recovery and asked why. The deploy-auto-trigger via Start() was already wired in (closed issue `lucos_repos#277` "Add HTTP endpoint to trigger a full audit sweep on demand" preceded it; commit `18b4931` consolidated startup and on-demand sweeps via the same TriggerSweep path).

Read the `Start()` flow before quoting recovery times next time.

## Manual trigger: POST /api/sweep

If a deploy *didn't* fire a sweep (e.g. you need to recheck after a non-deploy config change, or want to verify a fix without redeploying), you can hit `POST https://repos.l42.eu/api/sweep` directly:

- No auth (trusted-network operational endpoint)
- Returns `202 Accepted` immediately, sweep runs in background
- Returns `409 Conflict` if a sweep is already in progress
- Same code path as scheduled and startup sweeps — equivalent behaviour

**GOTCHA (cost me time 2026-06-15):** `/api/sweep` is the AUDIT sweep ONLY — it does NOT refresh the PR sweeper. To clear a `stale-dependabot-prs` alert after a Dependabot PR is merged/closed, you MUST hit the SEPARATE `POST /api/pr-sweep` (PR sweeper, own 6h ticker, reads `pulls?state=open`). I reflexively called `/api/sweep` for a stale-dependabot-prs alert, waited 20min, stayed red; `/api/pr-sweep` cleared it in ~30s. Don't conflate the two sweepers.

## Verification signals

- `seconds_since_last_sweep == -1` → sweep currently running, none completed since start
- `seconds_since_last_sweep > 0` → most-recent-completed-sweep timestamp (container's own view)
- Monitoring's `audit` check status follows schedule_tracker, which lags `/_info` by one polling cycle (~1–2 min after sweep completion)

## Related

- [[feedback_no_destructive_without_recovery_path]] — deploy-cycle as a recovery path is fine; the in-flight sweep IS the verification.
- [[feedback_no_transient_dismissals]] — give specific recovery times ("18 min after deploy") not vague "wait for it."
