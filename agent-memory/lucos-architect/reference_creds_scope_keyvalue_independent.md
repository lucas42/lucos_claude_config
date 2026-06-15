---
name: creds-scope-keyvalue-independent
description: In lucos_creds the key value and scope are independent — scope changes need NOT rotate the key; the convergence 401 window for scope edits is avoidable
metadata:
  type: reference
---

Verified against live `lucos_creds` origin/main `server/src/storage.go` (2026-06-15, consulting on the 2026-06-14 media-stack 401 convergence window, ex-monitoring#286).

**Data model:** `linked_credential` table has `encryptedvalue` (the opaque random key) and `scope` as **separate columns**. Scope is NOT encoded into the key.
- **Client** (`getClientCredentialsBySystemEnvironment`) is handed `KEY_<SERVER>` = `PlainValue` **only** — the raw key. It never presents scope.
- **Server** (`getServerCredentialsBySystemEnvironment`) builds `CLIENT_KEYS` = `client:env=key|scope;...` and enforces scope **entirely server-side**.

**Why the convergence 401 window exists for scope changes:** `updateLinkedCredential` calls `generateNewEncryptedValue` **unconditionally** on every write (storage.go:~366), so editing a scope annotation rotates the *key value* too — a two-sided handover (clients redeploy onto new key before server accepts it → ~2-min 401 window, the 2026-06-14 incident). This rotation is **incidental implementation, not a protocol/security requirement** — the client doesn't present scope, so scope enforcement never depended on the key changing.

**The simple fix (closes the window for scope changes):** preserve the existing `encryptedvalue` on a scope-only edit (SELECT existing row first; only mint a new value when the row is new or an explicit rotation is requested). Then the client's `KEY_*` is unchanged → no client redeploy → no handover → no window. Only the server redeploys to pick up the new scope. **No security regression** — revocation is enforced server-side at redeploy regardless of whether the value changed. Clean framing: creds today *conflates* "edit scope" and "rotate the secret"; separate them (`setScope` preserves value, explicit `rotateKey` mints new).

**The hard residual:** a *true key rotation* (rotating the secret itself) still has the hard-cutover window — closing that needs key **overlap / dual-accept** (server accepts old+new transiently, then drops old; the Bearer-migration pattern, lucos#74). Non-trivial in creds; it's also exactly what **aithne**'s short-lived-JWT + JWKS (kid-based overlap) gives for free, so defer the overlap problem to aithne rather than building it bespoke into creds.

**Trap:** "order the rollout, server first" is NOT a simple win — with a single-valued key it just flips *which side* eats the 401s; it can't close the window without overlap. Value-preservation removes the ordering need for scope changes entirely.

Related: [[reference-lucos-creds-key-rotation]] (coordinator's memory — "rotates on every update"; this adds *why it's avoidable*), [[auth-scopes-vocabulary]], [[machine-principal-sessions]] (aithne JWKS end-state).
