---
name: aithne-migration-guide
description: lucos_aithne consumer-migration guide (#159) and the three decisions gating it
metadata:
  type: project
---

The aithne consumer-migration guide (`docs/consumer-migration-guide.md`, #159) + **ADR-0003** (human session continuity, supplements ADR-0001 §3) are **WRITTEN as draft PR lucas42/lucos_aithne#182** (2026-06-18, awaiting lucas42 sign-off; unsupervised → draft + ping). All three gating decisions now settled + folded. Deferred impl raised: **aithne#181** (IdP session + silent re-mint endpoint) + **lucos_navbar#174** (navbar keepalive + multi-tab coord; Blocked on #181). See [[machine-principal-sessions]] for the aithne auth design.

**How to apply:** PR #182 closes #147+#159 on merge. The three (now-settled) gating decisions, for reference:
- **lucas42/lucos_arachne#657** — ✅ DECIDED (lucas42) **Option 1**: per-service access-denied page. Three-branch auth middleware (proceed / consumer's own styled 403 via its error view / login-redirect). **No** shared aithne request-access endpoint. Non-negotiable: stop redirecting wrong-scope→login, return 403. Captured on #159.
- **lucas42/lucos_aithne#147** — ⏳ human session continuity (15-min token TTL). lucas42 REJECTED per-form approaches (Axis 2: silent-refresh-before-submit/stash-replay/draft-autosave) — wants central-only or he'll lengthen sessions to hours/days. **My central counter (recommended): session-keepalive in the SHARED NAVBAR** (`lucos_navbar.js`, verified loaded estate-wide via import/script-include) — background timer + focus handler silently re-mints the short `aithne_session` via a new aithne re-mint endpoint backed by a long-lived IdP session; while a tab is open the token never expires mid-form → no redirect, no lost POST, ZERO per-form changes (only the navbar bumps). Optional 1 global `submit` listener in navbar closes wake-from-sleep race. **Security reconciliation: longer STATELESS token = hours/days revocation lag** (consumers verify JWT locally via JWKS, scopes baked at mint) — real regression on crown-jewel; longer sessions safe only if revocable, and clean revocable design IS IdP-session+short-token+keepalive (paths converge). Needs 2 new central aithne capabilities + navbar change + #148 cookie/CORS. Best as ADR-0001 supplement. Awaiting lucas42 pick: keepalive vs longer-sessions.
- **lucas42/lucos_aithne#148** — ✅ DECIDED (2026-06-17), both parts. Part 1: consumers inject `AITHNE_ORIGIN` env var (not hardcoded `https://aithne.l42.eu`); doc in local-verification-contract.md. Part 2 (lucas42 +1): dev consumers verify against **dev aithne instance**, not prod (cookie scoping). Affects whether client-side silent-refresh (#147 option A) is possible (SameSite/Secure/Domain cookie scoping). Captured on #159.

Related doc tickets on aithne: #156–#159 (local-verification-contract.md gaps + the migration checklist).
