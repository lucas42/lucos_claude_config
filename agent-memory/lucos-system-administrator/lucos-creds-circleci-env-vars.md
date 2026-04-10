---
name: lucos_creds CircleCI project env vars — manual rotation required
description: KEY_LUCOS_MONITORING and LUCOS_DEPLOY_ENV_BASE64 are set as CircleCI project env vars on lucos_creds and are NOT automatically rotated when the underlying credentials change
type: project
---

Two CircleCI project environment variables are set on `lucas42/lucos_creds` to break the circular deployment dependency (lucos_creds#152):

- **`LUCOS_DEPLOY_ENV_BASE64`** — base64-encoded production `.env` for lucos_creds. Set by lucos-system-administrator on 2026-04-10. Must be manually updated if any production env var changes (e.g. new service added, PORT change, SSH key rotation).

- **`KEY_LUCOS_MONITORING`** — monitoring suppression API key. Set by lucas42 on 2026-04-10. This is a **linked credential** in lucos_creds — when it is rotated via the normal lucos_creds credential management, the CircleCI copy is **not** updated automatically. Manual rotation step required.

**Why:** When lucos_creds deploys itself, it can't SCP from creds.l42.eu (port 2202 is briefly unavailable). These env vars allow the deploy orb to skip both SCPs. Without them the deploy still works but monitoring suppression is skipped.

**How to apply:** During any credential rotation involving `KEY_LUCOS_MONITORING`, flag to whoever is doing the rotation that the CircleCI project env var on `lucas42/lucos_creds` needs manual updating. Rotation via the CircleCI API: `POST https://circleci.com/api/v2/project/github/lucas42/lucos_creds/envvar` with `{"name": "KEY_LUCOS_MONITORING", "value": "<new_value>"}`.

Similarly, if the lucos_creds production `.env` changes significantly, `LUCOS_DEPLOY_ENV_BASE64` needs to be re-generated and updated.
