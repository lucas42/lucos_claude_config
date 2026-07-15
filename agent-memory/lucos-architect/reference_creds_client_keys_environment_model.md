---
name: creds-client-keys-environment-model
description: How lucos_creds builds CLIENT_KEYS per server instance, why client-env and server-env are independent, and how to diagnose a 401-vs-403 on an inter-system key without exposing secrets
metadata:
  type: reference
---

# `CLIENT_KEYS` / linked-credential environment model

Verified 2026-07-15 from `origin/main` source. Complements [[reference_lucos_creds_key_rotation]] and [[reference_creds_test_environments]].

## The model

A `linked_credential` row has **four** independent fields: `clientsystem`, `clientenvironment`, `serversystem`, `serverenvironment`. **Client env and server env are independent** — `foo/development → bar/production` is expressible.

`lucos_creds` `server/src/storage.go` builds each server instance's `CLIENT_KEYS` with:

```sql
SELECT * FROM linked_credential WHERE serversystem = $1 AND serverenvironment = $2
```

emitting `clientsystem:clientenvironment=value|scope1,scope2` joined by `;`.

**So a server instance only ever sees links whose `serverenvironment` matches its own.** A dev client's key works against the prod server *only* if a `serverenvironment=production` link exists for it.

**Hard constraint (creds README):** *"For a given pair of clientsystem/clientenvironment, each serversystem can only have ONE serverenvironment."* So a client pair cannot be linked to both dev and prod of the same server — the environments are mutually exclusive, not additive.

## Diagnosing a rejected inter-system key

**401 vs 403 is decisive — check it before theorising.** In `lucos_media_metadata_api/api/authentication.go` (the pattern to expect estate-wide):

- **401 "Authentication Failed"** → key value not in that instance's `CLIENT_KEYS` map at all. Wrong environment, or genuinely unregistered.
- **403 "Insufficient Scope"** → key IS registered; the *scope* doesn't cover the method/path.

Never reason past this distinction — it collapses "stale key / wrong env / bad scope" into one cheap observation.

## Diagnosing without exposing secrets

Agents can read **any** system's `development` `.env` via `scp -P 2202 creds.l42.eu:<system>/development/.env`. To find which server env a client key belongs to: fetch the *server's* dev `.env`, parse `CLIENT_KEYS`, and **hash-compare** the client's key value against each entry — printing only `clientsystem:clientenvironment` + scope, never values. A match proves the link is `serverenvironment=development`; combined with the ONE-serverenvironment rule, that proves no production link exists.

## The trap this exposes

When a dev client 401s against a prod server, the tempting "fix" is to re-link it to `serverenvironment=production`. **Check the scope first.** Scopes travel with the link, so re-pointing a `…:write` link at production silently grants a development system write access to production data. Usually the *credential* is right and the client's `*_ORIGIN`/`*_ENDPOINT` env var is what's wrong. Worked example: `lucos_media_weightings#267` (2026-07-15) — dev `MEDIA_API` pointed at prod `media-api.l42.eu` while the key was dev-linked with `media-metadata:read,media-metadata:write`; the service PUTs weightings every run, so the wrong fix would have let local dev runs rewrite the production music library.

**Smell test for env drift:** compare a system's env vars against each other. In weightings/development, `APP_ORIGIN` and `MEDIA_METADATA_MANAGER_ORIGIN` were both `localhost`; `MEDIA_API` alone pointed at production. The outlier is the bug. A server's own dev `APP_ORIGIN` tells you what clients should point at (`lucos_media_metadata_api/development` → `http://localhost:3002`).
