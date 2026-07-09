---
name: aithne-client-library
description: Proposal (lucos#264) to extract duplicated JS aithne-client auth into a shared npm library; boundary = library verifies+classifies, app presents
metadata:
  type: project
---

**lucas42/lucos#264** — proposal to extract the byte-identical JS aithne-client auth core (duplicated across creds/notes/seinn/loganne) into a shared npm library. Raised 2026-07-10 at lucas42's request off the lucos#260 audit.

**Why:** the four JS consumers carry copy-pasted `isJWKSInfraError` / `createServeStaleJWKS` / `parseCookies` / JWKS+`jwtVerify` core (verified byte-identical on origin/main). Both #260 audit bugs (bug#1 `error.code` should be `error.cause?.code`; bug#2 redirect-into-dead-aithne instead of local unavailable page) are structural consequences of the duplication. Security-critical → single-point-of-audit is the strongest argument (my #1 concern). navbar precedent = low overhead.

**How to apply (the load-bearing design call):** boundary is **library verifies + classifies; app presents**. Library returns `{authenticated, authorized, payload, errorKind:'infra'|'invalid'|'none'}`; the `errorKind:'infra'` surface IS the fix for both bugs. App keeps: injected scope string, 403 template, the local "sign-in unavailable" page (per-app UX — NOT libraryable), login redirect, CSRF (diverges 3 ways), loganne's Bearer path, notes' WebSocket reuse. Config (origin + `AITHNE_JWKS_URL` dev/prod override) is **injected**, not read from `process.env` by the library. All four consumers are server-side Express — no browser jose, so no "browser-vs-container" split.

**Routing/sequence:** #264 = Awaiting Decision (lucas42 go/no-go). On approval: sysadmin creates empty repo (proposed `lucos_aithne_client`) → **founding design = ADR-0001 in the NEW repo** (not a lucos estate ADR), routed to me, settles verify/classify boundary + stack (JS/`jose`/ESM) → scaffold → extract/publish v1 → 4 migration PRs. The four follow-ups (creds#449, notes#459, seinn#553, loganne#565) → Blocked on v1, re-scoped to "adopt library + local unavailable page". Non-JS #260 follow-ups out of scope; aithne `local-verification-contract.md` stays the cross-language source of truth. See [[project_machine_principal_sessions]].
