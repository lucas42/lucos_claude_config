---
name: aithne-migration-guide
description: lucos_aithne consumer-migration guide (#159) and the three decisions gating it
metadata:
  type: project
---

The aithne consumer-migration guide is **`docs/consumer-migration-guide.md`, proposed in lucas42/lucos_aithne#159 — NOT yet written** (no branch/PR/file as of 2026-06-18). I own authoring it as a single PR once its gating decisions land. See [[machine-principal-sessions]] for the aithne auth design.

**Why:** the guide's content depends on three "Awaiting Decision" tickets; opening it before they settle guarantees rework.

**How to apply:** don't claim a migration-guide PR is "open/held as a PR" — it's held = unwritten. The three gating decisions:
- **lucas42/lucos_arachne#657** — ✅ DECIDED (lucas42) **Option 1**: per-service access-denied page. Three-branch auth middleware (proceed / consumer's own styled 403 via its error view / login-redirect). **No** shared aithne request-access endpoint. Non-negotiable: stop redirecting wrong-scope→login, return 403. Captured on #159.
- **lucas42/lucos_aithne#147** — ⏳ human session continuity (15-min token TTL). Refined into two axes: session-continuity (recommend long-lived IdP session) + POST-data preservation (silent refresh-before-submit / stash-and-replay / draft autosave). **Key insight: IdP session makes re-auth silent but does NOT save a POST body across a top-level redirect — two separate problems.** Couples to #148 cookie model. Best as an ADR-0001 supplement.
- **lucas42/lucos_aithne#148** — ✅ DECIDED (2026-06-17), both parts. Part 1: consumers inject `AITHNE_ORIGIN` env var (not hardcoded `https://aithne.l42.eu`); doc in local-verification-contract.md. Part 2 (lucas42 +1): dev consumers verify against **dev aithne instance**, not prod (cookie scoping). Affects whether client-side silent-refresh (#147 option A) is possible (SameSite/Secure/Domain cookie scoping). Captured on #159.

Related doc tickets on aithne: #156–#159 (local-verification-contract.md gaps + the migration checklist).
