---
name: creds-configy-sync
description: lucos_creds already auto-derives PORT and APP_ORIGIN from lucos_configy hourly via configy_sync — check this before proposing any new configy-derived credential
metadata:
  type: reference
---

# `lucos_creds` ← `lucos_configy` sync

Verified 2026-07-19 from `origin/main`. Complements [[creds-client-keys-environment-model]] and [[reference_lucos_creds_deploy_snapshot]].

**lucos_creds is already a configy consumer.** `configy_sync/sync.py` GETs `https://configy.l42.eu/systems` hourly and writes, for every system:

- `PORT` = `http_port`, into both `development` and `production`
- `APP_ORIGIN` = `http://localhost:{http_port}` (development) / `https://{domain}` (production), **only when both `domain` and `http_port` exist**; otherwise the credential is deleted

So **the origin string for any system, per environment, is already computed and stored** — it's just written to the system's *own* env, never to its clients. Check this before proposing "we should derive X from configy": the derivation may already exist.

## Mechanism details worth knowing

- **`type: config` marks auto-managed credentials.** `config_keys := []string{"PORT", "APP_ORIGIN"}` in `server/src/storage.go` (~line 222). `cleanupRemovedSystems` keys orphan-deletion off this *type* rather than a second hardcoded list, deliberately so the two can't drift. Any new auto-derived credential belongs in `config_keys`.
- **Environments are hardcoded to `["development", "production"]`** in the sync loop. Test environments (creds ADR-0002) get no configy-derived values.
- **Empty-response guard**: an empty configy `[]` aborts the run loudly rather than treating it as "every system removed" — see [[reconcile-empty-source-guard]] for the general pattern.
- **Propagation is eventual**: hourly sync + redeploy before a value reaches a running service. Not a live control plane.

## Coverage limits (as of 2026-07-19)

`config/systems.yaml`: **41 systems, 33 with `domain`, 31 with `http_port`.** So ~10 systems have no derivable origin. Non-HTTP systems (deploy orb, docker_health, import jobs) are the obvious members. Re-count rather than trusting these numbers — the file changes.

## Why this matters architecturally

Deriving inter-system *auth-critical* values from configy widens the blast radius of bad configy data beyond "a system doesn't know its own address". Raised on lucas42/lucos_creds#470 (client key + origin both derived from one linked credential).
