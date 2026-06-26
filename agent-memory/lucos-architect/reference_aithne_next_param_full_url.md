---
name: aithne-next-param-full-url
description: aithne login `next=` param must be a full same-origin URL, not a bare path, or the post-login redirect gets stuck
metadata:
  type: reference
---

When a consumer redirects an unauthenticated user to `{AITHNE_ORIGIN}/auth/login?next=…`, the `next` value MUST be a **full, absolute, same-origin URL** (e.g. `${req.protocol}://${req.headers.host}${req.originalUrl}`; Django `request.build_absolute_uri()`) — **never a bare path**.

**Why:** login happens on *aithne's* origin. After auth, aithne redirects the browser to `next`. A bare path (`/admin/`) resolves *relative to aithne's origin* (`{AITHNE_ORIGIN}/admin/`), so the user lands on aithne and never returns to the consumer — the round-trip "gets stuck". Only an absolute URL on the consumer's own origin brings them back. aithne's `redirect.go` `isAllowedRedirect` *accepts* a bare path (same-origin for aithne's own internal pages), so the mistake passes review but breaks cross-origin — recurred across ≥2 migrations.

The open-redirect guard is unchanged: build `next` server-side (never reflect a caller-supplied `?next=`) and validate it's your own origin before sending; aithne re-validates host against `l42.eu`/`*.l42.eu` (dev: localhost).

Documented in `lucos_aithne` consumer-migration-guide C2 (PR #226) and `lucos_eolas` ADR-0002 §4 (PR #325), both 2026-06-26 from lucas42's review of lucas42/lucos_eolas#324. Canonical correct example: arachne `explore/src/server/auth.js`. Related: [[reference_aithne_agent_principal_model]] (scope-not-principal_class authz, also reinforced by that review). See also [[feedback_scope_first_not_principal_class]].
