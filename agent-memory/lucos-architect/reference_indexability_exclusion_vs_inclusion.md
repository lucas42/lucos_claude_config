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

**General lesson.** When a system distinguishes "X items" from "non-X items" via a denylist of non-X, ask whether the system already has a positive definition of X it could consult instead. Denylists drift; positive definitions are self-maintaining.

Related:
- [[reference_arachne_ingestor_inverse_materialisation]] — another arachne ingestor invariant
- [[feedback_data_driven_over_code_rules]] — why `eolas:preferredIdentifier` is an asymmetric property (the change that triggered this incident)
