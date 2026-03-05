# Ops Checks Tracking

Tracks when each ops check was last run, and per-container log review history.

## Periodic Checks

| Check | Last Run | Notes |
|---|---|---|
| CI status (monthly) | never | |
| `/_info` quality (monthly) | never | |

## Container Log Review

Tracks the last-reviewed timestamp for each container. Use `--since <timestamp>` when SSHing to review logs.

Timestamps are ISO 8601 / RFC 3339 format (e.g. `2026-03-05T12:00:00Z`).

| Container | Last Reviewed | Notes |
|---|---|---|
| (none yet) | | |
