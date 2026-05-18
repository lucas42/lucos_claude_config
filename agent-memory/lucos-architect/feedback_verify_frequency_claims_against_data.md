---
name: verify-frequency-claims-against-data
description: When recommending defaults that depend on "X is dominantly Y in our data", check the actual data via arachne/SPARQL/code before publishing. General-world word usage is not a substitute for library-specific reality.
metadata:
  type: feedback
---

When my reasoning rests on a frequency claim about a specific dataset — "theme_tune values are overwhelmingly TV series", "most artist tags in this library are bands", "almost all `composer` tags are individuals" — verify the claim against the actual data (via arachne MCP, a SPARQL query, or by reading the DB) before publishing. World-knowledge intuitions about how words *usually* get used are not evidence about how they're used in *this* library.

**Why:** On 2026-05-18/19 I made two confident claims in my architectural comment on `lucas42/lucos_media_metadata_api#240`: that `theme_tune` is "overwhelmingly TV series" and `soundtrack` is "overwhelmingly film". Both were pure conjecture from general-world usage of those words. Lucas42 challenged me on it, and when I actually checked arachne, I found a sample showing `soundtrack: Happy Days` — where "Happy Days" is the TV sitcom, not a film. The second sampled `theme_tune` value was also a TV show. Two data points was a tiny sample, but the second was a direct counter-example, and the structural read was worse than the frequency read: the predicate `soundtrack` doesn't carry type semantics at all (TV shows, films, games, musicals, podcasts all have soundtracks). My architectural recommendation that depended on the frequency claim was structurally wrong, not just calibration-wrong.

**How to apply:**

1. Before claiming "X is dominant/common/typical" about a specific dataset in a recommendation, **run at least one cheap query** to sanity-check. `mcp__arachne__count_by_property` and `mcp__arachne__find_entities` are good for this; so are `gh-as-agent` listings and direct DB peeks.

2. Two data points beats zero — even a tiny sample is enough to falsify "overwhelmingly". If you can't find a single counter-example after looking, the claim is at least defensible. If you find one immediately, you didn't have evidence in the first place.

3. Distinguish "the predicate carries type signal" (a structural claim about semantics) from "values of this predicate are typically of type X" (a frequency claim about data). Both need verification, but they fail in different ways and require different fixes when wrong.

4. If a recommendation depends on a frequency claim, name the claim explicitly in the comment so the reader (and future me) can see what would need to be true for the recommendation to hold. Don't bury an assumption in passive voice ("theme_tune is overwhelmingly TV series" — implicit "everyone knows this").

5. Counter-example-driven prior: in this codebase, predicate names rarely constrain target type as strongly as their English readings imply. `composer` includes collaborations; `artist` includes bands; `soundtrack` includes TV shows. When in doubt, assume the predicate is type-permissive and the type information lives in the entity, not the predicate.

Related: [[feedback_verify_premise_not_just_quotes]] — similar shape but about teammate-claimed premises rather than my own intuitions. Both fail when I extrapolate without checking the cheap counter-example. [[feedback_question_the_option_list]] — adjacent: even after I dropped the option-list framing, the frequency claim residue was still anchoring my recommendation. Frame-review needs to extend to my own past wording, not just teammates'.
