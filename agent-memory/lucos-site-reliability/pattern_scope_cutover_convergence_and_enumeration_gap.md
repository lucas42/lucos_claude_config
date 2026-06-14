---
name: scope-cutover-convergence-and-enumeration-gap
description: How to verify a lucos_creds scope cutover (eolas/media-metadata pattern) via the router access log, and the holder-enumeration-gap class (a client granted only some of the capabilities it actually uses → 403s under enforcement)
metadata:
  type: pattern
---

Scope cutovers (server enforces new `scope:read`/`scope:write`, clients redeploy onto rotated keys — see dispatcher's [[reference-lucos-creds-key-rotation]]) converge via concurrent redeploys. SRE arms an auto-fire watcher on the server PR's merge that POSTs all client CircleCI redeploys (`POST /api/v2/project/gh/lucas42/<repo>/pipeline {"branch":"main"}`), then watches convergence.

**Verification = the lucos_router access log on avalon** (`docker exec lucos_router` / `docker logs lucos_router`). Go services (eolas, media-metadata-api) don't log requests; the router log is the evidence. Log line: `IP - - [time] <host> "METHOD path HTTP/1.1" STATUS bytes "ref" "<user-agent=caller>" "-"`. The UA field = the calling service (e.g. `lucos_time`), but some clients show `python-requests/...`, `Java-http-client/...`, or `-` (can't always attribute by UA). Filter by host: eolas=`eolas.l42.eu`, **media-metadata API = `media-api.l42.eu`** (NOT `media-metadata.l42.eu` — that's media_metadata_*manager*). Watch for: transient pre-redeploy 403 (a client wrote/read 9s before its own redeploy completed = expected, NOT standing), then 200/2xx after. Verify BOTH read (GET 200) and write (POST/PUT/PATCH 2xx) per client; writes are organic + infrequent (no synthetic injection — wait for one). 499 = client-closed, NOT auth (ignore for convergence).

**HOLDER-ENUMERATION GAP (the big lesson, 2026-06-14 eolas cutover):** a service can be granted only a SUBSET of the capabilities it actually uses. mma's eolas key was set to `eolas:write` only, but mma also READS eolas (its `reconcile_tag_names` job fetches names) → reads 403'd under enforcement → job failed → **monitoring alert `lucos_media_metadata_api/reconcile_tag_names`**. Fix: add the missing scope (`eolas:read,eolas:write`), redeploy server + client.

Durable takeaways:
1. **Enumerate each client's ACTUAL read+write usage of the server, not its assumed role.** A "writer" may also read (and vice-versa). Verify BOTH paths for every client.
2. **The monitoring board is the authoritative safety net, not the router log.** mma's eolas reads are infrequent (zero GETs in a 3h router window) — the gap surfaced as a red `reconcile_tag_names` schedule check, which I would NOT have caught by tailing the access log. When hunting enumeration gaps, check `monitoring.l42.eu/api/status` (uses `status` field not `ok`) for any failing check on the clients/dependents, AND scan the log for 403s. Both together.
3. A red dependent check (e.g. `media_metadata_manager/metadata-api`, `media_weightings/media-api-reachable`) can also blip transiently during the server's deploy window — recovers on its own; distinguish from a standing gap.
4. Eolas writers seen: mma `POST /metadata/names`, `POST /api/metadata/person/` (201). Media-api writers: `PATCH /v3/tracks/{id}`, `PUT /v3/tracks/{id}/weighting` (python-requests = likely media_weightings). lucos_loganne uses `webhook` scope (unchanged across these cutovers, no redeploy).
5. `#319`/`#308` merged FAST — by the time a "going to merge now" dispatch arrives, the PR may already be merged; check `merged` state first and fire redeploys immediately rather than arming a merge-watcher for an already-merged PR.

**Reading/writing a cred SCOPE (NOT in the lucos_creds README — found in server/src/server.go:231):**
- Read: `ssh -p 2202 creds.l42.eu "ls <client>/<env>"` → JSON; client/linked creds have `type:"client"`, a `scope` field, and `server_environment`.
- Write/update a linked cred + scope: `ssh -p 2202 creds.l42.eu "<client>/<env> => <server>/<env>|<scope>"` — scope is **pipe-delimited** after the server env; multi-scope is **comma-separated, NO spaces** (e.g. `media-metadata:read,media-metadata:write`); validated to alphanumeric/colon/comma/hyphen only. Each write **rotates the key** (even scope-only change). REPLACE-INTO semantics. Agents have **dev** creds write access; prod is lucas42-only.
- 2026-06-14 least-privilege/dev-mirror: prod media_import → `media-metadata:write` only (write-only client). Dev environment was NEVER migrated during #6 (only prod) — dev creds sat on LEGACY scopes (`full`, `read`, `export:read`) until aligned. **Dev is local-only → no redeploy; cred update IS the convergence** (picked up next local `docker compose up`).
- ANOMALY to watch when aligning dev: a dev client cred can have `server_environment=production` (dev client → PROD server). Don't blindly apply a dev→dev `=>` (changes topology) or grant write to a dev→prod cred (dev writing prod data) — FLAG for the owner. (Hit on `lucos_media_metadata_api/development → lucos_eolas` = server_env production, 2026-06-14.)
- media_import deploys to **xwing-v4** (home host) → slower builds (see [[pattern_homehost_deploy_pull_slowness]]).
