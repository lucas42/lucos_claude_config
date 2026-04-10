# lucos_repos API Endpoints

`lucos_repos` exposes two endpoints for triggering checks outside the regular schedule. No auth required.

## Full Audit Sweep

Triggers a complete audit sweep across all repos — equivalent to the scheduled sweep. Use this to clear monitoring alerts on `repos.l42.eu` and `schedule-tracker.l42.eu` after transient failures (e.g. rate limit errors).

```
POST https://repos.l42.eu/api/sweep
```

- No query parameters. Returns 202 Accepted; sweep runs in the background.
- Returns 409 if a sweep is already in progress.
- The sweep waits for the GitHub rate limit to reset (up to 5 minutes) rather than aborting, so it can take several minutes to complete.
- Only triggers the audit convention sweep, **not** the PR sweeper (`stale-dependabot-prs` runs on its own schedule).

## Ad-Hoc Convention Rerun

After making changes during estate rollouts or verifying audit-finding fixes, you can trigger an immediate convention re-check for specific repos/conventions:

```
POST https://repos.l42.eu/api/rerun?repo=lucas42/lucos_contacts
POST https://repos.l42.eu/api/rerun?convention=auto-merge-secrets
POST https://repos.l42.eu/api/rerun?repo=lucas42/lucos_contacts&convention=auto-merge-secrets
```

At least one of `?repo` or `?convention` is required. Results are updated in the database and reflected on the dashboard immediately.

**Important distinction:** `/api/rerun` updates convention results in the database but does **not** satisfy the `last-audit-completed` monitoring check — only a full sweep (`/api/sweep`) does that. If monitoring is alerting on a failed sweep, use `/api/sweep`, not `/api/rerun`.
