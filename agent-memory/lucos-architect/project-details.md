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
- Revised design posted. lucas42 confirmed. Implementation tickets filed: #35-#42.
- v3 ideation (#45): API structural changes DECIDED: rename `trackid` -> `id`, remove debug weighting fields, structured JSON errors, richer pagination. Weighting endpoint stays plain text (lucas42 rejected). lucas42 then raised much larger data modelling scope:
  - Moving controlled vocabularies to lucos_eolas: recommended `offence` only; keep `singalong`, `provenance`, `dance` local. General principle: don't centralise speculatively.
  - Freetext-to-controlled: `memory` -> eolas Memory type, `theme_tune`/`soundtrack` -> eolas CreativeWork, `album` -> first-class local concept in API (new table). Merge tooling is prerequisite, not optional.
  - People/groups: recommended Option C (split by type -- contacts for personal, eolas for famous/fictional, link via arachne). Depends on lucos_eolas#19 resolution.
  - Sequencing: v3 ships API structural changes + album concept. Controlled vocab migrations post-v3 (one at a time). People modelling longer term.
  - lucas42 DECIDED: options 1,2,3,5 approved. Option 4 (weighting JSON) rejected.
  - lucas42 raised data modelling scope. Architect responded with per-field recommendations + sequencing.
  - Follow-up (2026-03-10): lucas42 agreed Option C for people. Three questions answered:
    1. lucos_eolas write API: narrow `POST /api/{type}/` for create-on-the-fly (Person, CreativeWork). Not general CRUD.
    2. Posted Option C rationale on lucos_eolas#19.
    3. Breaking change strategy: design v3 tag values as objects (`{"value": "...", "uri": "..."}`) from day one. Then all post-v3 controlled vocab migrations are data migrations, not API changes. No further version bumps needed. Key insight: v3 tag value format must be extensible.
  - lucas42 DECIDED (2026-03-10): tag value format approved. Field name: `name` (not `value` or `label`), consistent with lucos_eolas. Data sync: belt-and-braces (Loganne webhook + periodic reconciliation). Deletion: architect recommended Option A (clear URI, keep name). All awaiting final decision.
  - Write API for lucos_eolas filed as #75. Design input posted: `POST /metadata/{type}/`, returns `{id, name, uri}`, 409 for duplicates. Uses existing `@api_auth`.
  - lucos_eolas#19 follow-ups addressed (2026-03-10): names deferred, contact-to-person linking owned by lucos_contacts (`eolas_uri` field), search filtering via `is_contact` boolean (not `source` field) -- simpler for merged records where one person appears in both contacts and eolas. Merge logic in arachne ingestor using `owl:sameAs`; **eolas URI** used as primary `id` in merged records (revised 2026-03-12 after lucas42 flagged URI consistency problem for media_metadata_api). contacts URI used as primary would cause mixed-URI tags when a person becomes a contact after initial tagging. Consumers needing contacts URI (e.g. lucos_photos) extract it from search record metadata.

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

## lucos_photos -- App downloads (#115)

- Architectural question: where to store Android APK build artifacts.
- Recommended GitHub Releases (Option 1). No new infra. Aligns with #38 (auto-increment version).
- lucos_photos gets `GET /api/app/latest` endpoint (caches GitHub releases API, serves version+download URL).
- Dependency: lucos_photos_android#38 must complete first (versioning + releases).
- Awaiting lucas42 decision.

## lucos_photos_android -- App telemetry (#39)

- Recommended Option A: extend lucos_photos API with `POST /api/telemetry` endpoint (Postgres storage, flexible JSON `data` column).
- Rejected central telemetry service (one consumer, speculative reuse) and Loganne (in-memory, no persistence).
- OpenTelemetry: massive overkill for one app. Skip.
- Migration path: if second consumer appears, extract to central service then.
- Awaiting lucas42 decision.

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

- Architecture: nginx web proxy + Typesense search + Apache Jena Fuseki triplestore + Python ingestor + explore UI + MCP server. 6 containers.
- Typesense `items` collection: `type`, `category` (facets), `pref_label`, `labels`, `description`, `lyrics`, `lang_family`
- Ingestor consumes RDF from 14 named graphs (4 lucos systems + 10 external ontologies), converts to Typesense docs
- Dedicated `tracks` collection planned (#47) with ~15 faceted fields
- lucos_configy#33 (persona data via configy API): recommended closing as not planned.
- **Triplestore config:** TDB2 disk-backed storage + OWLMicroFBRuleReasoner. Two Fuseki endpoints: `raw_arachne` (read-write) and `arachne` (read-only, reasoning). Reasoner materialises inferred triples in memory -- dominant RAM consumer.
- **Memory issue (#86):** OOM-killed twice on avalon. 2GB container limit, `-Xmx1600m`. Root cause: OWL reasoner in-memory inference closure over 14 graphs + invalidation/rebuild on each ingestion run. lucas42 reframed: values inferencing (esp. transitive `containedIn` for places), but not wedded to Fuseki. Revised recommendation: **Option 3 -- pre-compute transitive closures in ingestor**, write to dedicated `urn:lucos:inferred` graph, remove OWL reasoner entirely. Fuseki becomes simple SPARQL store. RDFS reasoner alone won't work (doesn't handle owl:TransitiveProperty). Awaiting lucas42 decision.
- **Monitoring gap (#87):** lucas42 rejected sidecar script (Option 4). Wants `/_info` delegated to **explore container** (Express.js, already has credentials). Checks must be real authenticated queries not pings. Revised design posted: SPARQL query for triplestore, collection lookup for search, TCP for ingestor, skip MCP check (backends covered by other checks). Awaiting lucas42 sign-off.
- **Docker healthcheck (#91):** IPv6/localhost false negative -- `wget http://localhost/_info` fails because nginx binds IPv4 only. Fix: use `127.0.0.1`.

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

## pici (RETIRED 2026-03-17)

- Was Docker-in-Docker CI for ARM builds. All services migrated to `build-multiplatform` orb job (docker buildx + QEMU).
- Repo archived. No active containers. lucos_deploy_orb#9 complete.

## lucos_time

- Node.js service: raw `http.createServer`, single `server.js` (~105 lines), no framework
- No CLAUDE.md, no tests
- docker-compose: single container, `network_mode: host`, env vars `MEDIAURL` and `PORT`
- Issue #70: `/current-items` endpoint -- DESIGN AGREED, ready for implementation
  - Fetch eolas `/metadata/all/data/` RDF dump, cache in memory, refresh hourly
  - Phase 1: Gregorian + DayOfWeek only, skip non-Gregorian calendars
  - Response: `{ items: [{uri, name, type}], evaluated_calendars, timezone, as_of }`
  - Follow-up tickets: lucos_time#74 (non-Gregorian), lucos_eolas#67 (JSON list), lucos_eolas#68 (festival duration)
