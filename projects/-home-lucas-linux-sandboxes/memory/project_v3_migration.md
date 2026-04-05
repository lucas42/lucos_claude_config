---
name: Media API v2→v3 track format migration
description: Cross-service migration of loganne track payloads from v2 to v3 format — parked for now, pick up later
type: project
---

Media API v2→v3 track format migration is in progress but parked as of 2026-04-05.

**Current state:**
- lucos_media_manager (ceol): dual-format support already merged (PR #182)
- lucos_media_weightings: dual-format support in PR #119 (under review)
- arachne: not affected (ignores track payload, fetches fresh data)
- lucos_media_metadata_api#85: source migration to v3 — not yet started

**Related issues still open:**
- Arachne redirect to non-existent `/v3/tracks/` endpoint (causes 400s from Fuseki) — needs either a v3 RDF route or redirect fix. No issue raised yet.
- `media-api.l42.eu` returning 502 externally while `/_info` is healthy — separate issue, not yet raised.

**Why:** Owner wants to focus on clearing the immediate webhook alert first. The broader v3 migration and arachne redirect issues are out of scope for now.

**How to apply:** Don't dispatch v3 migration work unless the owner brings it back in scope. The remaining webhook alert clearance depends on PR #119 (weightings) only.
