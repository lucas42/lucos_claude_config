---
name: Media API v2→v3 track format migration
description: Cross-service migration of loganne track payloads from v2 to v3 format — now top strategic priority
type: project
---

Media API v2→v3 track format migration is the **top strategic priority** as of 2026-04-06 (previously parked).

**Current state:**
- lucos_media_manager (ceol): dual-format support already merged (PR #182)
- lucos_media_weightings: dual-format support merged (PRs #119, #121). Remove v2 compat tracked in #120 (blocked on #85).
- arachne: not affected by payload format (ignores track payload, fetches fresh data). Auth scheme fixed to Bearer (#221). Content-type validation added (#221). v3 RDF content negotiation added to metadata API (#88).
- lucos_media_metadata_api#85: source migration to v3 — not yet started

**Webhook alert cleared:** All 307 failures resolved as of 2026-04-06. Fixes shipped: loganne retry endpoint (#335), arachne URL encoding (#218) + auth/content-type (#221), metadata API v3 RDF content negotiation (#88) + IRI encoding (#93), weightings dual-format (#119, #121).

**Remaining open issues:**
- lucos_media_metadata_api#85 — migrate loganne events to v3 format (not started)
- lucos_media_weightings#120 — remove v2 backwards compat (blocked on #85)
- lucos_media_metadata_api#89 — flaky TestLoganneEvent test (P3)
- lucos_media_metadata_api#90 — auth panic on malformed Bearer header (P3)

**Why:** Owner has made this the #1 strategic priority as of 2026-04-06.

**How to apply:** v3 migration issues should be treated as `priority:high` during triage. Actively dispatch when the queue is clear.
