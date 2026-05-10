---
name: arachne MCP — list_types vs find_entities count discrepancy
description: list_types count for a type can differ significantly from find_entities results; list_types may inflate counts via OWL inference
type: reference
---

`list_types` reported 124 Historical Event instances. `find_entities` with startYear/endYear properties returned 62. lucas42 confirmed there are only 62 Historical Events total (all dated).

**Why:** `list_types` queries the inferred triplestore, so OWL reasoning can cause entities of other types to be counted as a given type if they're inferred subclasses. `find_entities` may apply tighter filtering.

**How to apply:** When using MCP entity counts for triage or design work, treat `list_types` counts as approximate upper bounds. If precision matters, use `find_entities` with a generous limit and count the results — or flag the count as unverified and let the implementer re-check against the live data.
