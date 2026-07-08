---
name: project_lucos_worlds_state
description: "lucos_worlds (BookStack worldbuilding) deployed 2026-07-07, login-blocked on BookStack-RS256 vs aithne-ES256 (#21); DECIDED 2026-07-08 → patch BookStack for ES256, implementing in #26"
metadata: 
  node_type: memory
  type: project
  originSessionId: bbf332f2-a3a1-44cf-9478-3ce93c92883c
---

**lucos_worlds** = self-hosted **BookStack** worldbuilding tool for TTRPGs (from lucas42/lucos#248; adopt-BookStack per its ADR-0001). Deployed to avalon 2026-07-07: infra-healthy (worlds.l42.eu, DB, `/status`, monitoring all green), branding + fantasy CSS theme shipped, **27/27 lucos_repos conventions clean**, and `worlds:admin` scope is live in aithne's vocabulary.

**BLOCKER — nobody can log in.** BookStack's OIDC hardcodes RS256/RSA-only key acceptance (in two code paths + the manual-key path; unchanged on BookStack's dev branch; upstream ES256 request unresolved). lucos_aithne signs ID tokens **ES256-only** by deliberate design — lucos_locations relies on it. So BookStack rejects 100% of aithne's keys → login 500 → "An unknown error occurred". `AUTH_METHOD=oidc` has no fallback. Tracked on **lucas42/lucos_worlds#21** (full architect + security assessment posted there).

**DECISION (lucas42, 2026-07-08): Option 1 — patch BookStack's vendored OIDC for ES256** (3 files, ~40 lines via bundled `phpseclib3` EC), delivered through the wrapper; aithne stays ES256-only. Implementing in **lucas42/lucos_worlds#26** (Ready, sysadmin, High), with a mandatory **lucos-security diff review**. **lucas42's load-bearing requirement: integration tests are the sole defence** — an end-to-end ES256-login test wired to gate Dependabot BookStack-version-bump auto-merge (pass→merge, fail→block), because internal-code patches can break on version bumps with no release-note warning (even a filename rename). **ADR-0002 commissioned** to architect. Scope: chosen only because BookStack is the sole non-ES256 estate tool — **not a precedent**; revisit aithne multi-alg if the estate diversifies.
Rejected alternatives: aithne-emits-RS256 (shared public JWKS can't be scoped; single-alg is defence-in-depth — security recalibrated it's NOT a live vuln today since all 11 consumers hardcode ES256-only, just a free safety net for future integrations); re-signing shim (more owned code than the patch); tool-switch (unverified ES256-native alternative — architect wouldn't assume one).

**Stopgap available** (offered, not applied): flip `AUTH_METHOD=standard` + seed a local BookStack admin → password login restored immediately, independent of the fix; revert to oidc after.

**Paused behind #21:** RBAC #17 (map aithne scopes→BookStack roles). `lucos_auth_scopes#26` (worlds:admin scope) merged + live; `lucos_worlds#19` (BookStack OIDC group-sync config) is a paused draft.

**Durable estate fact:** aithne is **ES256-only** — any adopted OIDC relying-party must support ES256. Verify signing-algorithm interop at adopt-evaluation time, not just "has OIDC" (the BookStack ADR-0001 premise cracked precisely because compatibility was checked at the feature level, not the signing-alg level). Also parked: [[reference_lucos_creds_key_rotation]]-adjacent — lucos_creds#439 (its lucos_auth_scopes pin is stale at 1.1.0; Low, architect, non-blocking).
