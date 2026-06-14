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
