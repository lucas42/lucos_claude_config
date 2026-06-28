---
name: pattern-contacts-403-for-unrecognised-key
description: During a creds key-rotation cutover, contacts returns 403 (not 401) for an unrecognised key — so 401-vs-403 can't tell key-mismatch from missing-scope; read CLIENT_KEYS
metadata:
  type: project
---

# Scope/key-rotation cutover: 403 ≠ "missing scope" (contacts api_auth)

**Context:** Wave 4 contacts auth reshape, 2026-06-28 (lucos_contacts#755 merged 19:47:24Z, contacts deployed 1.0.92 at 19:53). Setting machine scopes in lucos_creds **rotates each consumer's `KEY_LUCOS_<SERVICE>`**; running consumers keep presenting the OLD key until they redeploy.

**The trap:** contacts' `api_auth` returns **403 for an unrecognised key**, NOT 401. So during a key-rotation cutover, a 403 is **ambiguous**: it can be (a) old/rotated key not in the server's CLIENT_KEYS, OR (b) valid key but the principal lacks the scope. **You cannot classify "needs redeploy" vs "needs a prod scope grant" from the 401-vs-403 status code** — and you'll see ZERO 401s the whole time. (team-lead's and sysadmin's instinctive "401=key, 403=scope" heuristic was wrong here.)

**The decider — read the server's live CLIENT_KEYS on the running container:**
`ssh <host> "docker exec <svc>_app printenv CLIENT_KEYS"` → entries are `client_name:<KEY>|scope1,scope2` (no `|scope` = scopeless). This shows definitively which consumers HAVE a scope. If the scope is present → the 403 is an old-key mismatch → fixed by **redeploying that consumer** (fetches rotated key). If the scope is ABSENT → genuinely needs the prod scope set (lucas42; team can't write prod creds). **Redact key material when printing** (mask `[A-Za-z0-9+/=_-]{40,}`).

**Stuck-403 AFTER a consumer redeploy** = the SERVER's CLIENT_KEYS snapshot is stale vs creds (server baked an older key than creds now issues) → **redeploy the server** (contacts), not a scope change. (architect's call.)

**This cutover's outcome:** every active consumer (aithne, googlesync→write, photos→read, time→read, external_calendar→read) already had its scope in CLIENT_KEYS; all cleared purely on redeploy. NONE needed a prod scope set (incl. sysadmin's suspects time+aithne). Only fb/gphotos scopeless = deferred (lucos_creds#420).

**Identifying consumers behind generic UAs** (router logs all internal callers as one bridge IP, UA often generic): Go-http-client=aithne; python-httpx bulk `GET /people/<N>`=lucos_photos (`sweep_contact_display_names` worker job); googlesync sets a named UA. Confirm via the consumer's OWN container logs (e.g. photos_worker logs the 403 + job name). See [[pattern_scope_cutover_convergence_and_enumeration_gap]] and [[reference_lucos_creds_key_rotation]].
