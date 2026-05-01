---
name: arachne find_entities returns rdfs:label not skos:prefLabel
description: find_entities returns alternate names (rdfs:label) sorted alphabetically, not canonical names (skos:prefLabel); use get_entity by URI to verify canonical names
type: feedback
---

`mcp__arachne__find_entities` returns entity labels using `rdfs:label` values sorted alphabetically — these are **alternate names**, not canonical names.

The canonical name stored in the `name` field in lucos_eolas is the `skos:prefLabel`.

**Why:** This caused incorrect name lookups in lucos_eolas#71 — "Allhalloween" was returned instead of "Hallowe'en", "Chanukah" instead of "Hanukkah", "Chislev" instead of "Kislev". lucas42 caught it in review.

**How to apply:** When you need to verify the canonical name of an entity for use in code or migrations, use `mcp__arachne__get_entity(uri=...)` and read the `skos:prefLabel` field — not the `rdfs:label` values returned by `find_entities`.
