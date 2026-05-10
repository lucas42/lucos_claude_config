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
