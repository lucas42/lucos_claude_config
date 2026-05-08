---
name: arachne find_entities returns rdfs:label not skos:prefLabel
description: find_entities returns alternate names (rdfs:label) sorted alphabetically, not canonical names (skos:prefLabel); use get_entity by URI to verify canonical names
type: feedback
---

`mcp__arachne__find_entities` returns entity labels using `rdfs:label` values sorted alphabetically — these are **alternate names**, not canonical names.

The canonical name stored in the `name` field in lucos_eolas is the `skos:prefLabel`.

**Why:** This caused incorrect name lookups in TWO separate PRs:
- lucos_eolas#71: "Allhalloween" instead of "Hallowe'en", "Chanukah" instead of "Hanukkah", "Chislev" instead of "Kislev"
- lucos_eolas#230 / PR #240: 13 out of 24 TransportMode backfill entries used alternate names (e.g. "chopper" instead of "helicopter", "automobile" instead of "car", "ambulation" instead of "walking")

lucas42 caught both in review. This is a **recurring mistake** — do not rely on `find_entities` results for data migrations.

**How to apply:** When you need the canonical name of any entity for use in code, migrations, or lookups, use `mcp__arachne__get_entity(uri=...)` and read the `skos:prefLabel` field. Never use `find_entities` results as migration lookup keys — they return `rdfs:label` (alternate names), sorted alphabetically, which are frequently NOT the canonical `name`.
