---
name: arachne MCP tool name lookups
description: Which arachne MCP tool returns canonical (skos:prefLabel) names vs alternate (rdfs:label) names — important when verifying entity names for data migrations
type: reference
originSessionId: 32cc845c-d195-4b7b-953d-2007cec8b0c8
---
The arachne MCP server exposes `find_entities` and `get_entity`. They return *different* name fields:

- **`find_entities`** returns `rdfs:label` values (alternate names), sorted alphabetically. For an entity like London, it will return one of the *alternate* names ("Llundein", "Londain", "Londinium", "Lunden", "Trinovantum") — not necessarily the canonical "London".
- **`get_entity`** (called with a URI) returns the full set of triples for that entity, including the `skos:prefLabel` (canonical name).

**Implication:** to verify the canonical name of an entity (e.g. when authoring Django data migrations that look up `Festival.objects.get(name=...)` or similar), use `get_entity` by URI, not `find_entities`. Using `find_entities` results may return a non-canonical name and silently produce wrong lookups.

Surfaced by `lucos-developer` while implementing lucos_eolas#71 (FestivalPeriod data migration), 2026-05-01.

**Access note (2026-06-16):** the coordinator/team-lead is deliberately **not** provisioned with an aithne principal for arachne (lucas42's call — provision on a real future use case, not speculatively). arachne MCP currently works for the coordinator only via the legacy `CLIENT_KEYS` fallback, which lucas42/lucos_arachne#640 will drop once lucas42/lucos_arachne#638 lands — at which point these tools stop working for the coordinator until a principal is requested. So: don't reach for arachne MCP speculatively; if a genuine entity-lookup need arises, flag it to lucas42 to provision a `lucos-issue-manager`/coordinator principal + `arachne:read` grant. Of the agent team, only `lucos-architect` actually consumes arachne MCP (already provisioned).
