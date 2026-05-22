---
name: design-for-all-consumers
description: When designing a merge/aggregation/normalisation layer, enumerate all consumers of the underlying data before scoping — not just the consumer who motivated the design
metadata:
  type: feedback
---

When designing a layer that merges, aggregates, normalises or otherwise transforms data from multiple sources, enumerate every consumer that reads the underlying data before deciding scope. Scoping to the originating consumer creates a class of bug where the originating consumer sees a coherent view but other consumers (UIs, sibling APIs, future systems) still see the raw asymmetry.

**Why:** lucos_arachne#539 merged `foaf:Person` documents in the search-index layer to fix the lucos_photos / lucos_search_component face-tagging case. The design body was explicit that the triplestore stays raw — a conscious trade-off to keep the federation layer cheap. But the explorer's item page (`/item?uri=...`) queries the triplestore directly, so it surfaced single-source views. The user's reasonable expectation that "merged search hit → merged item page" was violated, and not because of an implementation defect — because the design only considered one consumer (the search component). Discovered 2026-05-22 via lucas42's testing; tracked as arachne#566 (sameAs symmetry materialisation) + arachne#567 (item-page merge across closure).

**How to apply:** when proposing a merge/aggregation/normalisation layer, list the consumers explicitly in the design document. For each, state whether the new layer affects what they see, and whether their existing expectations remain intact. Pay special attention to UIs that *render* the underlying data — they're often invisible from the original problem statement (which usually centres on a programmatic consumer) but they're the most user-visible failure mode when scope is too narrow. Generalises [[loganne-consumer-test]] from event-bus design to all federation/aggregation design.
