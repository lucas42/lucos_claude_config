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

**The 401/403 split is SERVICE-SPECIFIC — read the service's own auth code before using it.** It is *not* an estate-wide convention, and treating it as one produces a confidently wrong diagnosis.

`lucos_media_metadata_api/api/authentication.go` (Go):

- **401 "Authentication Failed"** → key value not in that instance's `CLIENT_KEYS` map at all. Wrong environment, or genuinely unregistered.
- **403 "Insufficient Scope"** → key IS registered; the *scope* doesn't cover the method/path.

`lucos_eolas/app/lucos_eolas/lucosauth/decorators.py` (Django) — **collapses both cases into 403**: `getUserByKey` returning `None` hits `else: return HttpResponse(status=403)`, the same code as an under-scoped key. Pinned by `test_key_scheme_invalid_key_returns_403`. Here **401 means only "no `Authorization` header at all"**, and unknown-vs-under-scoped is indistinguishable from outside.

So a 403 proves "registered but under-scoped" *only* on services that separate the two. When they don't, fall back to the hash-compare below, which answers the registration question directly and works regardless of status code. (2026-07-18: a 403 from prod eolas was read as a scope problem via the Go rule; it was actually an unregistered key — same root cause as `lucos_media_weightings#267`, different status code.)

## Diagnosing without exposing secrets

Agents can read **any** system's `development` `.env` via `scp -P 2202 creds.l42.eu:<system>/development/.env`. To find which server env a client key belongs to: fetch the *server's* dev `.env`, parse `CLIENT_KEYS`, and **hash-compare** the client's key value against each entry — printing only `clientsystem:clientenvironment` + scope, never values. A match proves the link is `serverenvironment=development`; combined with the ONE-serverenvironment rule, that proves no production link exists.

## The trap this exposes

When a dev client 401s against a prod server, the tempting "fix" is to re-link it to `serverenvironment=production`. **Check the scope first.** Scopes travel with the link, so re-pointing a `…:write` link at production silently grants a development system write access to production data. Usually the *credential* is right and the client's `*_ORIGIN`/`*_ENDPOINT` env var is what's wrong. Worked example: `lucos_media_weightings#267` (2026-07-15) — dev `MEDIA_API` pointed at prod `media-api.l42.eu` while the key was dev-linked with `media-metadata:read,media-metadata:write`; the service PUTs weightings every run, so the wrong fix would have let local dev runs rewrite the production music library.

**Smell test for env drift — outlier-hunting, and its limit.** Compare a system's env vars against each other. In weightings/development, `APP_ORIGIN` and `MEDIA_METADATA_MANAGER_ORIGIN` were both `localhost`; `MEDIA_API` alone pointed at production. The outlier is the bug. A server's own dev `APP_ORIGIN` tells you what clients should point at (`lucos_media_metadata_api/development` → `http://localhost:3002`).

**This only works where localhost is the norm — check that premise first.** In `lucos_time/development` (2026-07-18) *all three* external origins point at production (`EOLAS_URL`, `LUCOS_CONTACTS_ORIGIN`, `MEDIAURL`) and only `APP_ORIGIN` is localhost. There is no outlier, so the test yields nothing and "it's drift" is unsupported — it could equally be a deliberate read-from-prod dev setup. When prod-pointing is the norm, say you can't tell from config alone rather than importing the drift conclusion from another system.
