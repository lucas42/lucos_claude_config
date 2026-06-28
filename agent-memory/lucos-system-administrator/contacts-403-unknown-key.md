---
name: contacts-403-unknown-key
description: lucos_contacts returns 403 (not 401) for unrecognised CLIENT_KEYS — masks key-rotation mismatches as scope errors
metadata:
  type: feedback
---

`lucos_contacts` `api_auth` returns **403** for an unrecognised `KEY_LUCOS_CONTACTS` value — not 401. `getUserByKey()` misses the unknown key and falls through to a 403 response.

**Why this matters:** a creds scope annotation rotates the key (creds ADR-0003). A consumer presenting the pre-rotation key post-deploy gets a `getUserByKey` miss → 403. This looks like a *scope* error (wrong status code suggests "key is known but scope denied"), but it's actually a *key-rotation mismatch* (key no longer exists in `usersByKey`).

**How to apply:** during a Wave rollout or any key rotation:
- 403 on a machine caller does NOT mean the scope is missing from contacts' CLIENT_KEYS — it might mean the consumer is presenting a rotated-out old key.
- Always check the **live running contacts CLIENT_KEYS** (read the running container's env or logs) before concluding a scope grant is missing.
- The fix for 403-from-unknown-key is **consumer redeploy** (to fetch new KEY_LUCOS_CONTACTS), not a new scope grant.
- Only if the scope is genuinely absent from contacts' `CLIENT_KEYS` does lucas42 need to set a scope in production creds.

**Evidence:** Wave 4 cutover 2026-06-28 — all 403s were key-rotation mismatches; scopes were already staged. Both sysadmin and SRE initially misread 403s as missing grants.

[[reference-lucos-creds-key-rotation]]
