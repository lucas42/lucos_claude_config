# Ops Checks Tracking

Track when each periodic ops check was last run. Update this file after completing each check.

Format: `check_name: YYYY-MM-DD`

A check is due if there is no entry for it, or if elapsed time since last_run >= the check's frequency.

## Every-run checks

| Check | Last run |
|---|---|
| dependabot-alerts | 2026-08-19 |
| codeql-secret-scanning | 2026-08-19 |
<!-- last updated: 2026-08-19 — 0 dependabot alerts; same 3 codeql alerts, still tracked by open issues (contacts#771, googlesync_import#218, media_metadata_api#325), 0 secret-scanning -->

## Monthly checks

| Check | Last run |
|---|---|
| codeql-coverage | 2026-08-06 |
| github-actions-audit | 2026-08-06 |
