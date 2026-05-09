---
name: lucos_creds self-deploy via LUCOS_DEPLOY_ENV_BASE64
description: lucos_creds bypasses SCP and reads .env from a CircleCI env-var snapshot; live store changes don't propagate
type: reference
---

`lucos_creds` cannot SCP its own `.env` from itself during deploy — the deploy orb's default path is `creds.l42.eu:2202`, which is the very service being redeployed (circular bootstrap, see `lucas42/lucos_creds#152`). PR `lucas42/lucos_creds#233` (merged 2026-04-10) plus `lucas42/lucos_deploy_orb#67` introduced an alternative: a CircleCI project env var `LUCOS_DEPLOY_ENV_BASE64` containing a base64-encoded snapshot of the production `.env`. When this var is set, the deploy orb decodes it directly into `.env` on the deploy target, skipping SCP entirely.

**Critical implication:** updates to `lucos_creds` storage **do not propagate** to the snapshot. The snapshot is updated only by an explicit manual step (re-encoding the current `.env` and PUT'ing it via the CircleCI API). When investigating lucos_creds issues where credential changes "don't take" after a redeploy, the first question is: *"is the deploy reading the live store, or the LUCOS_DEPLOY_ENV_BASE64 snapshot?"* For lucos_creds, the answer is always the snapshot.

Bit me 2026-05-09 (incident report at `lucas42/lucos/docs/incidents/2026-05-09-creds-ssh-key-crlf.md`): SSH keys with CRLF were re-stored in lucos_creds storage to fix; the redeploy still wrote the OLD corrupted bytes because the snapshot hadn't been refreshed. Pipeline 680 failed for this reason; pipeline 682 (snapshot also updated) recovered the service.

**Diagnostic next steps for lucos_creds:**
- If creds.l42.eu/_info ssh-server fails after a credential update + redeploy: assume the snapshot is stale until proven otherwise.
- The fix is dual: update `lucos_creds` live store **and** `LUCOS_DEPLOY_ENV_BASE64` in CircleCI, then redeploy.
