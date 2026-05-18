---
name: lucos-arachne-claude-md-domain-types-caveat
description: The lucos_arachne CLAUDE.md convention "sources must include type metadata for every rdf:type" applies only to domain types, not OWL/RDFS meta-types — the text doesn't say this yet
metadata:
  type: project
---

`lucos_arachne/CLAUDE.md` contains a convention from `lucas42/lucos_arachne#371`:

> "The source's RDF export must include type metadata (skos:prefLabel and eolas:hasCategory) for every rdf:type it emits."

This text reads as absolute but is **only correct for domain types**. OWL/RDFS meta-types (`owl:ObjectProperty`, `owl:AsymmetricProperty`, `rdfs:Class`, etc.) are infrastructure — there's no realistic way for sources to provide `skos:prefLabel`/`eolas:hasCategory` for them, and the ingestor's `IGNORE_TYPES` denylist (or its planned namespace-filter replacement in `lucas42/lucos_arachne#544`) is what keeps them out of the indexing loop.

**Why:** The 2026-05-17/18 incident (`owl:AsymmetricProperty` crash, 14h31m partial degradation) exposed this mismatch. The CLAUDE.md convention hasn't been updated yet — `lucas42/lucos_arachne#544` is where it should be fixed alongside the namespace-filter rewrite.

**How to apply:** When reviewing any lucos_arachne PR that:
- Touches `CLAUDE.md` or references the `#371` convention
- Implements `#544` (the namespace-filter rewrite)
- Adds new `rdf:type` declarations anywhere in the estate

...verify whether the "domain types only" boundary is made explicit. Push back if the text still implies OWL meta-types need source-side metadata.
