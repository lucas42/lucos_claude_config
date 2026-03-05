# Architect Memory

## lucos_photos

- Reviewed Feb 2026 (commit c3be2c0). Original summary was filed as issue #27 (now closed -- wrong artefact type)
- Architecture: FastAPI API + Python worker + Postgres + Redis, 4 containers (Qdrant removed per ADR-0001)
- ADR-0001: Use pgvector instead of Qdrant for face embeddings (decided #23, implemented #29, both closed)
- ADRs live in `docs/adr/` with format `NNNN-short-description.md`
- Key open decision: job queue library (recommended RQ in #5 comment)
- Worker-Loganne constraint lifted (#24, closed 2026-03-05): lucas42 decided worker CAN call Loganne directly. Single `photoProcessed` event after processing, fired by worker. Entire inter-component notification mechanism (Options 1-4) became unnecessary. CLAUDE.md updated to remove the ban. Key learning: question architectural constraints early -- this one was premature.
- database.py engine issue (#25) closed after split into #39 (pg_isready retry) and #40 (engine function wrap) -- both approved, ready for implementation
- No docker-compose healthchecks on any container -- reliability gap noted in #27
- PhotoPerson join table alongside Face table could create data consistency issues
- Infrastructure guidance given on #29: use `pgvector/pgvector:pg16-alpine` (not custom Dockerfile), remove QDRANT_URL from lucos_creds, sequence configy volume removal after production deploy
- Android backup client (#3): recommended separate repo `lucos_photos_android` (different platform/toolchain/lifecycle). WorkManager for background sync, sideloaded APK for distribution. No Android SDK in coding sandbox -- tooling gap if agents need to implement.
- Video upload (#60): needs-refining. 6-step incremental delivery proposed. See `project-details.md`.

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
- When recommending infrastructure changes that span multiple repos/systems, always specify sequencing dependencies explicitly (e.g. deploy before removing configy entries, not the other way round). This was validated on the Qdrant removal work.
- Summary/tracking issues are the wrong artefact for architectural reviews. Confirmed by #27 closure. Reviews go in `docs/reviews/`, individual actionable issues are the work items.
- lucas42 prefers splitting multi-concern issues into separate tickets for easier implementation (validated on #25 split into #39/#40). Offer the split proactively when filing issues with distinct scopes.
- Strong one-service-per-repo convention across lucos. Different platforms (e.g. Android vs Docker) always get separate repos. Naming: `lucos_{subsystem}_{qualifier}` (e.g. `lucos_contacts_fb_import`, `lucos_photos_android`).

## Infrastructure notes

- `lucos/build-amd64` CI orb builds and pushes Docker images; large images (>1GB) significantly impact build/deploy times
- `depends_on` in compose does not wait for service readiness, only container start. Projects with Postgres should have startup retry logic.
- ARM builds currently use pici (DinD+SSH on ARM hosts). Recommended replacing with `docker buildx` + QEMU (pici#9). Decision pending.
- Image tags use `${ARCH}-latest` pattern (e.g. `lucas42/lucos_router:armv7l-latest`). Migration to multi-platform manifests would eliminate this.
- ARM-deployed services: lucos_media_import, lucos_media_linuxplayer, lucos_private, lucos_router, lucos_static_media (xwing=armv7l, salvare=arm64)

## Claude Code setup review (Mar 2026)

Reviewed all 3 repos: `lucos_claude_config` (~/.claude), `lucos_agent`, `lucos_agent_coding_sandbox`.

Key issues filed (closed):
- lucas42/lucos_agent#8: DONE. `personas.json` created as single source of truth in `lucos_agent`. Decision: keep local (not configy) for zero-network-dependency at token generation time. Follow-up: lucos_configy#33 for optional HTTP API later.
- lucas42/lucos_claude_config#4: DONE. Cron job (*/15) auto-commits `agent-memory/` only, using lucos-system-administrator[bot] identity. Script at `~/.claude/scripts/commit-agent-memory.sh`.
- lucas42/lucos_agent_coding_sandbox#3: DONE (fixed by lucos-system-administrator as part of other work).
- lucas42/lucos_agent_coding_sandbox#4: DONE. Global git identity removed; bare `git commit` now fails loudly.

Key issues filed (open):
- lucas42/lucos_agent#9: get-token has no caching; generates fresh token per API call. Latency and rate-limit concern.
- lucas42/lucos_claude_config#3: Three persona files have wrong memory paths (/Users/lucas/ instead of /home/lucas.linux/)
- lucas42/lucos_claude_config#5: CLAUDE.md too large, mixes reference docs with agent instructions. Recommend factoring out.
- lucas42/lucos_agent_coding_sandbox#5: README has wrong bot user ID (uses App ID)

Overall assessment: well-designed isolation model (Lima VM, no host mounts, dedicated SSH key). Identity sprawl partially addressed (personas.json exists), auto-commit for memory now in place. Remaining: token caching, memory path fix, CLAUDE.md restructure, git identity fallback risk, README correction.

Script consolidation (#11): reviewed 2026-03-05, recommended keeping current split:
- `lucos_agent` = GitHub API auth tooling (get-token, gh-as-agent, get-issues-*, get-prs-*, get-*-alerts, personas.json)
- `lucos_claude_config/scripts` = cron-driven self-maintenance (commit-agent-memory.sh)
- `lucos_agent_coding_sandbox` = one-time VM provisioning (setup-repos.sh)
Split is principled: GitHub API concern vs environment self-maintenance vs bootstrapping. Awaiting lucas42 decision.

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
- Device list (#112): in-memory HashMap, never cleaned up. Proposed lazy filtering via `lastSeen` timestamp + 5min threshold. Keep entries in map but exclude from poll response. Awaiting approval.

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
- MCP server (#15): recommended against for now. Direct HTTP access (SPARQL + Typesense) via wrapper script is simpler. Revisit MCP when multiple agents need access or query patterns become complex. Fuseki requires basic auth (Shiro); need read-only credential for agent env.
- lucos_configy#33 (persona data via configy API): recommended closing as not planned. No consumer, personas.json already solves the source-of-truth problem. Configy's data model is a poor fit for identity/auth data.

## lucos_monitoring

- Erlang OTP application: server (gen_tcp HTTP), fetcher (polls /_info per host every 60s), monitoring_state_server (gen_server with SystemMap + SuppressionMap)
- State: `Host => {SystemName, SystemChecks, SystemMetrics}` in-memory only, no persistence
- Uses `network_mode: host`, single container, service-list baked at Docker build from lucos_configy
- Email notifications on state changes via gen_smtp_client; suppression window for deploys (10 min)
- Proposed: `/api/status` JSON endpoint for LLM agent read-only access (#26). Recommended against MCP and against separate process -- existing per-request isolation in server is sufficient.
- /_info consumer: `parseInfo` reads `system` (required, crashes if missing), `checks` (defaults {}), `metrics` (defaults {}), `ci.circle` (defaults null). Ignores title/icon/show_on_homepage/start_url/network_only.

## lucos_root

- Static site served by Apache, built at Docker build time
- Build-time `fetch-service-info.sh` consumes /_info from all services via lucos_configy system list
- /_info consumer: filters by `show_on_homepage==true`, uses `icon`, `title`, `start_url` (defaults "/"), `network_only`. Does NOT read system/checks/metrics/ci.
- /_info schema proposal posted on lucos#35 (2026-03-05): revised 3-tier schema accepted by lucas42.
  - Tier 1 (required): system, checks, metrics. Tier 2 (recommended): ci, title. Tier 3 (frontend only): icon, show_on_homepage, network_only, start_url.
  - lucas42 feedback: frontend-specific fields should not be recommended for APIs. Also wants lucos_monitoring to start using `title` field.
  - Next: formal spec doc, monitoring ticket for title support, per-service compliance tickets, CLAUDE.md update.

## lucos_media_seinn

- Node.js music player client (Express server + webpack client + service worker)
- Service worker handles long-polling to media_manager, caches poll data
- Device switching: `track-status-update.js` sends position every 30s + on device_notcurrent/device_changing events
- Playback sync gap (#14): revised design posted 2026-03-05 covering both seinn and linuxplayer
  - lucos_media_linuxplayer is the bigger problem: only sends current-time on pause, no periodic updates, no device_notcurrent handler
  - Proposed: add 10s periodic updates + device_notcurrent position push to linuxplayer (essential), reduce seinn interval from 30s to 10s (lower priority)
  - Awaiting lucas42 approval to split into implementation tickets

## lucos_media_linuxplayer

- Node.js + mplayer (headless), deployed on ARM hosts (xwing, salvare, virgon-express)
- Architecture: long-poll to media_manager, mplayer subprocess controlled via stdin commands
- Device UUIDs hardcoded per HOSTDOMAIN in local-device-updates.js
- Only sends playback position to server on pause -- no periodic updates, no device_notcurrent handler
- This is the primary cause of stale playback position on device switch (#14)

## pici

- Docker-in-Docker CI for ARM builds (armv7l on xwing, arm64 on salvare)
- Stale images (#3): Docker volume accumulates old layers. Proposed: `docker system prune -f --filter "until=48h"` in `quickbuild.sh` after push.

## lucos_repos

- Greenfield redesign (#22): Go + SQLite, convention auditing. Implementation tickets #23-#30.
- Audit lifecycle (#30): design posted, awaiting approval. See `project-details.md` for full design.

## lucos_creds

- Go server, SQLite storage, AES-GCM encrypted values. Two credential types: simple (key-value) and linked (inter-system API keys).
- SSH key issue (#61): proposed fixing .env quoting for multiline values. See `project-details.md`.

## lucos_time

- Node.js service: raw `http.createServer`, single `server.js` (~105 lines), no framework
- Currently serves clock UI with video backgrounds, `/now` (JSON timestamp), `/_info`
- No CLAUDE.md, no tests
- docker-compose: single container, `network_mode: host`, env vars `MEDIAURL` and `PORT`
- Issue #70: `/current-items` endpoint -- DESIGN AGREED, ready for implementation
  - Fetch eolas `/metadata/all/data/` RDF dump, cache in memory, refresh hourly
  - Phase 1: Gregorian + DayOfWeek only, skip non-Gregorian calendars
  - DayOfWeek order: 1=Monday to 7=Sunday. JS getDay() 0=Sunday needs mapping.
  - Gregorian months: order 1=January to 12=December
  - Festivals: current for 1 day if day_of_month set, entire month if null
  - Seasons excluded (no date fields in eolas model)
  - Response: `{ items: [{uri, name, type}], evaluated_calendars, timezone, as_of }`
  - Endpoint path: `GET /current-items`
  - Follow-up tickets filed: lucos_time#74 (non-Gregorian), lucos_eolas#67 (JSON list endpoint), lucos_eolas#68 (festival duration model)

## lucos_eolas

- Django app, personal metadata/ontology manager, Postgres + nginx
- Auth: `Authorization: Key <apikey>` header via `@api_auth` decorator
- API endpoints: `/metadata/<type>/<pk>/data/` (individual RDF), `/metadata/all/data/` (full dump), `/ontology` (no auth)
- 5 calendars: Chinese, Gregorian, Hebrew, Hijri, Hindu
- Festival duration (#68): Option C proposed, awaiting decision. See `project-details.md`.

## lucos_media_metadata_api

- Go + SQLite, multi-value fields (#34): revised design posted, awaiting lucas42 confirmation. See `project-details.md`.

## Cross-cutting: User-Agent convention (lucos#19, closed)

- ADR-0001 in lucas42/lucos: `docs/adr/0001-user-agent-strings-for-inter-system-http-requests.md`
- Convention: set User-Agent to `SYSTEM` env var value for all inter-system HTTP requests.
