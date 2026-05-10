---
name: When relaying an agent plan, ask about the plan first
description: AskUserQuestion on a multi-part agent plan must lead with the plan-level question, not just the niche details the agent flagged
type: feedback
originSessionId: 4595a1b0-a470-4c5f-8870-6b813937dcbd
---
When relaying a multi-section agent plan to the user (architecture proposal, ticket structure, migration design, etc.), the AskUserQuestion call must lead with the **plan-level question** — "do you agree with this overall shape?" — *before* asking about any niche details the agent flagged at the end.

**Why:** Niche-detail questions (ADR location, sweep timing, etc.) only matter if the plan's shape is agreed. Asking only the niche details implicitly signals that the plan itself is settled, leaving the user no clean way to push back on sequencing, scope, or approach without rewinding. (Lesson from 2026-05-11: architect proposed a 3-phase dual-emit migration for `mmm:` URIs and ended with three sign-off questions — stop-gap, ADR location, cross-estate sweep. I relayed verbatim, asked all three, but didn't ask about the plan itself. lucas42 wanted a 2-phase no-dual-emit version and had to interrupt to redirect.)

**How to apply:** Before composing the AskUserQuestion, look at the agent's reply and separate plan-shape decisions from leaf details. Always include at least one plan-shape question — even if the agent didn't explicitly ask one — phrased as "approve as described" / "approve with changes" / "different approach". Treat the agent's "ready for sign-off on (a)/(b)/(c)" framing as advisory: the agent only surfaces decisions they think are open, but the user may disagree with parts the agent thought were settled. Leaf-detail questions can follow in the same call when there's a slot, or be saved for after the plan is approved.

Within the AskUserQuestion's 4-question limit, prioritise: (1) plan-shape, (2) the most consequential leaf detail, (3) further leaf details only if there's room. If you can't fit the plan-shape question alongside the leaves, drop the lowest-impact leaf rather than the plan-shape.
