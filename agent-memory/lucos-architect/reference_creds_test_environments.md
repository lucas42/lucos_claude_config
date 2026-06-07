---
name: creds-test-environments
description: lucos_creds test-environment pattern (ADR-0002) — open env namespace, single-valued allowed-environment, the bright-line no-prod-secrets rule, and the agent-access mechanism
metadata:
  type: reference
---

# Test environments in lucos_creds (ADR-0002, 2026-06-07)

Triggered by lucos_dns#99 (first consumer). Tracking issue lucos_creds#363; PR #364 (Proposed). Designed with lucos-security.

**Genuinely greenfield** — NO secrets are stored with environment=`test` anywhere (lucas42 confirmed). Note: a `scp .../<system>/test/.env` exiting 0 does NOT prove a test env exists — `controller.go readFileByHandle` sets `found=true` unconditionally for any well-formed `system/env/.env` handle, and SYSTEM/ENVIRONMENT built-ins are auto-injected for any combo. (I briefly mis-concluded lucos_contacts/test existed from exit-0; reverted. See [[feedback_verify_ci_mechanism_before_relying_on_it]].)

## Mechanism facts (verified in server/src)

- **Environment namespace is OPEN.** No enum/allowlist of valid environment names. An environment exists the moment a credential is written to a `system/env` pair; vanishes when its last credential is deleted. Creating `test` needs **no** server/schema change.
- **`allowed-environment` is SINGLE-VALUED.** `keys.go` parses `restrict-environment="X"` from `authorized_keys`; `server.go` enforces equality at every op (ls, get, set, delete, linked-cred ×2, sftp stat/read). A key is scoped to exactly ONE env, or (unset) ALL. **No way to express "development AND test but not production"** without a code change.
- **Current key scoping:** `lucas`, `docker-deploy`, `tests`, `lucos_creds_ui`, `lucos_creds_configy_sync` are all **unrestricted** (incl. production). Only `lucos-agent-coding-sandbox` is restricted (`development`). Same check gates writes → agents write `development` only.

## The decisions

1. **Contents** = standard env rule: only secrets or env-varying values; non-secret/non-varying config stays in `docker-compose.yml`. Legit contents = env-varying config + *test-scoped* secrets (e.g. a `test→test` linked credential, dummy keys).
2. **Bright-line rule: a test env must NEVER contain a production secret.** Security endorsed it as a *single inspectable invariant* (beats the dual-invariant "allow prod secrets but exclude from agent keys"). Gated exception requires written rationale + agent-key exclusion + lucas42 sign-off; never agent-accessible.
3. **Access:** standard test envs **ARE** in the agents' permission set (read+write, == development), safe because of rule 2. Needs `restrict-environment` extended to a **set** (`development,test`) — prerequisite follow-up lucos_creds#360.
4. **Pulled by:** CI test jobs (existing unrestricted `tests` key — dns#99 path, **no code change blocks it**); agents (after #360); local dev (human key).

## Follow-ups
- lucos_creds#360 — set-valued `restrict-environment` + `test` on agent key (prereq for agent access; contingent on ADR Accepted)
- lucos_creds#361 — audit/right-scope the over-broad `tests` CI key (security: prod-secret CI-exfil risk)
- lucos_creds#362 — periodic test-vs-prod key-NAME collision audit (defence-in-depth) + optional UI warning
- lucos_dns#100 — dns config-sync test writes to PRODUCTION loganne/schedule_tracker (security flag; may cascade into those services needing test envs)

## Why dns#99's endpoints legitimately go in creds (not compose)
`lucos_dns/development` stores `LOGANNE_ENDPOINT`/`SCHEDULE_TRACKER_ENDPOINT` (type `simple`) → they vary by env → convention says creds, not hardcode. So dns#99's test env is convention-consistent (and trivially satisfies the bright-line: no secrets at all). Don't claim "dns doesn't need a creds test env" — checked, it does.

See [[reference_creds_store_enumeration]], [[reference_lucos_creds_deploy_snapshot]].
