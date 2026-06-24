---
name: auth-scopes-vocabulary
description: lucos_auth_scopes design — flat scope list, domain≠service, enforcement is backend-side; no scope→backend mapping exists
metadata:
  type: reference
---

`lucas42/lucos_auth_scopes` = the issuer-agnostic **scope vocabulary** for lucOS authz. Single file `scopes.yaml` (a flat YAML list of strings); the file **IS** the allowlist. Consumed at build-time (docker COPY) by `lucos_aithne` and `lucos_creds` (no runtime polling). Design rationale: `lucos_aithne` ADR-0001 §6/§7.

**Three things to remember for any scope/authz consultation:**
1. **Flat list, NOT service-keyed.** Grouping by service was considered and *explicitly rejected* — "a capability often spans services, so a service-keyed structure mis-models it."
2. **`domain:` prefix ≠ owning service.** Scope form is `domain:capability` (e.g. `eolas:read`, `media-metadata:write`) or bare (estate-wide: `render-ui`, `webhook`). The `domain` is the resource/capability area, "not required to be the full lucos_configy system code" — often coincident, never guaranteed. So you CANNOT reliably derive the backend from a scope string.
3. **Enforcement is backend-side, default-deny.** aithne makes a scoped *assertion*; each backend decides what a scope permits. A scope a backend doesn't understand is **inert** (no escalation).

**Consequence (used in lucas42/lucos_creds#386, 2026-06-14):** there is no scope→backend relationship anywhere in the data model (creds stores `serversystem` + `scope` independently; validation is character-class only — see [[feedback_test_prescribed_values_against_rule.md]]). So a UI scope picker should offer the **full** vocabulary, not filter by backend — filtering would require re-introducing the rejected service-keyed structure AND would wrongly hide the cross-cutting bare scopes. Surface each scope's inline `scopes.yaml` comment as helper text instead.

Grant model: a credential carries a comma-separated subset, `key|scope1,scope2`. No wildcard/`full` scope by design (least-privilege must be explicit/auditable). Vocabulary changes are build-time coupled, default-deny, lucas42-approval-required.

**The `:read` suffix is LOAD-BEARING in lucos_creds (not just cosmetic).** `allScopesReadOnly` (`server/src/scopes.go`) treats a scope as read-only **iff it ends in `:read`**, and the dev→prod linked-credential guard (`storage.go`) rejects any non-`:read` scope on a link from a non-prod client to a prod server (so a compromised dev key can't write prod). Naming consequence for any new scope: name a genuinely GET-only/read capability `<domain>:read` AND make sure it really is non-mutating; name anything that mutates `:write`/`:admin` (never `:read`). This reinforces the README's generic-verb preference and is a real correctness constraint, not style. (Surfaced doing lucas42/lucos_auth_scopes#19 — the holistic UI-scope pass for the remaining aithne session consumers, PR #20: backups/contacts/creds/loganne/media-seinn/notes/photos got per-service scopes; eolas + media_metadata_manager reuse existing ones — capability-not-interface.)

**Current vocab state (verified origin/main 2026-06-24, #19 CLOSED):** `render-ui`, `aithne:admin`, `arachne:read`, `eolas:read`/`eolas:write`, `media-metadata:read`/`media-metadata:write`, plus `:use` singletons for backups/contacts/creds(`creds:admin`)/loganne/media-manager/notes/photos, and bare `webhook`. **There is NO human-admin scope for eolas or contacts, and `contacts:use` conflates read+edit.** eolas:read/write are the MACHINE-API (@api_auth/creds-key) scopes — NOT the human Django-admin session. So the Django human-admin surface had no scope until ADR-0002 (below) proposed `eolas:admin` / `contacts:read` + `contacts:admin` (retire `contacts:use`) — a NEW vocab PR (since #19 closed), build-time coupled, gating the eolas+contacts code migrations.
