---
name: When a mechanism is "replaced", check both sides before reasoning about safety
description: Removing X and adding Y to do X's job means safety claims about X depend on Y's behaviour — check Y, not just the absence of X
type: feedback
---

When you discover that one mechanism has been removed (e.g. "Fuseki inference was removed"), do NOT conclude that operations which were previously gated by that mechanism are now safe. The mechanism was likely *replaced* by something equivalent in another layer. Always find the replacement and read its logic before pivoting any safety claim.

**Why:** lucos_arachne#452, 2026-05-10. I checked `triplestore/configuration/arachne.ttl`, saw the assembler had no reasoner, and pivoted my recommendation to allow `owl:inverseOf` declarations. But the inference logic had moved to the ingestor — `compute_inferences()` in `ingestor/triplestore.py` walks `owl:inverseOf` and materialises full reverse triples into `urn:lucos:inferred`, which is visible to every query via `unionDefaultGraph`. My pivot would have caused the exact bloat I'd originally warned against. lucas42 caught it: "I'm worried you're making decisions here without understanding the full picture."

**How to apply:**
- When a doc/comment/memory says "X was removed/replaced", treat it as a half-fact. Find what replaced it. Read that code.
- For any inference-style mechanism (RDFS reasoner, OWL reasoner, schema-driven materialiser, build-time codegen): the reasoning rules don't disappear when the runtime moves; they get reimplemented in the new layer. Verify by reading the new layer's source, not by checking that the old layer is gone.
- If you can't find the replacement, that's evidence the migration is incomplete — say so rather than assume the operation is now unconstrained.
- This generalises beyond inference: caches, queues, retry logic, auth middleware — anything described as "replaced" needs the *replacement* checked, not just the absence of the original.
- **Same shape applies to a value with multiple read sites.** When something feeds a field that is consumed in more than one place, enumerate *every* consumer before endorsing a "no change to the engine" claim — an analysis that addresses the obvious consumer can silently miss a second one.

**Second instance:** lucos_monitoring#272, 2026-06-03. SRE proposed stamping `dependsOn:[router,dns]` onto synthetic probes and verified it against `is_dependency_suppressed/3` ("no change to the suppression engine"). Correct — for that read site. But ADR-0002 names *two* `dependsOn` read sites, and the second (`find_dependent_systems/2`, the unsuppress cascade) now fans `pending_verification` to the whole estate on every router/dns deploy. The ADR itself listed both sites; reading the ADR's own Context paragraph surfaced the missed one. Lesson: when a field's behaviour is governed by an ADR, re-read the ADR's enumeration of where the field is *read*, not just where it's written.
