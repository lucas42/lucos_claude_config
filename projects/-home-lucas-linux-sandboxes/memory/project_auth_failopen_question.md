---
name: Auth fail-open/fail-closed question RESOLVED — fail closed
description: Resolved 2026-06-30 — post-aithne-migration security review confirmed all consumers FAIL CLOSED on auth failure (correct); the JWKS serve-stale gap is the residual reliability concern
type: project
originSessionId: 9777c034-07fc-4b8e-9216-8d1573f7ea53
---
**RESOLVED 2026-06-30** by the lucos-security review during the lucos_authentication → lucos_aithne post-migration review.

**Answer: FAIL CLOSED (correct security behaviour).** Every migrated consumer returns 401 / redirects to aithne login on auth failure; a missing or invalid token never grants access. The 5-minute JWKS cache gives ~5 min resilience during an aithne outage, but once the cache expires AND aithne is unreachable, consumers fail closed (a 401 storm) — i.e. *more* closed than the local-verification contract intends, never fail-open.

**Residual concern (not fail-open):** the JWKS **serve-last-known-good / serve-stale** gap — most consumers use off-the-shelf `createRemoteJWKSet` (jose) / `PyJWKClient` which raise on a failed refresh instead of serving the last-known-good key set. Tracked by lucas42/lucos_aithne#241 (security, umbrella), lucas42/lucos_arachne#697 (architect — /mcp HIGH, /explore MED), and lucas42/lucos#255 (architect — the 4 JS consumers, may suit an estate-rollout). `lucos_contacts` already has the correct pattern (`_LKGJWKSClient`) — the reference for the others to copy.

**How to apply:** The original fail-open/fail-closed question is closed — don't re-raise it. If auth-resilience work comes up, the live item is the serve-stale gap above, not fail-open.
