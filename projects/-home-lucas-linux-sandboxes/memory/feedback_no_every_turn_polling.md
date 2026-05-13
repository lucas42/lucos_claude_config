---
name: feedback-no-every-turn-polling
description: "Don't propose \"re-check X on every user turn\" as an instruction fix — it produces weird inconsistencies"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4baabbd0-6778-4cfa-b190-0f9fb337f4cf
---

When proposing an instruction fix for a gap where state changes between turns (e.g. supervised PR merges happening while idle, dependents not getting unblocked), do NOT suggest "re-fetch the relevant state at the top of every subsequent user turn until X". lucas42 has explicitly rejected this shape (2026-05-13).

**Why:** Every-user-turn polling produces weird inconsistencies — the behaviour now depends on when the user happens to send any unrelated message, which is non-deterministic from the user's perspective and creates surprising effects (a "what's the weather" message could trigger a re-check + automated dispatch). The mental model becomes confusing because actions stop being caused by the thing they appear to be caused by.

**How to apply:**
- If the natural fix for a gap is "poll on every turn", consider whether to leave the gap unfixed rather than introducing per-turn polling.
- Alternative fix shapes that may be acceptable: explicit trigger (the user asks "what's the status?"), turn-scoped (only when the user's message references the relevant artifact), or a real notification mechanism (not a polling proxy).
- Specifically: do NOT add "on every user turn" or "at the start of every response" clauses to dispatch/coordinator instructions.
