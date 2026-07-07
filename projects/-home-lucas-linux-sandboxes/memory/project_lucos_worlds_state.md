---
name: project_lucos_worlds_state
description: "lucos_worlds (BookStack worldbuilding) deployed 2026-07-07 but login-blocked on a BookStack-RS256 vs aithne-ES256 incompatibility (#21); lucas42 deciding the fix 2026-07-08 morning"
metadata: 
  node_type: memory
  type: project
  originSessionId: bbf332f2-a3a1-44cf-9478-3ce93c92883c
---

**lucos_worlds** = self-hosted **BookStack** worldbuilding tool for TTRPGs (from lucas42/lucos#248; adopt-BookStack per its ADR-0001). Deployed to avalon 2026-07-07: infra-healthy (worlds.l42.eu, DB, `/status`, monitoring all green), branding + fantasy CSS theme shipped, **27/27 lucos_repos conventions clean**, and `worlds:admin` scope is live in aithne's vocabulary.

**BLOCKER — nobody can log in.** BookStack's OIDC hardcodes RS256/RSA-only key acceptance (in two code paths + the manual-key path; unchanged on BookStack's dev branch; upstream ES256 request unresolved). lucos_aithne signs ID tokens **ES256-only** by deliberate design — lucos_locations relies on it. So BookStack rejects 100% of aithne's keys → login 500 → "An unknown error occurred". `AUTH_METHOD=oidc` has no fallback. Tracked on **lucas42/lucos_worlds#21** (full architect + security assessment posted there).

**Fix options (lucas42 deciding 2026-07-08 morning):**
- **Option 1 (architect-recommended): patch BookStack's vendored OIDC for ES256** via the wrapper/`custom-cont-init` layer we own — ~2 files (relax 2 RS256 gates + add an EC branch using BookStack's already-bundled `phpseclib3`). It's signature-verification code → needs a **lucos-security review of the diff** + re-verify on every BookStack upgrade. Contains the compromise in the low-criticality leaf.
- **Rejected: aithne emits RS256** — any RSA key in the shared public JWKS makes an RFC 8725 algorithm-confusion precondition true estate-wide; can't be scoped per-client (JWKS is one public endpoint). Wrong blast radius. Security concurs.
- **Re-signing shim** (small service in front of BookStack with its own key endpoint) = the only genuinely-scoped-RSA path; a bigger build → fallback.
- **Reconsider the tool** (ES256-native: self-build / Outline / Wiki.js) — only if owning a fork/shim is unacceptable; not recommended for a live single-user deploy.

**Stopgap available** (offered, not applied): flip `AUTH_METHOD=standard` + seed a local BookStack admin → password login restored immediately, independent of the fix; revert to oidc after.

**Paused behind #21:** RBAC #17 (map aithne scopes→BookStack roles). `lucos_auth_scopes#26` (worlds:admin scope) merged + live; `lucos_worlds#19` (BookStack OIDC group-sync config) is a paused draft.

**Durable estate fact:** aithne is **ES256-only** — any adopted OIDC relying-party must support ES256. Verify signing-algorithm interop at adopt-evaluation time, not just "has OIDC" (the BookStack ADR-0001 premise cracked precisely because compatibility was checked at the feature level, not the signing-alg level). Also parked: [[reference_lucos_creds_key_rotation]]-adjacent — lucos_creds#439 (its lucos_auth_scopes pin is stale at 1.1.0; Low, architect, non-blocking).
