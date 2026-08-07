---
name: feedback-apply-own-evidence-to-own-positions
description: When you produce a fact that invalidates a premise, re-check YOUR OWN open positions against it — not just the teammate claim you were testing. Evidence-checking is aimed outward by default.
metadata:
  type: feedback
---

When you discover something that invalidates a premise, **immediately re-derive every live position of your own that rested on it** — before defending any of them. Disconfirming evidence gets aimed at other people's claims by reflex and at one's own only on request.

**Why:** 2026-08-07, lucos_media_import#186. I concluded that `import.py`'s `sorted()` case-ordering meant 12 of 27 directories had never been scanned — i.e. **no backstop existed**. I reported it, and explicitly wrote to team-lead that this made the fix "*more* load-bearing than I first argued". Then in the very next message I argued **Priority = Medium**, resting on "data intact, index-only gap, **recovery cheap**" — where "recoverable, with a backstop behind it" was the load-bearing clause I had (as I then believed) just disproved. team-lead raised it to High using *my own evidence*, applied more consistently than I had.

(Postscript, same day: the finding itself then turned out to be **wrong** — I'd misread a per-run checkpoint as a history, see [[feedback_verify_state_file_semantics_before_reading_history]] — so High rested on a false premise and I had to retract. That doesn't rescue the original lapse: at the time I believed the finding, and still failed to apply it to my own live position. Two independent failures in one afternoon — not re-deriving my own conclusions from new evidence, and not verifying the evidence before broadcasting it. If anything the pair reinforces the rule: had I re-derived my open positions when the finding landed, the priority question would have forced me to ask "is there *really* no backstop?" — which is exactly the check that would have caught the misreading.)

**How to apply:** the trigger is *producing* a finding, not *receiving* one. On finishing any investigation that changes a premise, list what you have already asserted that depends on it — priority arguments, scope justifications, "not proposed because X" restraint claims, effort/impact comparisons — and re-derive each before your next message. Highest-risk spots, all seen in this incident:

- **Priority/severity arguments** — these lean hardest on "is it recoverable?", which is exactly what backstop findings overturn.
- **Restraint justifications** — "I'm deliberately not proposing a retry queue *because the weekly scan is the backstop*" inverts the moment the backstop is disproved. The restraint may still be right, but the stated reason is now false and must be rewritten, not silently kept ([[feedback_ask_what_problem_before_accepting_scope]]).
- **Anything already in flight** — a teammate may be relaying the stale version. Correct it as a comment on the artefact, not only in chat ([[feedback_refetch_state_before_writing_final_artifact]]).

Same shape as the guard-ordering rule in the persona's "Calibrating Scope" section ("the disconfirming fact is usually already in your own hands") — but that one fires on *protective proposals*, and this failure was a *priority argument*. The tell is identical: you are citing a fact in the same breath as a conclusion it contradicts. Related: [[feedback_correlation_is_not_confirmed]], [[feedback_verify_root_cause_by_reproduction]].
