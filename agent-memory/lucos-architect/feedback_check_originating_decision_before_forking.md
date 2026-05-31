---
name: Check the originating decision ticket before presenting a design fork
description: Before framing an observation as a "new problem" with an A/B fork, read the ticket that settled the original design — the observed state may be the designed-for state with an unfinished implementation half, and a proposed option may silently re-open a deliberately-rejected approach
type: feedback
---

Before presenting a design fork (or recommending an option within one), **read the ticket(s) that settled the original design in full** and test each option against what was deliberately decided there.

**Why:** On `lucos_arachne#597` (2026-05-31) I framed an artist↔person "divergence" as a present data-quality bug needing an A/B design decision, and recommended **Option B** (media resolves artist-people to eolas Person URIs, mints `mo:MusicArtist` only for bands). lucas42 pushed back: (1) wasn't this settled in `lucos_media_metadata_api#246`? and (2) doesn't Option B re-open the person-vs-group-at-ingest question? He was right on both. Re-reading #246/#237 showed:
- The two-node state (media `mo:MusicArtist` + eolas `foaf:Person`, linked by manual `owl:sameAs`) was **#246's deliberate design**, not a bug. The "divergence" was simply that the federation half (`owl:sameAs` storage/emission in media_api + arachne honouring it) **was never implemented** — PR #281 shipped only the modelling half. So it was an *unfinished implementation of a settled design*, not a new problem.
- **Option B silently re-opened the exact decision #237/#246 designed out:** to route people→eolas and bands→media URIs, media would have to classify person-vs-group at ingest. The whole point of `mo:MusicArtist` was "covers individuals and groups uniformly — no Person-vs-Group decision at ingest." An option that contradicts a deliberately-settled decision is **not a valid option**.

**How to apply:**
- When a ticket presents an observation as a "new problem" or a fresh A/B fork, first ask: *was this decided before?* Pull the originating decision ticket and read its decision + rationale before reasoning about options. The observed bad state is often the expected state of a design whose implementation is half-done — in which case the fix is "finish what was decided," not "decide again."
- For each option in a fork, check it doesn't reintroduce an approach the originating ticket explicitly rejected (here: ingest-time person-vs-group classification). If it does, strike it before presenting — don't recommend it and make the user catch it.
- Distinguish *the decision wasn't implemented* (finish it) from *a new requirement surfaced the decision didn't cover* (genuinely re-open). Most "divergence" findings are the former.
- Verify the implementation gap in code before asserting it (here: artist table `(id,name)` only; `ArtistToRdf` emits no `sameAs`; arachne `#539` closure gates both ends on `foaf:Person`). See [[feedback_implementation_surface_code_trace]].
- Related: [[feedback_check_adr_before_advising]], [[feedback_question_the_option_list]], [[feedback_apply_frame_review_to_own_reasoning]].
