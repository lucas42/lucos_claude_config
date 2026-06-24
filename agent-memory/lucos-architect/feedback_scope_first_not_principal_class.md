---
name: scope-first-not-principal-class
description: lucas42 — authorise on scopes, not principal_class; and don't accrete ADR complexity through review rounds
metadata:
  type: feedback
---

Two pieces of feedback from lucas42 on the lucos_eolas ADR-0002 amendment (PR #322, 2026-06-24):

**1. Authorisation is SCOPE-FIRST. Do not differentiate access on `principal_class`.**
Decide what a principal may do **first-and-foremost on its granted scopes**, the same test for every principal (human or agent). `principal_class` is relevant **only** for matching a logged-in user to a contact (e.g. attaching the human's name to the lucos_contacts navbar) — never as an access gate.
- **Why:** consistent with `lucos_aithne` ADR-0001 §6 (capability comes from a granted, named scope, not identity/class). Default-deny + grant discipline is the protection against an agent reaching a human surface — "don't grant an agent a human-UI scope" is a grant-layer decision, not a per-consumer class check.
- **What I got wrong:** I built an elaborate `principal_class`-based access model (agents → `AnonymousUser`, an `is_authenticated`-first gate, "two-barrier defense-in-depth", env-aware mapping, a method-check exposition). lucas42: "I don't understand why we seem to be differentiating so fundamentally on principal_class." The whole edifice collapsed to: `@require_scope` checks the scope; `is_staff` follows the admin scope; `map_principal` uses class only to attach identity.
- **How to apply:** for any consumer-auth/authz design, gate on scopes by default; reach for principal/identity only for display/ownership ("is this YOUR record"), never for service access. If you find yourself special-casing agent-vs-human for *access*, stop — that's an authZ-via-scope job. Note the contrast with [[reference_aithne_agent_principal_model]] / arachne #637 which gated `/mcp` on `principal_class=="agent"` alone — lucas42 flagged that too as a §6 violation; same root lesson.

**2. Don't accrete complexity through review rounds. When the approach gets simpler, the text should get shorter.**
- lucas42: "every time you've received feedback on this PR, you've made the text more complicated, even when the approach becomes simpler. Let's try to keep any additions here concise, and don't go off mentioning things which aren't relevant."
- **What happened:** across ~5 review rounds I kept *adding* paragraphs (Bearer disambiguation, cold-start, two-barriers, future-suggestions, method-check-location). The scope-first rewrite cut ~90 lines net and was clearer.
- **How to apply:** when addressing review feedback on an ADR/design doc, default to *replacing/trimming*, not appending. If a round simplifies the approach, the doc must shrink. Don't add notes about not-yet-built/irrelevant future features. Watch the net line count — each revision should aim flat-or-shorter. (Mirrors the global CLAUDE.md "consolidate over additive growth" rule for instruction files — same instinct for ADRs.)
