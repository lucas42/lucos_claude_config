---
name: feedback-ask-usage-context-before-ranking-options
description: Establish the operating context (device, role, when the user learns what they need) BEFORE ranking design options — not after presenting a recommendation
metadata:
  type: feedback
---

Before ranking options for a user-facing design, establish **how the person actually uses the system**: what device, what role they occupy, when they find out what they need, and what they have to hand at that moment. Ask it *before* the ranking, not after the recommendation has been delivered.

**Why:** 2026-07-30, lucos_worlds session-bookmarking. I got this wrong twice in one thread, each time confidently:
1. Ranked Favourites first on the strength of two keyboard shortcuts (`favourite`, `favourites_view`). lucas42 uses it on a **split-screen tablet** — no keyboard. The whole basis of the ranking didn't exist in his context.
2. Pivoted to a "Tonight" page prepared in advance. He's a **player**, not the DM — he learns the cast on arrival and brings no laptop. Any advance-preparation design is dead on arrival.

Both recommendations were internally sound and both were answers to a user I'd invented. The eventual answer (Favourites + make the ★ reachable on a narrow viewport) was reachable on turn one had I asked.

**How to apply:** when a request is about *using* something rather than *building* it, the operating context is a load-bearing input, not colour. The tell is a recommendation whose justification rests on an affordance (keyboard shortcut, second screen, prep time, always-on connection) — check that affordance exists in the real usage before ranking on it. One question up front beats two confident reversals.

Note the failure is NOT "didn't ask why" — I understood the problem perfectly. It's narrower and easier to miss: the *problem* was clear, the *context of use* was assumed. Related: [[project-lucos-worlds]].
