---
name: feedback-new-consideration-gets-own-adr
description: A new consideration or a reversal gets its own ADR; only additive detail within the original decision's scope is an amendment
metadata:
  type: feedback
---

Before extending an existing ADR, apply the test: does this **clarify or add detail to the
decision that ADR actually made**, or is it a **new consideration** / a **reversal** of it?
Amendments are for the former only. The latter gets its own numbered ADR, plus a
supersession pointer on the superseded section, leaving the original text intact.

**Why:** an ADR records one decision *with the context that existed when it was made*.
Folding later unrelated thinking into it means it can no longer be read as what was decided
then — it degrades into a general wiki page nobody trusts. And rewriting a *reversed*
decision in place erases both that the original choice was made and why it changed, which
is exactly the sanitising-in-hindsight I claim not to do.

**How to apply:** the tell is an **implementation coupling** being mistaken for a
**decision coupling**. If the argument for bundling is "these two share a mechanism", that
mechanism is a *consequence* of both decisions, never a reason to fuse them into one
document. Check whether the original ADR's Context section even contemplated the new topic
— if it didn't, it's a new consideration.

**Where this bit me:** 2026-08-06, `lucos_worlds`. I proposed folding an NPC stat-block
convention into ADR-0001 as an amendment, on the grounds that the stat-block template hangs
off the chapter structure ADR-0001 covers. lucas42: *"Decisions around NPCs shouldn't go
into ADR-0001. That's a completely new consideration, not a clarification of an existing
decision."* Applying the test properly then also changed the *other* half — the
types-as-chapters change was a **reversal** of ADR-0001 §1, so it needed its own ADR too,
not the in-place amendment I'd planned. Correct split: ADR-0004 (reversal) + ADR-0005 (new
consideration), with ADR-0001 gaining pointers only.

Note the precedent that makes the boundary real rather than academic: `lucos_worlds`
ADR-0001 *does* carry a legitimate RBAC amendment — additive detail on the auth decision
that ADR had already made. That one is correct; mine wasn't.

Related: [[project-lucos-worlds]].
