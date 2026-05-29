---
name: indexability-exclusion-vs-inclusion
description: arachne search indexer decides "is this subject indexable?" by exclusion (denylist of meta-types) — leads to recurring outages when sources add legitimate metadata; inclusion (allowlist via eolas:hasCategory) is structurally cleaner
metadata:
  type: reference
---

# Indexability driven by exclusion vs inclusion (arachne search index)

The arachne ingestor (`ingestor/searchindex.py`) decides which RDF subjects become Typesense documents by *exclusion*: any subject with a `skos:prefLabel` is treated as indexable unless its `rdf:type` is in a denylist (`IGNORE_TYPES`, or — per [arachne#544](https://github.com/lucas42/lucos_arachne/issues/544) — in a `META_NAMESPACES` set).

**Failure mode this creates.** When an ontology author adds a `skos:prefLabel` to a predicate (entirely legitimate as ontology documentation), the predicate gets pulled into the indexable loop. If the predicate's `rdf:type` isn't in the denylist, the indexer crashes trying to look up a label for the meta-type itself. This happened 2026-05-17/18 (lucos `docs/incidents/2026-05-18-arachne-asymmetric-property-ignore-types-gap.md`): `lucas42/lucos_eolas#256` declared `eolas:preferredIdentifier` with `rdf:type owl:AsymmetricProperty`, which wasn't in `IGNORE_TYPES`, → 14h partial ingest outage. Hotfix #543, broader fix #544.

**Why exclusion is structurally fragile.** Every new vocabulary, every new OWL property characteristic, every new meta-type the ingestor hasn't anticipated re-creates the same outage shape. The denylist needs to know about everything the indexer *isn't* — an open set. The namespace-based filter in #544 narrows the open set considerably (vocabulary namespaces vs individual types) but doesn't close it.

**The cleaner framing: inclusion.** Only index subjects whose `rdf:type` is registered as a domain item type — i.e., has an `eolas:hasCategory` mapping. The ontology already knows what's a domain item; the indexer should consult that knowledge rather than enumerate what's *not* a domain item. The "is this thing indexable?" question is answered by data, not by a hardcoded filter that drifts.

**Why not adopt now.** Bigger change than #544's scope. The namespace filter is a real improvement and the right next step. But the inclusion framing should be recorded as a future direction — the namespace filter still has its own drift risk (new infra vocabulary; we forget to add it; same outage shape, rarer).

**3rd occurrence (2026-05-28, lucos_media_metadata_api#271).** #258's SKOS migration emitted `skos:Concept`/`skos:ConceptScheme` subjects. SKOS namespace was never in `META_NAMESPACES`, so concepts were treated as domain types → `get_label` raised on the `skos:Concept` *type* → media search-index step failed on every ingest. Exactly the predicted "new infra vocabulary we forgot to add" drift. Immediate fix = option 2 (add SKOS core namespace to `META_NAMESPACES`); I framed it as **completing #544, NOT re-scoping #371** (#371 governs domain types; SKOS is W3C controlled-vocabulary infrastructure on the same footing as OWL/RDFS). The inclusion-direction future fix is now tracked as a real issue: **lucas42/lucos_arachne#590** (drive indexability by `eolas:hasCategory` registration, retire the denylist). Note for #590 design: inclusion test must key off the *resolved domain type after special cases* (LanguageFamily→Language branch, per-subject PlaceType category, subClassOf walk), not the raw rdf:type — see [[feedback_check_special_cases_before_extending_pipeline]].

**General lesson.** When a system distinguishes "X items" from "non-X items" via a denylist of non-X, ask whether the system already has a positive definition of X it could consult instead. Denylists drift; positive definitions are self-maintaining.

Related:
- [[reference_arachne_ingestor_inverse_materialisation]] — another arachne ingestor invariant
- [[feedback_data_driven_over_code_rules]] — why `eolas:preferredIdentifier` is an asymmetric property (the change that triggered this incident)
