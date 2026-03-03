# Architect Memory

## lucos_photos

- Reviewed Feb 2026 (commit c3be2c0). Original summary was filed as issue #27 (now closed -- wrong artefact type)
- Architecture: FastAPI API + Python worker + Postgres + Redis, 4 containers (Qdrant removed per ADR-0001)
- ADR-0001: Use pgvector instead of Qdrant for face embeddings (decided #23, implementation #29)
- ADRs live in `docs/adr/` with format `NNNN-short-description.md`
- Key open decision: job queue library (recommended RQ in #5 comment)
- Key open decision: how API learns about worker processing completion (#24)
- database.py has module-level engine creation -- fragile pattern (#25)
- No docker-compose healthchecks on any container -- reliability gap noted in #27
- PhotoPerson join table alongside Face table could create data consistency issues

## Architectural review convention (agreed -- lucas42/lucos#24)

- Reviews are committed Markdown files in `docs/reviews/` in each repo
- Filename: `YYYY-MM-DD-review.md`
- Separate from ADRs (`docs/adr/`) -- reviews are snapshots, ADRs are decisions
- Do NOT file summary issues for reviews. File individual actionable issues only.
- Submit review file via PR; the PR is the reviewable artefact
- CLAUDE.md should include a pointer to `docs/reviews/` so agents know where to look
- Template includes mandatory "Sensitive findings" section (link to Security Advisory or "None")
- Codified in lucos-architect persona instructions (lucos_claude_config commit 02983b9)
- Retroactive lucos_photos review: PR #32 (merged)
- lucos_photos CLAUDE.md now has pointer to `docs/reviews/` (included in PR #32)
- lucas42/lucos#24 is now closed (all work complete)
- Follow-up: lucas42/lucos#25 tracks GitHub Security Advisory practice for sensitive findings

## Cross-project patterns

- Module-level side effects in shared packages (database connections, env var reads) are a recurring fragility pattern. Watch for this in other projects.
- The lucos convention of hardcoding auth domain as `https://auth.l42.eu` is sometimes expressed as a compose env var (`LUCOS_AUTHENTICATION_URL`), which is confusing. Better to hardcode in application code.

## Infrastructure notes

- `lucos/build-amd64` CI orb builds and pushes Docker images; large images (>1GB) significantly impact build/deploy times
- `depends_on` in compose does not wait for service readiness, only container start. Projects with Postgres should have startup retry logic.

## Claude Code setup review (Mar 2026)

Reviewed all 3 repos: `lucos_claude_config` (~/.claude), `lucos_agent`, `lucos_agent_coding_sandbox`.

Key issues filed:
- lucas42/lucos_agent#8: Persona identity scattered across 5+ locations in 3 repos. Root cause of "adding a persona is cumbersome". Recommended: single personas.json registry.
- lucas42/lucos_agent#9: get-token has no caching; generates fresh token per API call. Latency and rate-limit concern.
- lucas42/lucos_claude_config#3: Three persona files have wrong memory paths (/Users/lucas/ instead of /home/lucas.linux/)
- lucas42/lucos_claude_config#4: No mechanism to auto-commit agent memory changes
- lucas42/lucos_claude_config#5: CLAUDE.md too large, mixes reference docs with agent instructions. Recommend factoring out.
- lucas42/lucos_agent_coding_sandbox#4: Global git identity creates silent fallback when persona forgets -c flags
- lucas42/lucos_agent_coding_sandbox#5: README has wrong bot user ID (uses App ID)

Overall assessment: well-designed isolation model (Lima VM, no host mounts, dedicated SSH key). Main weakness is identity data sprawl and lack of automation for config repo maintenance.

## lucos_contacts

- Django app with calendar ICS endpoint (`app/agents/calendar.py`)
- Calendar uses `nextOccurence()` which only returns future dates -- no historical events
- 265 starred contacts, 131 calendar events in production (as of Mar 2026)
- Recommended 1-month rolling lookback for calendar history (#523)
- `lucos_contacts_gphotos_import`: standalone HTML-scraping import tool pattern (view-source, paste, run script)
- Recommended same standalone-repo pattern for Facebook import (#7), scoped to names+birthdays

## lucos_media_manager

- Java codebase with long-polling mechanism (`LongPollControllerV3.java`)
- Polling loop uses `Thread.sleep(1)` busy-wait with nanoTime timeout check
- Flaky `pollTimeout` test (#79): race condition -- 500ms slack between poll timeout and Mockito verify timeout. Fix: increase Mockito timeout from 2000ms to 3000ms.

## lucos_media_metadata_manager

- PHP front-end for media metadata API
- Search currently delegates to API (`LIKE "%query%"` in SQLite)
- Bulk edit is coupled to search: PATCHes same API URL as GET search
- Recommended client-side Typesense integration via lucos_arachne for better search (#51)
- Keep existing API search for bulk edit and advanced/null-field search
- Agreed with lucas42: add dedicated `tracks` collection to arachne (alongside general `items`). Filed as lucos_arachne#47.
- RDF export has ~20 predicates per track; `items` collection only captures 5 fields. Dedicated collection unlocks faceted search by artist/album/genre/language/year/rating.
- Note: artist/album/genre values in RDF are encoded as search URLs, need URL-decoding in ingestor.

## lucos_arachne

- Architecture: nginx web proxy + Typesense search + Apache Jena Fuseki triplestore + Python ingestor + explore UI
- Typesense `items` collection: `type`, `category` (facets), `pref_label`, `labels`, `description`, `lyrics`, `lang_family`
- Ingestor consumes RDF from multiple lucos systems, converts to Typesense docs
- Search endpoint: `/search` proxied to Typesense `/collections/items/documents/search`
- CORS enabled, supports read-only client keys for browser-side search
- Dedicated `tracks` collection planned (#47) with ~15 faceted fields from media RDF export

## lucos_monitoring

- Erlang OTP application: server (gen_tcp HTTP), fetcher (polls /_info per host every 60s), monitoring_state_server (gen_server with SystemMap + SuppressionMap)
- State: `Host => {SystemName, SystemChecks, SystemMetrics}` in-memory only, no persistence
- Uses `network_mode: host`, single container, service-list baked at Docker build from lucos_configy
- Email notifications on state changes via gen_smtp_client; suppression window for deploys (10 min)
- Proposed: `/api/status` JSON endpoint for LLM agent read-only access (#26). Recommended against MCP and against separate process -- existing per-request isolation in server is sufficient.
