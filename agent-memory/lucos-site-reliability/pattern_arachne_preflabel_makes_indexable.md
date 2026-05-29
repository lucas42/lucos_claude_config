---
name: pattern-arachne-preflabel-makes-indexable
description: arachne ingestor treats any subject with skos:prefLabel as indexable — adding prefLabel to an ontology meta-entity (predicate/class definition) makes it look like an item and forces a label lookup for its rdf:types
metadata:
  type: project
---

When the arachne search-index ingestor (`searchindex.py`) loops over RDF subjects, it produces a Typesense doc for every subject with an `rdf:type` that isn't a "meta type". For each such type it calls `get_label()` + `get_category()`, which require `skos:prefLabel` + `eolas:hasCategory` for that type **in the source RDF** (no triplestore fallback since lucos_arachne#371). If a meta-entity carries `skos:prefLabel`, the doc-building loop visits it and then crashes on its un-labelled rdf:type.

**Meta-type filter:** `IGNORE_TYPES` (denylist) was replaced by the namespace-based `is_meta_type()` (lucos_arachne#544, shipped). It excludes the OWL/RDFS namespaces + two explicit eolas types. **It does NOT exclude the SKOS namespace** — so `skos:Concept` / `skos:ConceptScheme` are treated as indexable domain types.

**Recurrence log:**
- 2026-05-17/18: lucos_eolas#256 added prefLabel to `eolas:preferredIdentifier` (an `owl:AsymmetricProperty`); that type wasn't excluded → crash. Fixed via lucos_arachne#543/#544 (namespace filter).
- 2026-05-28: lucos_media_metadata_api #258/#269 SKOS migration made the RDF export emit `<…/vocab/{predicate}/{slug}> a skos:Concept ; skos:prefLabel …` for ~44 vocab concepts. The doc-builder hits these `skos:Concept` subjects and fails: `Source RDF does not include a label for <…skos/core#Concept>`. Surfaces only on a **complete** export (a truncated export missing the scheme block hides it). Tracked in **lucos_media_metadata_api#271** — pending a design call: label skos:Concept source-side (per #371) vs add SKOS to `is_meta_type` arachne-side.

**How to apply:**
- When any source starts emitting a new `rdf:type` (especially adding `skos:prefLabel` to ontology/vocabulary meta-entities), check `is_meta_type()` covers that type's namespace — else the source must supply `skos:prefLabel` + `eolas:hasCategory` for the type.
- Symptom signature: `Post-ingest update for <source> failed: Source RDF does not include a label for <URI>` — for an OWL/RDFS/SKOS infra URI it's an `is_meta_type` gap; for a genuine domain type it's missing source metadata.
- Consequence to remember: this failure is in the **post-Phase-1 searchindex step** — the **triplestore still updates**, but `set_source_hash` is skipped (so it re-fails every run) and **cleanup is skipped** (which incidentally protects the graph from deletion). See [[pattern_media_metadata_arachne_pipeline]].
