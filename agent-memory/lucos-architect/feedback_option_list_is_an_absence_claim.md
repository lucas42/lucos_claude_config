---
name: option-list-is-an-absence-claim
description: An enumerated option list presented to a decision-maker asserts that no other option exists — check for the third path before presenting or accepting one
metadata:
  type: feedback
---

**A list of options put to a decision-maker is an absence claim in disguise: "A or B" asserts "not C".** Treat it with the same scepticism as any other claim that closes off an option — before presenting an option list, or accepting one presented to you, ask what a *decision-neutral* path would look like.

**Why:** an option list reads as *complete*, so a missing option is never questioned — unlike a stated impossibility, which at least invites a challenge. A bad option list offered to a decision-maker is worse than none. (2026-08-26, lucas42/lucos_backups#403: the coordinator put "ship the fix early and settle Decision B by building it" vs "stay red until lucas42 decides" to lucas42. Both were real, and the pair was not exhaustive — a one-line Pipfile rename cleared the failing check while deciding nothing, which is what got filed as lucas42/lucos_backups#404. The framing was propagated to lucas42 before it was caught.)

**How to apply:** the tell is a binary whose two arms are "act now and pre-empt the decision" vs "wait for the decision". That shape almost always has a third arm — the subset of the work that is *neutral* about what is being decided. Separate the parts of a fix that settle the open question from the parts that don't; the latter can usually ship immediately.

Two corollaries worth keeping:
- **Rejecting an option "as the fix" does not reject it as a stopgap.** An objection of the form "this makes correctness rest on a property nothing asserts" is an argument against building permanent architecture on it, not against using it while the permanent question is open. Say so explicitly in the ticket, or the stopgap gets cited later as precedent against your own position.
- **Removing time pressure is a real argument, distinct from the cost of delay.** A decision taken while something is on fire is a worse decision. But do not let that collapse into "this unblocks the decision" — the conditions improve, the readiness does not, and conflating them makes the open ticket look like it was waiting on something other than the decision-maker.

Relates to [[verify-path-before-defensive-code]] and the Self-Verification rule on absence claims that *close* a risk.
