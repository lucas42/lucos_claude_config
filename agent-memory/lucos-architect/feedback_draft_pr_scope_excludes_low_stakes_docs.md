---
name: draft-pr-scope-excludes-low-stakes-docs
description: The draft-PR + lucas42-sign-off convention is for cross-system contracts, NOT low-stakes reversible doc/config updates
metadata:
  type: feedback
---

The "ship design-decision docs as a draft PR gated on lucas42's sign-off" convention applies to documents that **lock a cross-system contract / binding that then propagates** (ADRs, integration-pattern guidance, schemas, auth contracts). It does **not** apply to **low-stakes, easily-reversible internal doc/config updates** — `priorities.md`, internal notes, config tweaks. For those, make a reasonable call and ship through the **normal** code-reviewer→merge flow; don't open a draft and park it on lucas42's queue.

**Why:** on PR lucas42/lucos#269 (priorities.md update, 2026-07-10) lucas42 said: "Updating the priorities doesn't warrant a pull request, especially not a draft one waiting my input." Draft-gating a trivially-reversible doc wrongly holds a change hostage to his sign-off and clutters his review queue. He reviews the substance if he wants; the change shouldn't *wait* on him.

**How to apply:** before opening a design/decision doc as a draft, ask — does this establish or change a **cross-system contract** that other systems/agents will build on before he could catch it post-merge? If yes → draft + @lucas42 ping (the propagation is the risk the draft guards). If it's an internal, reversible prioritisation/guidance/config doc → normal flow, ship it, let review catch issues. The tell for "normal flow": a wrong version is trivially reverted and nothing downstream hard-commits to it in the meantime.

Related: [[feedback_flag_human_approval_staleness_at_push_time]]
