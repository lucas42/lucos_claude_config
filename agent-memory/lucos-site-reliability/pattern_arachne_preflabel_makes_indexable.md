---
name: pattern-arachne-preflabel-makes-indexable
description: arachne ingestor treats any subject with skos:prefLabel as indexable — adding prefLabel to an ontology meta-entity (predicate/class definition) makes it look like an item and forces a label lookup for its rdf:types
metadata:
  type: project
---

When the arachne search-index ingestor (`searchindex.py:graph_to_typesense_docs`) loops over RDF subjects, it produces a Typesense doc for every subject that has any `rdf:type` not in `IGNORE_TYPES`. A subject whose only rdf:types are in IGNORE_TYPES gets `doc["type"] = None` and is dropped silently elsewhere; otherwise the ingestor calls `get_label()` on the rdf:type — which requires a `skos:prefLabel` in the source RDF (no triplestore fallback since #371).

**Why:** The relevant chain of events from 2026-05-17/18 incident: lucos_eolas#256 added `eolas:preferredIdentifier a owl:ObjectProperty, owl:AsymmetricProperty ; skos:prefLabel "preferred identifier"@en`. The `skos:prefLabel` was harmless on its own — it's the right thing on a predicate definition. But it caused the predicate to be visited by the doc-building loop, and `owl:AsymmetricProperty` wasn't in IGNORE_TYPES → get_label crashed.

**How to apply:**
- Whenever someone adds a `skos:prefLabel` to an *ontology meta-entity* (predicate definition, class definition, restriction), check that ALL of its `rdf:type`s are covered by `IGNORE_TYPES` — or that lucos_arachne#544 (namespace-based filter) has shipped, after which this stops mattering.
- Symptom signature: `Post-ingest update for <source> failed: Source RDF does not include a label for <OWL_OR_RDFS_URI>` in lucos_arachne monitoring debug — that's an IGNORE_TYPES gap, not a missing-metadata-in-source bug.
- Fix shape: add the offending URI to `IGNORE_TYPES` in `ingestor/searchindex.py` (matches commit f027781 pattern). Same shape resolved the 2026-05-18 incident in lucas42/lucos_arachne#543.
