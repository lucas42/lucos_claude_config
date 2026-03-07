# Detailed Project Notes

Overflow from MEMORY.md for projects with extensive design history.

## lucos_media_metadata_api -- Multi-value fields (#34)

- Go + SQLite, schema-agnostic key-value tags per track (UNIQUE constraint on trackid+predicateid)
- lucas42 rejected: predicate_schema DB table (prefers schema in code), all-arrays approach (dislikes `track.artist[0]`)
- Revised: `multiValuePredicates` as Go constant map (composer, producer, language, offence, about, mentions)
- Data migration: drop UNIQUE constraint, split comma-separated values into separate rows
- Internal refactor needed: map[string]string -> []Tag before schema change
- Search gets simpler with normalised rows (existing JOIN pattern works unchanged)
- rdfgen already has `splitCSV` for multi-value predicates -- can be removed after migration
- Consumers: lucos_media_metadata_manager (PHP), lucos_media_manager (Java), lucos_arachne ingestor (Python), lucos_media_import, lucos_media_weightings
- GET/PUT/PATCH must use same shape (no asymmetry). PUT/PATCH replaces all values for multi-value predicates.
- `DecodeTrack` needs custom JSON unmarshaller for v3 (tags become `map[string]interface{}`)
- 8-step implementation plan: audit -> internal refactor -> define multiValuePredicates -> DB migration -> v3 endpoints -> update rdfgen -> migrate consumers -> deprecate v2
- Revised design posted. Awaiting lucas42 confirmation before filing implementation tickets.

## lucos_repos -- Greenfield redesign (#22)

- Currently a shell: Node.js /_info + deprecated webhook. lucas42 wants greenfield reimagining.
- Proposed: Go + SQLite, single container, deterministic convention auditing
  - Scheduled sweep every 6 hours (not webhook-driven)
  - Convention checks defined in code (Go functions), not config
  - Raises GitHub issues on non-compliant repos (one per finding)
  - HTML dashboard (server-rendered) + JSON API for compliance matrix
  - Repo list from GitHub API (all lucas42 repos), not hardcoded
  - Auth: GitHub App (not PAT -- lucas42 wants clear attribution)
  - Implementation tickets filed: #23-#30
