---
name: risk-wave4-csrf-samesite-none
description: CSRF regression risk in Wave 4 aithne migrations — pre-existing @csrf_exempt endpoints become vulnerable when aithne_session SameSite=None replaces SameSite=Lax session cookies
metadata:
  type: project
---

# Wave 4 CSRF Risk: @csrf_exempt + aithne_session SameSite=None

## The risk

`aithne_session` is `SameSite=None` (by design, for cross-service SSO). The old Django session cookie was `SameSite=Lax` (Django 3.1+ default). This matters for CSRF:

- **SameSite=Lax**: cross-site form POSTs do NOT include the cookie → `@csrf_exempt` views were safe
- **SameSite=None**: cross-site form POSTs DO include the cookie → `@csrf_exempt` views are now exploitable

Services with `@csrf_exempt` + form-data mutation endpoints (i.e., endpoints reading `request.POST.get(...)` not `json.loads(request.body)`) become CSRF-vulnerable when migrated.

**Why the regression isn't surfaced by tests:** Tests use `RequestFactory`/`Client` which don't simulate cross-origin cookie behaviour.

## What to check in each Wave 4 PR

Before approving: grep the codebase for `@csrf_exempt`. For each decorated view, check if:
1. It accepts state-mutating methods (POST/PUT/DELETE/PATCH)
2. The mutation code reads `request.POST` or `request.body` in a non-JSON format

If both: **CSRF vulnerability**. Require a fix before merge.

## Safe patterns (not vulnerable even with @csrf_exempt)

- `application/json` body (`json.loads(request.body)`) — cross-origin JSON POST requires CORS preflight; if CORS doesn't allow the origin, preflight fails
- `PUT`/`DELETE` requests — these require CORS preflight regardless of content type
- Machine-auth-only endpoints (only accessible via lucos_creds Bearer key, no cookie auth)

## Recommended fixes

**Option A (preferred):** Change form-data endpoints to require JSON body. JSON POST requires CORS preflight from cross-origin → blocks simple form CSRF. UI JS needs updating to use fetch with Content-Type:application/json.

**Option B:** Add explicit `*.l42.eu` origin check for cookie-authenticated mutations — same pattern as `checkCSRF()` in lucos_backups Wave 4.

## Found in

- lucas42/lucos_contacts#755 — `/agent/add` uses `request.POST.get('name')` under `@csrf_exempt`. Flagged REQUEST_CHANGES 2026-06-27.

## Possibly also in

- lucas42/lucos_eolas (Wave 4 reference, #321 merged 2026-06-26) — should be checked for the same pattern. Developer cited eolas as the reference.

**Why:** The consumer migration guide checklist (lucos_aithne#159) says "CSRF mitigation for cookie-auth mutation endpoints" — but the checklist assumes the service will add the check; it doesn't flag pre-existing `@csrf_exempt` as needing audit.
