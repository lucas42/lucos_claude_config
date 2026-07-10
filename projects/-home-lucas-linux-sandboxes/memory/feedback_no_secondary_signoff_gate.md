---
name: feedback_no_secondary_signoff_gate
description: "Don't manufacture a redundant lucas42 sign-off gate for shippable work — not via Awaiting Decision, not via a draft PR held for his input; /next is his sign-off, and reversible doc/config updates just ship"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bf92cb1d-5f9a-4e81-890d-6f1b60ae08bc
---

Do NOT park a fully-specified, fully-implementable ticket in **Awaiting Decision** just because the work is a one-way door (decommission, teardown, data deletion). Irreversibility alone is not grounds for the column. If the only open question is "shall we proceed," it's **Ready**.

**Why:** `/next` and `/dispatch` ARE lucas42's explicit sign-off. Gating dispatch behind Awaiting Decision adds a redundant *second* approval for the same act, and inflates his decision queue. He flagged this directly on lucas42/lucos_authentication#143 (2026-06-29): "The `/next` skill is my explicit sign-off. Please don't misuse another mechanism in our workflow to add a secondary sign-off for the same thing." The "sign-off on a one-way-door" phrasing in the persona Status table had been too broad and led to the misuse.

**How to apply:** Awaiting Decision is only for a genuine decision/input lucas42 must provide that agents cannot — which option, whether to build a new system, product direction, a question only he can answer. For a one-way door, use it only when the decision *itself* (whether/how) is still genuinely his to make and isn't already settled. The irreversibility safety belongs at **execution time** as the implementing agent's confirm-first step, not as a board-status latch. Fixed in `agents/coordinator-persona.md` Status-table "Awaiting Decision" row. Related: [[feedback_dont_shift_work_to_coordinator]], [[feedback_ticket_decisions_async]].

**Same principle, second mechanism — draft PRs.** Don't hold a **low-stakes reversible doc/config update** (e.g. `docs/priorities.md`) as a *draft PR gated on lucas42's input*, and don't route it as a strategic-sign-off decision, even when it carries a small judgment call (e.g. what the new #1 priority is) or lands on an unsupervised repo that would otherwise auto-merge. Make the reasonable call, ship it through the normal review→merge flow, and let him adjust after with a quick follow-up if he disagrees — reversibility makes post-hoc tweaks cheap, so the draft-gate ceremony isn't worth it. **Why:** 2026-07-10, lucos#252 (a priorities.md refresh) was routed as a gated decision and the architect opened a *draft* PR (lucos#269) waiting on lucas42. He pushed back: "Updating the priorities doesn't warrant a pull request, especially not a draft one waiting my input." Applies to implementers (draft-vs-ready choice) as much as to coordinator routing.
