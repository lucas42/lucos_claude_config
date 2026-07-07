---
name: lucos-worlds-bookstack-deploy
description: Lessons from the lucos_worlds (BookStack) first production deploy — DB password/volume-init gotcha, APP_KEY formatting, and a genuine BookStack/aithne OIDC algorithm incompatibility
metadata:
  type: project
---

## MariaDB/MySQL: password changes after first init don't take effect

MariaDB (and MySQL) only run their init logic — creating `MARIADB_USER`/`MARIADB_PASSWORD`, creating the database — **once, against an empty data directory**. If a container first boots with an empty or wrong password value, the app user is silently skipped (no error, container reports `healthy` anyway) or created with the wrong password. Setting the correct value in creds afterward and just redeploying does **not** fix it — the persisted volume already has a data directory, so init never reruns.

**Symptom:** `Access denied for user 'X'@'...' (using password: NO)` (user never created) or `(using password: YES)` (user created, but with a stale password that no longer matches creds — happens if the creds value changes again after a successful init).

**Fix:** stop the DB container, `docker volume rm` the DB data volume, redeploy. Only safe when the volume has no real data yet (first-ever deploy) — this is exactly the `recreate_effort` judgment call the backup-diligence habit exists for.

**Why this happened twice in one deploy:** DB_PASSWORD was set in prod creds, but its *value* changed again (lucas42 re-set it) after the first successful init — both containers agreed on the new value, but the value baked into the DB from init was the old one. Same root cause, different trigger. If DB_PASSWORD is going to be touched more than once during a rollout, always re-verify actual DB auth (not just "the env var is now set") before declaring done.

## Laravel `APP_KEY` needs the literal `base64:` prefix

`APP_KEY=<44-char base64 string>` (no prefix) causes Laravel to treat the value as 44 *raw* bytes rather than base64-decoding to 32 bytes — `Unsupported cipher or incorrect key length`. The value must be exactly `base64:` + `openssl rand -base64 32` output, with `base64:` as the literal first 7 characters. This bit us twice: once in local testing, once in prod even after documenting it in the repo README — the README note alone didn't prevent the mistake at credential-setting time. When handing off an APP_KEY-generation instruction, give the exact one-liner (`base64:$(openssl rand -base64 32)`), not just prose.

## BookStack ↔ lucos_aithne: OIDC login does not work (upstream limitation, not fixable via config)

**Confirmed 2026-07-07, verified against source, not a guess:** BookStack (`linuxserver/bookstack`, confirmed on both the pinned `26.05.2` tag and current `development` HEAD) hardcodes its OIDC JWKS key filter and its `OidcJwtSigningKey` loader to accept **only RSA keys with `alg: RS256`** — enforced in two independent code paths (`OidcProviderSettings::filterKeys()` and `OidcJwtSigningKey::loadFromPath()`/`loadFromJwkArray()`).

`lucos_aithne` signs OIDC ID tokens **exclusively with ES256** (EC/P-256), by deliberate design (`oidc.go` hardcodes `IDTokenSigningAlgValuesSupported: []string{"ES256"}`) — already relied on by `lucos_locations`.

Result: BookStack filters out 100% of aithne's JWKS keys, ends up with an empty key set, and throws `InvalidArgumentException: Missing required configuration "keys" value` (HTTP 500) the moment OIDC login is attempted — even though the login button renders fine and discovery itself succeeds. **The button rendering and the OIDC config accepting values is NOT proof the login flow works — you must actually drive `POST /oidc/login` with a valid session+CSRF token to catch this.**

No fix exists upstream (open feature request since ~2025-01, no config-level bypass — `OIDC_PUBLIC_KEY`'s manual-key path enforces the same RSA-only check) as of 2026-07-07. Also confirmed: BookStack's `AUTH_METHOD` is a single exclusive choice (`standard`/`ldap`/`saml2`/`oidc`) — no fallback login path when set to `oidc`.

**This blocks lucos_worlds' entire purpose (auth via aithne) until a real design decision is made** (patch BookStack's vendored code, have aithne additionally publish an RS256 key, or something else) — escalated to lucas42/lucos-architect via lucas42/lucos_worlds#2, not something to solve unilaterally as sysadmin. If any other future "adopt a self-hosted tool + wire to lucos_aithne OIDC" ADR comes up, **check the tool's OIDC library's supported signing algorithms against ES256 before committing to the design** — this exact gap could recur with any other RSA-only OIDC client library.

## Process gap: branch protection must exist BEFORE the first PR, not after

On this from-scratch repo, I hadn't yet run the branch-protection step of the provisioning script when the first PR was reviewed. `lucos-code-reviewer`'s approval fired the auto-merge workflow, which merged immediately since there was no required status check to wait on — merging *before* CircleCI's build even finished, regardless of the (later) CI failure. Provision branch protection (`ci/circleci: lucos/build` as a required check) as step 1 of a new-repo standup, before any PR lands — not as cleanup after the fact. See `new-repo-provisioning-script.md`.
