---
name: lucos-creds-scoped-key-permissions
description: lucos_creds CLIENT_KEYS scope design (lucos_creds#87) — fail-closed scopes, server-side-only enforcement, deploy-then-set-scopes sequencing
metadata:
  type: project
---

# Design: lucos_creds scoped key permissions (lucos_creds#87, approved 2026-03-13)

`CLIENT_KEYS` format extended with `|` delimiter for optional scopes:
```
clientsystem:clientenv=key|scope1,scope2
```
Unscoped entries unchanged. Scopes only set after the server is migrated (deploy first,
set scopes second — env vars pulled at deployment time is the natural safety checkpoint).

Key security decisions accepted:
- **No scope = no permissions** (fail-closed by default on migrated systems)
- Scope enforcement is server-side only; client never knows its own scopes
- Scopes opaque to lucos_creds; each service defines its own vocabulary (`{resource}:{action}`)
- Loganne audit trail for scope changes included
- Scope-aware flag rejected — migration risk accepted given deployment-time env var pull

Do not re-raise the scope-aware flag concern.

# Risk: LUCOS_DEPLOY_ENV_BASE64 silently reverts credential rotations

`lucos_creds` bootstraps its own deploy from a manually-maintained base64 snapshot
stored as a CircleCI env var (`LUCOS_DEPLOY_ENV_BASE64`), which overwrites the
production `.env` on every redeploy.

**A credential rotation applied only to the live lucos_creds store silently fails to
take effect.** The deploy writes `.env` from the stale snapshot, not the live store —
the running service never sees the new value, at any point, unless
`LUCOS_DEPLOY_ENV_BASE64` is also updated. Affected credentials (lucos_creds's own
`.env`, not creds it stores for others):
- `UI_PRIVATE_SSH_KEY`, `CONFIGY_SYNC_PRIVATE_SSH_KEY`, `KEY_LUCOS_CREDS` (the most
  sensitive cryptographic material in the estate — a silently-reverted rotation of
  `KEY_LUCOS_CREDS` is the worst case)

**Status (2026-05-09):** Runbook in lucos_creds#304 should include the explicit
callout that rotating any credential present in `LUCOS_DEPLOY_ENV_BASE64` without also
updating the CircleCI env var silently undoes the rotation on next deploy.
Architectural auto-sync deferred (cost). lucos_creds#306 adds startup validation of SSH
key material.