- Auto-merge reusable workflows (#70): recommended `lucas42/.github` repo (Option A). Two reusable workflows + thin per-repo callers. Pinned to `@main` (branch-protected). #71 (convention checks) blocked by #70.
- Audit issue lifecycle (#30): design posted 2026-03-05
  - Audit result is source of truth, not issue state
  - New issues instead of reopening (cleaner timeline, avoids confusion)
  - `audit-finding` label on all audit-raised issues
  - Auto-close from PRs: let it happen, self-heals on next sweep if fix was incomplete
  - Accepted risk: `audit-suppressed` label on closed issues prevents re-creation
  - Awaiting lucas42 approval

## lucos_photos -- Video upload (#60)

- needs-refining. Reviewed 2026-03-04.
- Key design decisions pending: table rename (photo->media_item vs discriminator column), video size limits, transcoding scope, face detection deferral
- Recommended 6-step incremental delivery
- Streaming upload is prerequisite (current endpoint reads entire file into memory)
- Range request support needed for video serving
- Residual Qdrant check still in /_info endpoint code

## lucos_eolas -- Festival duration (#68)

- Option C DECIDED. Separate FestivalPeriod model (extends EolasModel). Refined design posted 2026-03-06. Awaiting approval to file implementation tickets. lucos_time#76 blocked on this.
- Key: FestivalPeriod has festival FK (CASCADE), start_day, start_month FK, duration_days. Uses inherited `name` not separate label.
- Backward compat: Festivals with no periods use existing day_of_month/month fields (consumer-side logic in lucos_time).

## lucos_creds -- SSH key issue (#61)

- Multiline values break .env format. Proposed fixing .env quoting for multiline values rather than adding a new credential type.
- Dedicated key lifecycle management (generation, rotation) deferred as unnecessary at current scale (2-3 keys).

## Claude Code setup review (Mar 2026)

Reviewed all 3 repos: `lucos_claude_config` (~/.claude), `lucos_agent`, `lucos_agent_coding_sandbox`.

Key issues filed (closed):
- lucas42/lucos_agent#8: DONE. `personas.json` created as single source of truth in `lucos_agent`.
- lucas42/lucos_claude_config#4: DONE. Cron job (*/15) auto-commits `agent-memory/`.
- lucas42/lucos_agent_coding_sandbox#3: DONE. Fixed by lucos-system-administrator.
- lucas42/lucos_agent_coding_sandbox#4: DONE. Global git identity removed.

Key issues filed (open):
- lucas42/lucos_agent#9: get-token has no caching; generates fresh token per API call.
- lucas42/lucos_claude_config#3: Three persona files have wrong memory paths.
- lucas42/lucos_claude_config#5: CLAUDE.md too large, recommend factoring out.
- lucas42/lucos_agent_coding_sandbox#5: README has wrong bot user ID.

Key changes (post-review):
- `--app` flag now REQUIRED on `get-token` and `gh-as-agent` (no default). Errors with helpful message if omitted.
- `lucos-developer` persona created for general implementation tasks (replaces old `lucos-agent` fallback).
- Dispatcher cannot make git/GitHub calls directly -- must hand off to a persona.

Overall assessment: well-designed isolation model (Lima VM, no host mounts, dedicated SSH key). Identity sprawl partially addressed (personas.json exists), auto-commit for memory now in place.

Script consolidation (#11): reviewed 2026-03-05, recommended keeping current split:
- `lucos_agent` = GitHub API auth tooling
- `lucos_claude_config/scripts` = cron-driven self-maintenance
- `lucos_agent_coding_sandbox` = one-time VM provisioning
Awaiting lucas42 decision.

## lucos_contacts

- Django app with calendar ICS endpoint (`app/agents/calendar.py`)
- Calendar uses `nextOccurence()` which only returns future dates -- no historical events
- 265 starred contacts, 131 calendar events in production (as of Mar 2026)
- Recommended 1-month rolling lookback for calendar history (#523)
- `lucos_contacts_gphotos_import`: standalone HTML-scraping import tool pattern
- Recommended same standalone-repo pattern for Facebook import (#7), scoped to names+birthdays

## lucos_media_manager

- Java codebase with long-polling mechanism (`LongPollControllerV3.java`)
- Polling loop uses `Thread.sleep(1)` busy-wait with nanoTime timeout check
- Flaky `pollTimeout` test (#79): race condition. Fix: increase Mockito timeout from 2000ms to 3000ms.
- Device list (#112): in-memory HashMap, never cleaned up. Proposed lazy filtering via `lastSeen` timestamp + 5min threshold.

## lucos_media_metadata_manager

- PHP front-end for media metadata API
- Search delegates to API (`LIKE "%query%"` in SQLite)
- Bulk edit coupled to search: PATCHes same API URL as GET search
- Recommended client-side Typesense integration via lucos_arachne for better search (#51)
- Keep existing API search for bulk edit and advanced/null-field search
- Agreed: dedicated `tracks` collection in arachne (lucos_arachne#47)
- RDF export has ~20 predicates per track; `items` collection only captures 5 fields
- Note: artist/album/genre values in RDF are encoded as search URLs, need URL-decoding in ingestor

## lucos_arachne

- Architecture: nginx web proxy + Typesense search + Apache Jena Fuseki triplestore + Python ingestor + explore UI
- Typesense `items` collection: `type`, `category` (facets), `pref_label`, `labels`, `description`, `lyrics`, `lang_family`
- Ingestor consumes RDF from multiple lucos systems, converts to Typesense docs
- Dedicated `tracks` collection planned (#47) with ~15 faceted fields
- MCP server (#15): recommended against for now. Revisit when multiple agents need access.
- lucos_configy#33 (persona data via configy API): recommended closing as not planned.

## lucos_monitoring

- Erlang OTP application: server (gen_tcp HTTP), fetcher (polls /_info per host every 60s), monitoring_state_server (gen_server)
- State: `Host => {SystemName, SystemChecks, SystemMetrics}` in-memory only, no persistence
- Uses `network_mode: host`, single container, service-list baked at Docker build from lucos_configy
- Email notifications on state changes via gen_smtp_client; suppression window for deploys (10 min)
- Proposed: `/api/status` JSON endpoint for LLM agent read-only access (#26)
- /_info consumer: reads `system` (required), `checks` (defaults {}), `metrics` (defaults {}), `ci.circle` (defaults null)

## lucos_root

- Static site served by Apache, built at Docker build time
- Build-time `fetch-service-info.sh` consumes /_info from all services via lucos_configy system list
- /_info consumer: filters by `show_on_homepage==true`, uses `icon`, `title`, `start_url` (defaults "/"), `network_only`
- /_info schema proposal posted on lucos#35 (2026-03-05): revised 3-tier schema accepted by lucas42

## lucos_media_seinn

- Node.js music player client (Express server + webpack client + service worker)
- Service worker handles long-polling to media_manager, caches poll data
- Device switching: `track-status-update.js` sends position every 30s + on device_notcurrent/device_changing events
- Playback sync gap (#14): revised design posted 2026-03-05 covering both seinn and linuxplayer
  - Proposed: add 10s periodic updates + device_notcurrent position push to linuxplayer (essential), reduce seinn interval 30s to 10s (lower priority)

## lucos_media_linuxplayer

- Node.js + mplayer (headless), deployed on ARM hosts (xwing, salvare, virgon-express)
- Device UUIDs hardcoded per HOSTDOMAIN in local-device-updates.js
- Only sends playback position to server on pause -- primary cause of stale position on device switch (#14)

## pici

- Docker-in-Docker CI for ARM builds (armv7l on xwing, arm64 on salvare)
- Stale images (#3): proposed `docker system prune -f --filter "until=48h"` in `quickbuild.sh` after push

## lucos_time

- Node.js service: raw `http.createServer`, single `server.js` (~105 lines), no framework
- No CLAUDE.md, no tests
- docker-compose: single container, `network_mode: host`, env vars `MEDIAURL` and `PORT`
- Issue #70: `/current-items` endpoint -- DESIGN AGREED, ready for implementation
  - Fetch eolas `/metadata/all/data/` RDF dump, cache in memory, refresh hourly
  - Phase 1: Gregorian + DayOfWeek only, skip non-Gregorian calendars
  - Response: `{ items: [{uri, name, type}], evaluated_calendars, timezone, as_of }`
  - Follow-up tickets: lucos_time#74 (non-Gregorian), lucos_eolas#67 (JSON list), lucos_eolas#68 (festival duration)
