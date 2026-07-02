---
name: pattern-eolas-dual-auth-static-key-vs-jwt-middleware
description: eolas runs TWO auth paths — @api_auth (static lucos_creds key) and AithneAuthMiddleware+@require_scope (aithne JWT); the middleware logs "Not enough segments" for every static bearer but never blocks — that log is NOISE on @api_auth endpoints
metadata:
  type: reference
---

**lucos_eolas has two coexisting auth mechanisms (ADR-0002 migration, PR lucas42/lucos_eolas#324):**

1. **`@api_auth(required_scope='eolas:read')`** — `lucosauth/decorators.py`. The *static lucos_creds key* path: `getUserByKey()` looks the `Authorization: Bearer <key>` value up in the `CLIENT_KEYS` env (format `system=key|scope1,scope2`, parsed once per gunicorn worker at import in `lucosauth/envvars.py`). Returns **401** if no auth header, **403** if key unknown OR key lacks the required scope. **This is the path the estate-standard static bearer keys use.** The data/bulk endpoints (`/metadata/all/data/`=all_rdf, `/metadata/<type>/<pk>/data/`=thing_data, `/metadata/names`=batch_names, `/metadata/<type>/list/`, `api/metadata/<type>/`=thing_create[eolas:write]) all use `@api_auth`.
2. **`@require_scope('...')` + `AithneAuthMiddleware`** — `lucosauth/aithne.py`. The *aithne JWT* path for human sessions (aithne_session cookie) and dev agents (Bearer JWT). Unauthenticated → 303 redirect to aithne login.

**THE TRAP:** `AithneAuthMiddleware` runs on EVERY request and tries to parse EVERY `Authorization: Bearer` value as a JWT. A static lucos_creds key has 0 dots → `JWT rejected: malformed token — Not enough segments` + "verification failed, treating as unauthenticated". **But the middleware NEVER blocks** — it only sets `request.user`; `@api_auth` then re-does its own key auth independently and overwrites `request.user`. So on `@api_auth` endpoints, **"Not enough segments" is harmless noise, NOT the cause of a 403.** Don't attribute a static-key 403 to the JWT middleware (I did, in lucos_arachne#711 — wrong).

**Decider for an `@api_auth` 403 (same as [[pattern-contacts-403-for-unrecognised-key]] / Wave4):** read the live server config — `docker exec lucos_eolas_app printenv CLIENT_KEYS` (avalon), parse per-system, check the consumer's entry has both the right key value AND the `|<scope>` annotation. Then run a live probe with the consumer's real key. arachne is registered `lucos_arachne:production=<key>|eolas:read` and works (200). See also [[pattern-arachne-eolas-dual-ingest-hyphen-pk]].
