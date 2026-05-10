---
name: arachne ingestor materialises owl:inverseOf and owl:TransitiveProperty closures
description: The ingestor walks meta-property declarations and writes inferred triples to urn:lucos:inferred — declaring either for a high-fan-out predicate causes bloat
type: reference
---

The arachne ingestor (`ingestor/triplestore.py`, `compute_inferences()`) replaced Fuseki's OWL reasoner. It walks two meta-property declarations from any source ontology and materialises closures into `urn:lucos:inferred`:

1. **`owl:TransitiveProperty`** (lines ~170–207): for each declared transitive predicate, computes the full transitive closure across direct triples and writes inferred chains.
2. **`owl:inverseOf`** (lines ~209–242): for each `(p1 owl:inverseOf p2)` pair, fetches all `?s p1 ?o` and `?s p2 ?o` triples, materialises the missing direction in either direction.

The dataset assembler (`triplestore/configuration/arachne.ttl`) sets `tdb2:unionDefaultGraph true`, so `urn:lucos:inferred` is visible to every query on the `arachne` endpoint — including `arachne_explore`'s general-triples item-page query (`?subject ?p ?o LIMIT 1000`).

**Implication for ontology design.** Declaring `owl:inverseOf` or `owl:TransitiveProperty` on a high-fan-out predicate (n:m with skew) materialises bloat. The existing `mmm:onAlbum ↔ mo:track` and `mmm:about ↔ mmm:subjectOf` precedents are fine because each track has one album / few "about" links. `dcterms:language` would NOT be safe — English alone has ~10K tracks; declaring an inverse would write ~10K reverse triples that flood any item-page query for the English Language URI.

**The trap:** "we removed Fuseki inference" is sometimes used to argue that owl:inverseOf is now safe metadata. That is false — the reasoner moved to the ingestor. Always check both the dataset assembler AND the ingestor closure logic before recommending owl:* meta-properties.

**Why this matters more generally:** any future addition of `owl:inverseOf` or `owl:TransitiveProperty` to any source ontology (eolas, contacts, media API, configy, or third-party-cached files in `ingestor/ontologies/`) goes through the same materialisation path. Inverse safety is a property of the *predicate's fan-out*, not the *declaring repo*.

Discovered: 2026-05-10, lucos_arachne#452. Caught by lucas42 after I pivoted on insufficient investigation.
