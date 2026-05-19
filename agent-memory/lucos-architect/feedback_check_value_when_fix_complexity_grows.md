---
name: check-value-when-fix-complexity-grows
description: When a proposed fix accumulates new types, new components, new follow-up tickets, pause and re-ask "what concrete functionality breaks without this?" — don't let solution refinement push the original problem out of frame.
metadata:
  type: feedback
---

When my proposed fix grows new components, new types, new dependency tickets, or new admin queues, that's the cue to return to the *value* question — not to refine the fix further. Specifically: ask "what concrete functionality breaks without this fix?" If I can't name a load-bearing user-visible behaviour that depends on the fix, the fix is probably over-scoped relative to its problem.

**Why:** On 2026-05-19 on `lucas42/lucos_media_metadata_api#237`, I responded to lucas42's "are we overloading Person for bands?" question by proposing an `eolas:Group` type. The Group introduction created a disambiguation problem (how to type new artist values at import time), which I solved by proposing deferred resolution + a background enrichment worker + an admin review queue + cross-type re-typing in eolas. That's three follow-up tickets, a new type, and new estate-wide machinery — to fix the fact that the class label "Person" was technically inaccurate for bands.

Lucas42 stopped the spiral with: *"This now seems like an awful lot of work just to figure out if an artist is a Person or a Group. And what value does that actually deliver? I don't see any functionality which actually depends on that distinction."*

When I re-examined honestly, my three justifications for the Group split all collapsed under inspection:
- Federation pollution: contacts↔eolas Person merging is link-driven (`preferredIdentifier`), not name-driven. No pollution.
- Type-faceted browse: aesthetic, no functionality breaks.
- Person-specific properties: don't exist today; would only matter if they were ever added.

The original simple model (overload Person; eolas-create-on-the-fly; existing merge UI for disambiguation) worked fine. My elaborate machinery dissolved completely.

**How to apply:**

1. **Trigger:** notice when my own proposal needs new types, new components, new prerequisite tickets, or "while we're at it" infrastructure. Each addition is a signal to re-question the problem, not just refine the solution.
2. **Diagnostic question:** "What concrete user-visible behaviour breaks if we don't ship this fix at all?" Name a specific functionality, not "correctness" or "the class label is misleading". If the answer is structural-aesthetic only, scope is probably wrong.
3. **Check load-bearing-ness of justifications.** When I list reasons in a recommendation, walk through each: does this reason translate to a concrete failure mode? Federation arguments need a concrete merge path. Federation-by-name-matching arguments need evidence the system actually merges by name.
4. **Distinguish "do it right now" from "do it when concretely needed".** A type split, a new component, an enrichment worker — these can almost always be added later when a concrete need arises. The cost of deferring is usually low; the cost of premature elaboration compounds across multiple tickets.
5. **Multi-round threads are the danger zone.** When a design has gone through 2+ rounds of refinement and the fix is more elaborate each time, that's the pattern. Use the same diagnostic as a course-correction trigger even when no one has corrected me.

Related: [[feedback_simplify_before_elaborate_in_multi_round]] — same family, different trigger (external correction vs. internal accumulation). [[feedback_question_the_option_list]] — also adjacent; pre-enumerated options bias toward "pick a defensible default" instead of "is this the right question?" When I notice myself building elaborate structure on top of the option-list framing, I should also be checking whether the underlying problem warrants the structure.
