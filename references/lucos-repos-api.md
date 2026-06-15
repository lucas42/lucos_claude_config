# lucos_repos API Endpoints

`lucos_repos` exposes endpoints for triggering checks outside the regular schedule. No auth required.

## Full Audit Sweep

Triggers a complete audit sweep across all repos — equivalent to the scheduled sweep. Use this to clear monitoring alerts on `repos.l42.eu` and `schedule-tracker.l42.eu` after transient failures (e.g. rate limit errors).

```
POST https://repos.l42.eu/api/sweep
```

- No query parameters. Returns 202 Accepted; sweep runs in the background.
- Returns 409 if a sweep is already in progress.
- The sweep waits for the GitHub rate limit to reset (up to 5 minutes) rather than aborting, so it can take several minutes to complete.
- Only triggers the audit convention sweep, **not** the PR sweeper. To refresh `stale-dependabot-prs` use `/api/pr-sweep` (below), not this endpoint.

## PR Sweep (Dependabot dashboard)

Triggers the **PR sweeper**, which fetches each repo's open PRs (`GET /repos/{repo}/pulls?state=open`) and recomputes the `stale-dependabot-prs` monitoring check (Dependabot PRs open >48h). This is a **separate** sweeper from the audit sweep, on its own 6-hour ticker.

```
POST https://repos.l42.eu/api/pr-sweep
```

- No auth, no params. Returns 202 Accepted; 409 if a PR sweep is already in progress.
- **Use this — not `/api/sweep` — to clear a `stale-dependabot-prs` alert after the offending PR is merged or closed.** `/api/sweep` (audit) does NOT refresh PR data; the check otherwise lags up to 6h until the next PR-sweeper tick. Cleared in ~30s when tested 2026-06-15 (after PR lucos_contacts_googlesync_import#201 was closed).

## Ad-Hoc Convention Rerun

After making changes during estate rollouts or verifying audit-finding fixes, you can trigger an immediate convention re-check for specific repos/conventions:

```
POST https://repos.l42.eu/api/rerun?repo=lucas42/lucos_contacts
POST https://repos.l42.eu/api/rerun?convention=auto-merge-secrets
POST https://repos.l42.eu/api/rerun?repo=lucas42/lucos_contacts&convention=auto-merge-secrets
```

At least one of `?repo` or `?convention` is required. Results are updated in the database and reflected on the dashboard immediately.

**Important distinction:** `/api/rerun` updates convention results in the database but does **not** satisfy the `last-audit-completed` monitoring check — only a full sweep (`/api/sweep`) does that. If monitoring is alerting on a failed sweep, use `/api/sweep`, not `/api/rerun`.
