---
name: creds-capability-axis
description: lucos_creds ADR-0004 — capability axis (metadata-vs-secret tier) for creds' own access control
metadata:
  type: project
---

**lucos_creds ADR-0004** (PR lucas42/lucos_creds#457, issue #384). **Deny-by-default, scope-based grant model** for creds' own access. Redesigned 2026-07-12 with lucas42 (head `18bc63d`) from an earlier two-axes default-allow draft.

**Why:** the scope-vocab migration (auth_scopes#6) and the C4 trust-edge (lucos_repos#426) need "see the shape of production without reading its secrets"; the single-axis model made production all-or-nothing incl. secrets. lucas42 ruled out a full-prod agent key, so #426 is blocked on this.

**Final design (post-lucas42):**
- **One `authorized_keys` option `allow-scopes`** carrying scope-primary grants `scope@envset` (`;` sep grants, `,` sep envs, `@` scope-to-env). Replaces/removes `restrict-environment` (env now lives per-grant). Single option ⇒ the Extensions merge-vs-replace footgun dissolves.
- **Deny-by-default** both dimensions. Absence = no access, fails loudly. Footgun inverts to fail-closed. Migrated via ONE atomic PR annotating the 5 keys (flag-day: annotate→verify→flip; can't split or `.env` fetches break). Only 5 keys total (`lucas`,`docker-deploy`,`lucos_creds_ui`,`lucos_creds_configy_sync` unrestricted + `lucos-agent-coding-sandbox` dev,test) → tractable.
- **Scopes:** `creds:metadata:read`/`creds:secret:read`/`creds:write` (independent, flat) + `creds:admin` = a FIXED full-access scope encompassing exactly those three (NOT a wildcard; new scopes never auto-absorbed). Added to shared `scopes.yaml`.
- **Env wildcard `@*`; NO scope wildcard** (small finite set; each new scope grant is a deliberate "who needs this?").
- **Scopes = ordinary shared-vocabulary scopes** (Point D); only the *proof mechanism* differs per plane (JWT vs authorized_keys grant vs stored link scope) — not different "types". Dropped the documentary-vs-enforced hedging.
- **UI:** keeps its single `creds:admin` check UNCHANGED; UI key granted `creds:admin@*`; server recognises `creds:admin` as full access → same token both planes, consistent by construction, NO UI code change, no coarse bypass. (Resolves the reviewers' UI-surface concern without decomposing creds:admin.)
- **Boundary already latent**: `ls`/`ls sys/env` blank `credential.Value`; only 3-part `ls` + SFTP `.env` return values. One projection change: server-side `CLIENT_KEYS` must be built from `LinkedCredential` rows (never string-parse/decrypt) to expose client→scope graph w/o key value.
- **Honest asymmetry:** `@env` is an SSH-grant refinement, NOT in JWTs (env-agnostic) → humans via UI are all-environments; env-scoping is a machine-key least-privilege tool.

**How to apply:** creds is **supervised** → normal PR, lucas42 auto-requested. On agreement, raise **3** deferred issues (1: impl grant model + atomic 5-key migration; 2: add 3 scopes to auth_scopes scopes.yaml; 3: mint repos C4 `creds:metadata:read` key → unblocks #426) and send URLs to team-lead. #361/#375 CLOSED; aithne#12 CLOSED.

Related: [[feedback_file_followups_during_design]], [[reference_auth_scopes_vocabulary]], [[reference_creds_scope_keyvalue_independent]], [[project_machine_principal_sessions]]
