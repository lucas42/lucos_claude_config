---
name: pattern-repo-name-not-container-name
description: In runbook/ops per-container commands, the JWKS/auth-consuming service is often a SEPARATE container from the repo name (lucos_creds_ui not lucos_creds; lucos_arachne_mcp + _explore not lucos_arachne) — restarting the wrong one is a SILENT no-op
metadata:
  type: reference
---

When writing any per-container command (a runbook `docker restart`, an incident action, an ops-check probe), **the container name is NOT the repo name.** Several estate repos ship the auth/JWKS-verifying service as a *distinct* container alongside a backend that has no aithne config. Verify against each repo's `docker-compose.yml` `container_name:` before putting a name in an artifact.

Confirmed splits (aithne#307, 2026-07-09):
- **lucos_creds** repo → three containers: `lucos_creds` (Go backend, port 2202, SSH-key/secret storage, **no `AITHNE_ORIGIN`/`AITHNE_JWKS_URL`** — NOT a JWKS consumer), `lucos_creds_configy_sync`, and **`lucos_creds_ui`** (the serve-stale JWKS consumer gating `creds:admin`; has the AITHNE env vars; builds from `ui/src/auth.js`). The consumer is `lucos_creds_ui`.
- **lucos_arachne** repo → the two serve-stale consumers `/mcp` and `/explore` are **two separate containers** `lucos_arachne_mcp` and `lucos_arachne_explore` (plus `_web`, `_triplestore`, `_ingestor`, `_search`). There is **no** `lucos_arachne` container.
- Single-container (name == `lucos_<repo>`): seinn (`lucos_media_seinn`), loganne (`lucos_loganne`), notes (`lucos_notes`).

**Why this bites hard:** `docker restart <wrong-container>` returns a **clean success** and restarts *something*, so nothing tips off an operator mid-incident — while the actually-vulnerable container stays up untouched. In aithne#307 the pre-review draft said `docker restart lucos_creds`, which would have no-op'd the single highest-value target (`creds:admin`, every stored secret) during a signing-key-compromise response. A restart that *looks* like it worked but targeted the wrong container is worse than a command that errors.

**Rule:** grep `container_name:` in the repo's compose before writing the command; don't assume `lucos_<repo>`. See [[feedback_verify_before_propagating]]. Related: [[pattern_pwa_sw_render_drops_aithne_origin]] (the creds/arachne serve-stale consumers), [[reference_lucos_creds_self_deploy]].
