---
name: feedback-ready-no-deferred-design-choices
description: "Status = Ready requires meaningful design/approach/UX/mechanism choices to be settled AT TRIAGE, not punted to the implementer. The tell: you wrote the open fork into the triage comment."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9fcb4312-35a3-44cc-8036-71222379b5bc
---

Status = Ready means *no meaningful design choices left to the implementer* — the decision is made at triage, not deferred to implementation. Latitude over pure mechanics (variable names, which file/line, refactor shape) is fine; behaviour / approach / UX / mechanism choices are not.

**The tell:** if your own triage comment contains "implementer should pick/decide", "within the implementer's remit", "left to implementation", "the developer can resolve" — you have named an unresolved fork, and that fork IS the triage-time decision you're skipping. Naming it = it must be resolved before Ready.

**How to apply:** settle the choice now — decide it yourself if it's a coordinator-level call, or consult the owning agent inline (Needs Analysis + Owner + SendMessage, wait for their proposal, bake it into the body), and only THEN set Ready.

**Why:** 2026-06-14, during `/routine` triage, marked `lucos_media_metadata_manager#334` (artist search — punted result ranking/presentation) and `lucos_creds#385` (Android icon — punted "pick a rendering approach") as Ready while writing the open choice into the triage comment. lucas42 corrected: "didn't we decide that decisions like those should be done at triage time, rather than implementation?" Re-triaged both to Needs Analysis + routed for the design decision; added a self-catching CHECKPOINT to the coordinator persona's Ready definition (commit db4b8ce).

Distinct facet from [[feedback-ready-means-fully-implementable]] (that one is about dependency/dormant-code → Blocked-vs-Ready; this one is about design choices → Needs-Analysis-vs-Ready). See [[feedback-correct-agents]] for the correction sequence.
