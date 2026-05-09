---
name: SSH key handling and deploy snapshot review heuristics
description: Patterns to check when reviewing SSH key code or credential deploy paths — from lucos_creds 2026-05-09 incident
type: feedback
---

## `Load key … error in libcrypto` = corruption class, not a single bug

When reviewing SSH key handling code, ensure fixes reject **all** non-base64-alphabet characters in the PEM body, not just the one that surfaced in a specific incident. Characters that trigger this OpenSSH error include:
- `\r` (CRLF line endings)
- `~` (old lucos_creds substitution-era encoding)
- Literal `\n` (backslash-n, not actual newline)
- BOM (byte-order mark)
- Leading/trailing whitespace

The error message gives no hint which character is the culprit. Startup validation (#306 pattern) should enumerate and reject all of these.

**Why:** The lucos_creds 2026-05-09 incident — CRLF in stored keys caused libcrypto decode failure after PR #303 removed the substitution workaround that had been masking them.

**How to apply:** When reviewing SSH key validation code, check it rejects the full class of corruption, not just the one mode mentioned in the issue.

---

## Deploy path vs live state — check for snapshot indirection

When reviewing PRs that change how credentials are loaded at startup, check whether the **deploy path** reads from the same store as the **runtime path**. Services with circular deploy dependencies (A deploys by reading its own credentials from itself) often have a snapshot bypass:

- Look for env vars named `*_DEPLOY_*`, `*_ENV_BASE64`, or similar
- If a snapshot exists, check whether credential updates propagate to it automatically or require a manual step
- If manual, the PR should either document this or add automation

A one-line `grep` for these patterns in `.circleci/config.yml` or the deploy orb quickly rules out snapshot indirection.

**Why:** lucos_creds 2026-05-09 incident — `LUCOS_DEPLOY_ENV_BASE64` (a CircleCI snapshot set 2026-04-10) silently overwrote corrected keys on every redeploy until the snapshot itself was updated.

**How to apply:** On any PR that touches credential loading or startup, grep the deploy config for snapshot-style variables.

---

## Docker healthcheck depth — `Healthy` ≠ end-to-end working

Always read the actual `healthcheck.test` line in `docker-compose.yml` before treating Docker `Healthy` as evidence that a service is functioning. Common shallow checks that pass even when the service is broken:

- `test -p /var/log/cron.log` — only proves cron daemon initialised, not that scheduled jobs work
- `nc -z 127.0.0.1 PORT` — only proves something is listening, not that it handles requests
- `wget -qO- /_info` or `curl /_info` — passes on HTTP 200 even if `/_info` reports `ok: false` internally
- `test -f /var/run/service.pid` — only proves the process started

For services where a specific operation must work (e.g. SSH authentication, database connection), the healthcheck should verify that operation, not just daemon presence.

**Why:** lucos_creds 2026-05-09 incident — `lucos_creds_configy_sync` showed Docker `Healthy` in 2.0s during a failed deploy because the healthcheck only checked `test -p /var/log/cron.log`, not whether SSH authentication worked.
