---
name: 2026-05-09 libcrypto incident lessons
description: Three load-bearing sysadmin lessons from the lucos_creds SSH key CRLF incident
type: project
---

Incident report: https://github.com/lucas42/lucos/blob/main/docs/incidents/2026-05-09-creds-ssh-key-crlf.md

**Lesson 1 — `Load key … error in libcrypto` is a class, not a specific failure**

Any non-base64-alphabet character in a PEM key triggers this: `\r` (CRLF line endings), `~` (tilde-mangled newlines), whitespace, BOM, etc. When you see this error, the question is not "which newline character" but "what character is polluting the base64 body." Read the raw bytes with `xxd` or `od -c` to identify the actual offender.

**Lesson 2 — When a fix to live state doesn't survive a redeploy, check if the deploy reads live state or a snapshot**

The lucos_creds SSH key was fixed in live state but the fix was silently reverted on the next deploy because the deploy pipeline reads `LUCOS_DEPLOY_ENV_BASE64` (a base64-encoded snapshot), not the live credential store. 

General check: `grep -r 'DEPLOY_ENV_BASE64\|_ENV_BASE64' ~/sandboxes/` in any CI config to find other services with snapshot-based deploys. These require dual-update when credentials change.

For `lucos_creds` specifically: the update procedure is documented in the runbook at `https://github.com/lucas42/lucos/blob/main/docs/runbooks/update-lucos-creds-production.md`.

**Lesson 3 — Docker `Healthy` is not proof of end-to-end functionality**

Before treating a `Healthy` container as recovery proof, read the actual `healthcheck.test` line in `docker-compose.yml` or via `docker inspect`. Example: `lucos_creds_configy_sync` healthcheck was `test -p /var/log/cron.log` — entirely uncorrelated with SSH key validity. A service can be `Healthy` while its core function is broken.

**Why:** During the incident, `Healthy` status on `lucos_creds_configy_sync` was briefly interpreted as the fix taking effect, delaying diagnosis by several minutes.

**How to apply:** When investigating incidents, always read the healthcheck command before citing container health status as evidence. If the healthcheck doesn't probe the broken function, it's uninformative.
