---
name: review-aithne-migration-prs
description: Review checklist for lucos_authentication → lucos_aithne migration PRs, derived from lucos_arachne migration review findings
metadata:
  type: feedback
---

When reviewing an auth-migration PR (lucos_authentication → lucos_aithne), verify ALL of the following:

**Three-branch auth pattern (mandatory shape):**
- Valid token + required scope → proceed
- Valid token + missing scope → consumer's own styled 403 page — NOT a redirect (infinite loop if redirected)
- No/invalid/expired token → redirect to `{AITHNE_ORIGIN}/auth/login?next=…` with server-side path only (no open-redirect via query param)

**Security hardening (request changes if absent):**
- Algorithm pinning: `jwtVerify`/`jwt.decode` MUST pass `algorithms: ['ES256']` — without it, algorithm confusion attacks are possible (caught PR #637)
- `kid` sanitisation: strip C0 control chars (`\x00–\x1f`) and DEL (`\x7f`) from JWKS error messages before logging — `kid` is attacker-controlled (caught PR #646)
- ADR-0001 §6: gate on named scope check, NOT bare `principal_class` check (caught PR #639)
- Open-redirect in return URL: build `next=` from server-side `req.protocol` + host, not from `req.query['X-Forwarded-Proto']` — the latter is user-controlled (caught PR #637)

**Operational requirements:**
- JWKS fetch failures logged at WARNING level, distinct from JWT validation failures — without this, JWKS outage = silent 401 storm (caught PR #641)
- `AITHNE_ORIGIN` must come from `process.env.AITHNE_ORIGIN` / `os.environ.get("AITHNE_ORIGIN")`, never hardcoded URL (caught PR #661)
- Read `ENVIRONMENT` inline on each call, not at module load time — module-load reads break test isolation (caught PR #639)

**Standard exemptions:**
- `/_info` exempt from auth (before auth middleware in route table)
- `render-ui` dev bypass only when `ENVIRONMENT == "development"`

**Why:** These were all real bugs caught in lucos_arachne migration PRs #637–#675, not theoretical. The consumer migration guide (`lucos_aithne/docs/consumer-migration-guide.md`) covers the three-branch pattern and AITHNE_ORIGIN; the security hardening items were missing (tracked in lucos_aithne#198).
