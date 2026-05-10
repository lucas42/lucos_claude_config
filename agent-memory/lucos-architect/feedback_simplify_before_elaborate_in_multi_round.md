---
name: In multi-round design threads, default to "simplify the proposal" before "elaborate further"
description: After being course-corrected once on a design, the next failure mode is to elaborate the now-revised design rather than question whether the original frame was too complex
type: feedback
---

When a design conversation has already course-corrected once, the second-correction risk is no longer "did I miss a trap" but "is the whole frame too elaborate". After a course-correction, your default should be to *simplify* the proposal before adding more layers — not to refine the same architectural shape.

**Why:** lucos_arachne#452, 2026-05-10. Across four rounds with lucas42 I ended up proposing successively: (1) ontology change + render section, (2) ontology change with `owl:inverseOf` + render section + label registry, (3) per-predicate label registry. Each round I responded to a specific correction by elaborating the existing frame. lucas42 finally said "I really dislike your idea of a label registry" — at which point the simplest answer (no ontology change, no registry, two SPARQL queries, use forward predicate's prefLabel as inbound section heading) became obvious. It had been available the whole time, but I hadn't questioned the frame because I was still operating within "we need a labelling mechanism".

**How to apply:**
- After any architectural course-correction in a multi-turn thread, before writing your next proposal, ask: "what would the simpler-by-one-layer version look like?" Make that the starting point of the response.
- The self-verification "have you reviewed the proposed approach itself, or only reasoned within it" applies to your *own* in-flight proposal too, not just to other people's framings. Especially after a correction.
- The burden of proof shifts to the more-complex design after every correction. If you can't justify why the elaborate version beats the simple one *cleanly*, ship the simple one.
- Watch for "we need to handle X" propositions that drag in mechanisms (registries, custom predicates, lookups). Most of the time, X reduces to "render the predicate's own label" or some other already-available primitive.
