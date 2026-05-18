---
name: feedback-dont-shift-work-to-coordinator
description: "Don't add workflow rules that shift work from GitHub automation onto the coordinator without lucas42 asking for it; default to trusting existing automation + brief transient inconsistencies"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 95dd3212-10dc-4f8f-9047-e18d6d22e7d3
---

When I see a workflow producing a transient inconsistency or a minor edge case, my default reaction should NOT be to add a rule that requires coordinator intervention to clean it up. Trust the automation. A brief inconsistency that resolves itself in minutes (e.g. an issue auto-closing on the first PR merge before the paired PR lands) is fine — it doesn't need a coordinator-side workaround.

**Why:** Lucas42 explicitly doesn't want the coordinator manually closing issues after PR merges; he prefers GitHub's `Closes` automation to handle it, even at the cost of short-term inconsistency when multi-PR issues land out of expected order. When I observed a premature auto-close on a multi-PR issue and proposed switching to `Refs`-everywhere with coordinator-side manual close, he pushed back: the developer's `Closes`-on-one-PR was fine; the brief gap was acceptable; the proposed workflow change moved work onto the coordinator without being asked.

**How to apply:**

1. **When a workflow edge case produces transient inconsistency, ask: does it actually need fixing?** If it self-resolves within minutes once the dependent action lands, leave it alone.
2. **When considering a workflow rule that requires coordinator manual action where GitHub automation could do it instead, default to NOT adding the rule.** Especially: don't add rules that say "the coordinator will manually X" or "the coordinator will close Y after Z" — those shift the work onto the coordinator and into the user's chat surface area.
3. **If the inconsistency is genuinely problematic, ASK first** before adding the rule. The user may prefer to live with the inconsistency, fix it at a different layer, or accept it as the cost of an automated system that mostly works.

Same pattern in [[feedback-priority-pickup-are-coordinator]] (priority/pick-up timing are coordinator-side calls, NOT Awaiting Decision items) — both about not creating workflow paths through the coordinator when automation or my own judgment would do.
