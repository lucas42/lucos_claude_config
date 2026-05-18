---
name: question-the-option-list
description: When a triage brief delivers a question alongside a pre-enumerated (a)/(b)/(c)/(d) option list, treat the list as one possible carve-up — re-read the underlying question for hidden assumptions before reasoning within the frame.
metadata:
  type: feedback
---

When the coordinator (or any teammate) relays a question alongside a list of pre-enumerated options ("options I see: (a)…, (b)…, (c)…"), do **not** structure my analysis around weighing those options. Re-read the underlying question first — verbatim if possible — and look for hidden assumptions in the option set before reasoning inside it.

**Why:** On 2026-05-18, the coordinator forwarded lucas42's questions on `lucos_media_metadata_api#237` and `#240` alongside lists of (a)/(b)/(c)/(d) candidate answers. I structured both my comments around those options — went down each, rejected three, picked one. The coordinator later corrected themselves: lucas42 deliberately keeps these questions problem-oriented to keep agent thinking open, and the option list biased me toward "pick a default" when the actual question wanted a structural rethink.

When I re-read the verbatim questions and the actual code, I landed on materially different proposals in both cases:

- **#237** ("how to tell whether a given artist name is a Person or a Group?"): the option list pushed me toward "source-supplied hint + predicate-aware fallback default", trading off between defaults. Re-reading the question and `lucos_media_import/src/logic.py`, the cleaner answer was "don't decide at import time" — defer URI resolution to a background enrichment process; the import stays name-only, as it already is.
- **#240** ("what's the plan for the mandatory `creative_work_type` field for migration-created CreativeWorks?"): the option list pushed me toward "predicate-aware heuristic default" ("TV series" for theme_tune, "Film" for soundtrack). Re-reading the question and noticing `CreativeWorkType` is itself an `EolasModel`, the cleaner answer was "the migration takes the CreativeWorkType IDs as input — lucas42 pre-creates the types however he likes". No defaults at all.

**How to apply:**

1. When a teammate relays a question alongside an option list, mentally separate the verbatim question from the list. The list is the teammate's hypothesis about the answer-space, not the answer-space itself.
2. Ask: what assumption does the option list embed? Each option usually shares one or more hidden premises — if all options say "the import decides", the premise is "the import must decide". That premise is the thing worth challenging.
3. Read the actual code path before recommending. The right answer to a "how should X behave?" question often becomes obvious once you know how X behaves today. In both #237 and #240 the cleanest answers fell out of looking at existing code I hadn't read.
4. If I find myself going (a) reject, (b) reject, (c) accept, (d) reject — pause. That pattern is the smoking gun for option-list anchoring. Recommendations should land *in spite of* the option structure, not *within* it.
5. Acknowledge the option list briefly to confirm I read it, then state the proposal in its own terms.

Related: [[feedback_apply_frame_review_to_own_reasoning]] — same shape of bias (anchoring on someone else's frame); difference is that there the anchor was a teammate's reasoning summary, here it's an explicit option enumeration. The fix is the same: verify the framing against ground truth before reasoning within it.
