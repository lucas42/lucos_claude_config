---
name: lucos-creds
description: Structure, SSH command syntax, and deploy-snapshot gotcha for lucos_creds implementation work
metadata:
  type: project
---

- **Server**: Go SSH/SFTP server in `server/src/`. Tests run with `/usr/local/go/bin/go test ./src`.
- **UI**: Node/Express in `ui/src/index.js`, EJS views in `ui/src/views/`. No UI tests.
- **SSH command syntax**: `system/environment/KEY=value` (set), `system/environment/KEY=` (delete simple), `client/environment => server/environment` (create linked), `rm client/environment => server/environment` (delete linked), `ls system/environment` / `ls system/environment/KEY` (read). Values may contain slashes — the server splits on `=` first (max 2 parts), so URL values like `http://...` work fine. The key path must have exactly 3 slash-delimited segments: `system/environment/KEY`.
- **CI**: CircleCI runs Go tests in parallel with Docker build. Config in `.circleci/config.yml`.
- **`/usr/local/go/bin/go`** is the Go binary path (not on PATH in bash tool sessions).
- Linked credential DB schema: UNIQUE on (clientsystem, clientenvironment, serversystem) — serverenvironment not part of the unique key.
- **CRITICAL — deploy reads a snapshot, not live store**: `LUCOS_DEPLOY_ENV_BASE64` in CircleCI is a base64-encoded `.env` snapshot used to break the circular self-deploy dependency (tracked in lucos_creds#152). It is manually maintained and **silently overwrites the live store on every redeploy**. If you update credentials in the live store but a redeploy happens, the old values come back. When a live-store fix "doesn't take" after a redeploy, check for `*_DEPLOY_*` / `*_ENV_BASE64` env vars in CircleCI — that's the snapshot path. Both the live store AND the CircleCI env var must be updated. (Incident: 2026-05-09-creds-ssh-key-crlf)
- **SSH key corruption: `Load key … error in libcrypto`** surfaces for any non-base64-alphabet byte in the PEM body — CRLF (`\r\n`), `~` (old substitution encoding), literal `\n`, BOM, extra whitespace. Don't narrow to one corruption mode early when diagnosing.
