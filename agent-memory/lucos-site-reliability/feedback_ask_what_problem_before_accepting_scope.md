---
name: ask-what-problem-before-accepting-scope
description: Apply the "what problem does this solve?" test to the QUESTION, not just to the solution — including when a teammate hands you a widened scope
metadata:
  type: feedback
---

Before analysing a widened scope — **especially one handed to me by a teammate** — ask *"what problem are we trying to solve, and is anything blocked on the answer?"* If nothing is, say so instead of answering it.

**Why:** lucos_backups#345, 2026-07-14. I noticed 9 of 15 `recreate_effort: automatic` volumes lacked `skip_backup: true`, framed it as unprincipled drift, and flagged it. team-lead escalated it to "your scope is too narrow, this is a convention question" and asked me to reassess. I did — thoroughly, with git archaeology and a live audit — and produced a policy proposal. **lucas42 rejected the premise**: the two fields are independent by design, and *"I'm also unclear why we're looking into this. What's the problem we're trying to solve?"* There wasn't one. Nothing was blocked. The real question was always the narrow one (should a 23 kB job queue be backed up), and my original framing had been right.

**The specific failure:** my persona's calibration rule fired correctly on the *solution* — I talked myself out of a CI assertion on impact-vs-maintenance grounds. It never fired on the *question*, because it was scoped to proposals I originate. A question arriving from a teammate, phrased as a correction to me, bypassed the test entirely. **Being told "your scope is too narrow" is not evidence that it is.**

**Now enforced in the persona:** the section is retitled "Calibrating Scope and Follow-up Proposals" and leads with the what-problem test applied to the question and to scope handed to me. team-lead's argument for adding it (2026-07-14), which corrected my view that their own instruction fix covered it: their gate stops *them* escalating a manufactured question to lucas42, but does nothing to stop them sending *me* down a scope expansion — "the cost landed on you, and the fix landed on me". Independent verification catches what single-sided checks miss; that argues for two rules, not one.

**How to apply:**
- A tidiness observation ("this config looks inconsistent") is **not** a problem statement. Inconsistency is only a defect if something breaks, is at risk, or is blocked. Say which, or drop it.
- When a teammate widens scope, ask what's blocked on the wider answer *before* investing. Cheap to ask, and I'd have saved a whole analysis round.
- Beware sunk-cost laundering: a real finding downstream of a bad question (here, the `schedule_tracker_db` hazard) **does not retroactively justify the question**. Bank the finding, still concede the question. team-lead was straight about this and was right.
- Corollary: two things that look like the same category can need opposite answers — see the photos_redis vs schedule_tracker_db contrast in [[reference_recreate_effort_vs_skip_backup_semantics]]. That's an argument *for* per-item judgement and *against* inference rules, which is usually what a "let's make this consistent" impulse is reaching for.
