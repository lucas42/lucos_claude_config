---
name: creds-capability-axis
description: lucos_creds ADR-0004 — capability axis (metadata-vs-secret tier) for creds' own access control
metadata:
  type: project
---

**lucos_creds ADR-0004** (PR lucas42/lucos_creds#457, issue #384). Adds an orthogonal **capability** axis composing with the existing per-key **environment** restriction: *environment × capability*. Three capabilities: `creds:metadata:read`, `creds:secret:read`, `creds:write`.

**Why:** the scope-vocab migration (auth_scopes#6) and the C4 trust-edge (lucos_repos#426) need "see the shape of production without reading its secrets"; the single-axis model made production all-or-nothing incl. secrets. lucas42 ruled out a full-prod agent key, so #426 is blocked on this.

**Key design facts (verified against origin/main code 2026-07-12):**
- `lucos_creds` is **SSH-only** (`main.go` starts only `startSftpServer`; no HTTP). `creds:admin` in scopes.yaml names a *future* aithne admin console — not built yet, different plane.
- The metadata/secret boundary **already exists latently**: `ls` and `ls system/env` blank `credential.Value` in `server.go`; only `ls system/env/key` (3-part) and the SFTP `.env` read (`controller.go`) return decrypted values. So the tier is mostly *gating existing commands*.
- One genuine projection change: server-side `CLIENT_KEYS` value is blanked wholesale (hides the client→scope graph); must strip *only* the key value, preserve `client:env`+`scope`. Client-side `KEY_<SERVER>` already keeps `Scope` as a separate field, so the graph is readable per-client today.
- Attaches as a 2nd authorized_keys option (`restrict-capability=`) mirroring `restrict-environment` (ADR-0002 extended that to a comma-set). No schema change.
- **Default-allow** (absence = all capabilities), NOT default-deny — every system fetches its own `.env` via SFTP secret-read, so fail-closed would break prod deploys. Narrowing (agent keys, repos C4 key) is explicit.
- Vocabulary membership (creds:* in scopes.yaml) recommended but enforced via key-option plane, NOT `knownScopes` (different planes) — left as explicit decision for security + lucas42.

**How to apply:** creds is **supervised** → normal PR, lucas42 auto-requested. Drove code-reviewer + lucos-security review loop. On agreement, raise 4 deferred follow-ups (capability impl in creds; agent-key narrow; repos C4 metadata key → unblocks #426; scopes.yaml addition if §4 accepted) and send URLs to team-lead. #361 (tests key) + #375 (link-scope vocab) already CLOSED; aithne#12 CLOSED.

Related: [[feedback_file_followups_during_design]], [[reference_auth_scopes_vocabulary]], [[reference_creds_scope_keyvalue_independent]], [[project_machine_principal_sessions]]
