---
name: creds-store-enumeration
description: How to enumerate AND mutate systems/keys in the lucos_creds store over SSH, and the agent-key dev-only scoping limitation
metadata:
  type: reference
---

# Enumerating & mutating the lucos_creds store

The creds store is driven over SSH exec on `creds.l42.eu` port 2202 (handled in `server/src/server.go`). Read commands (safe):

- `ssh -p 2202 creds.l42.eu "ls"` → JSON list of **all** `{system, environment}` pairs (`getAllSystemEnvironments()` — DISTINCT across the `credential` table + `linked_credential` client/server systems).
- `ssh -p 2202 creds.l42.eu "ls <system>/<env>"` → that system/env's credential **keys** (values blanked server-side). Built-in derived keys `SYSTEM`/`ENVIRONMENT` always show here even with no stored rows — they're synthesised, not stored; check the full `ls` to see whether a system has real entries.
- `ssh -p 2202 creds.l42.eu "ls <system>/<env>/<KEY>"` → one credential's metadata (value blanked).

**Write/delete commands** (state-changing — dev-scoped for agents):

- Set: `ssh -p 2202 creds.l42.eu "<system>/<env>/<KEY>=value"` (`updateCredential`).
- **Delete a simple credential: `ssh -p 2202 creds.l42.eu "<system>/<env>/<KEY>="`** (empty value → `deleteCredential`, server.go:247). There is **no** bulk "delete whole system" command — delete each stored key individually; the built-in `SYSTEM`/`ENVIRONMENT` keys aren't stored so need no deletion, and the system vanishes from `ls` once its last stored credential is gone.
- Linked credentials: create `client/env => server/env`; delete `rm client/env => server`. Each delete fires a `credentialDeleted` Loganne event.

Used the delete path to action the `paperclip`/development removal (creds#333, 2026-06-01).

**Critical limitation:** the **agent SSH key is scoped to `development` only** (`allowedEnvironment` filter, set per-key). Every `ls` result comes back `development`; **production is invisible to agents**. Production enumeration (read or write) needs lucas42's production-scoped key or the creds UI. Relevant for any creds↔configy reconciliation, since decom orphans accumulate in **production** (e.g. the `comhra` orphan).

**configy_sync only writes `PORT`/`APP_ORIGIN`** (derived from `systems.yaml`). Any other key on a system (API keys, client `KEY_*`, PEMs) is **manually managed**, not sync-managed — so an auto-cleanup keyed off `systems.yaml`-absence would wrongly delete legitimate manual creds. Used this in the creds#333 Step 1 audit (2026-05-31). See [[reference_lucos_creds_deploy_snapshot]].
