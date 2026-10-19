---
name: project-creds-selfdeploy-keys
description: lucos#291 (2026-10-19) — lucos_creds sidecar SSH keys out of CircleCI: server-generated per-sidecar keys, grants stay in authorized_keys (ADR-0004), committed prod envfile replaces LUCOS_DEPLOY_ENV_BASE64
metadata:
  type: project
---
lucos#291 APPROVED by lucas42 2026-10-19 → lucos_creds ADR-0007 (PR #602, both bots approved on 21e9205, awaiting lucas42); impl creds#600 → #601 → orb#208. Dev store holds the same prod-authenticating sidecar keys (creds#603, High) — fixed by #600 cutover. Server generates keys for `lucos_creds_ui`/`lucos_creds_configy_sync` into per-sidecar named volumes (ro mount, skip_backup). Grants stay in committed `authorized_keys` — only key material generated (ADR-0004 "file is the policy"; #459 open, same parser). Rollback-safe cutover: old keys stay in snapshot until verified. Then a committed prod envfile + a generic orb branch; drop `LUCOS_DEPLOY_ENV_BASE64`, and probably `KEY_LUCOS_MONITORING` (its orb SCP is non-fatal; untested).

**Why:** lucas42 rejected hand-made keys on avalon ("messy"), wanted self-contained; `KEY_LUCOS_CREDS` was a security hallucination — never cite it.
**How to apply:** ADR goes in lucos_creds once he chooses. I rejected the sidecar-generates variant (startup cycle; a server compromise is total anyway).
