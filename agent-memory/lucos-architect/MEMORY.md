# Architect Memory

Detailed per-project notes are in `project-details.md`. This file is an index with key facts only.

## lucos_photos

- Architecture: FastAPI API + Python worker + Postgres + Redis, 4 containers
- ADR-0001: pgvector instead of Qdrant (decided #23, implemented #29, both closed)
- Worker-Loganne constraint lifted (#24, closed): worker CAN call Loganne directly. Key learning: question architectural constraints early.
- database.py engine issue (#25) closed, split into #39 (pg_isready retry) and #40 (engine function wrap)
- Docker-compose healthchecks now present (api + worker)
- SSR (#137): recommended Option 2 (Jinja2 in existing API container). 3 pages to convert (index, photo, people). Eliminates nav duplication and client-side data fetching issues.
- Android backup client (#3): separate repo `lucos_photos_android`
- App downloads (#115): recommended GitHub Releases for APK storage, `GET /api/app/latest` endpoint. Depends on #38 (versioning).
- App telemetry (#39 on android repo): recommended extending photos API with `POST /api/telemetry`. Skip OpenTelemetry. Revisit central service if second consumer appears. Telemetry shares same Postgres DB as app data -- DB restore wipes telemetry too (learned from 2026-03-17 incident). Separation tracked in #211.
- Photo serving (#26, closed): Option 1 (API serves files directly) confirmed. Stable URLs: `/photos/{id}/original`, `/photos/{id}/thumbnail`.
- Video upload (#60): needs-refining. See `project-details.md`.
- Profile pictures (#149): agent-approved, priority:high. Phased approach: 4 criteria now (det_score, frontality from kps, face width, face height), smile/hat deferred. Worker generates crops, stored in `/data/photos/derivatives/`. Two columns on `person` table (profile_photo_id, profile_auto_generated). Need to persist det_score + kps from InsightFace (currently not saved).
- Face reprocessing (#208, merged): `detect_and_save_faces` now preserves `person_confirmed=True` links via embedding cosine similarity matching. Option B (snapshot + re-apply). Key: bounding box IoU is fragile (EXIF orientation transforms coordinates); embedding similarity is invariant.
- Face-to-contact linking (#104): revised design agreed. Sequencing: (1) JSON API on contacts (lucos_contacts#529), (2) person-to-contact linking UI using `lucos_search_component` with `data-types="Person"`, (3) photo detail view (#103), (4) face assignment UI. Steps 1-2 independent of #103. lucas42 wants names managed in contacts, not photos. No proxy endpoint needed -- search component queries arachne client-side. API keys: `KEY_LUCOS_ARACHNE` (client-side search), `KEY_LUCOS_CONTACTS` (server-side only). Open: whether `contact_id` stores full URI or numeric ID. Endpoint rename: `/persons` -> `/people` (lucas42 preference, landed in production).

## Architectural review convention (agreed -- lucas42/lucos#24)

- Reviews: committed Markdown in `docs/reviews/`, filename `YYYY-MM-DD-review.md`
- Separate from ADRs. Do NOT file summary issues. Submit via PR.
- CLAUDE.md should include pointer to `docs/reviews/`
- Mandatory "Sensitive findings" section (link to Security Advisory or "None")
- lucas42/lucos#25 tracks GitHub Security Advisory practice

## Cross-project patterns

- Module-level side effects in shared packages are a recurring fragility pattern
- Auth domain hardcoded as `https://auth.l42.eu` -- prefer in application code, not compose env var
- Always specify sequencing dependencies for cross-repo infrastructure changes
- lucas42 prefers splitting multi-concern issues into separate tickets
- **Always check `origin/HEAD` before reviewing code.** Sandbox copies of repos may be on stale branches. If lucas42 mentions a change they made and the code you're reading doesn't reflect it, run `git fetch && git checkout origin/main` (or equivalent) to ensure you're looking at the latest deployed code.
- Strong one-service-per-repo convention. Naming: `lucos_{subsystem}_{qualifier}`
- Agent instruction compliance ADR: `~/.claude/docs/adr/0001-agent-instruction-compliance.md` in lucos_claude_config. Key practices: extract task lists into short files, explicit counts + completion manifests, dispatcher verification, order by criticality, group by schedule, 200-line max. Originally placed in lucos repo (PR #39, merged then removed), moved to lucos_claude_config as it is specific to agent config.
- lucos_claude_config ADRs live in `~/.claude/docs/adr/`. `.gitignore` updated to allow `docs/` directory. Numbering is independent from lucos repo ADRs.
- ADR-0002: Agent teams migration (lucos_claude_config#14, closed via PR #15). Migrated from subagent Task tool dispatch to agent teams with SendMessage. Identity via persona instructions (not fragile -- same delivery mechanism as before). Team config tracked as `config.canonical.json` (stripped of runtime state). Known constraints: no session resumability, token cost unmeasured, rollback via git revert.
- Paperclip trial (2026-03): trialed for ~2 weeks, rejected. Too many tokens, unhelpful middle-management task copying. Claude Code teams retained.
- Issue-manager merged into team-lead (lucos_claude_config#27, PR #28, 2026-04-02): `coordinator-persona.md` loaded via `/team` skill (skill output = lead-only context, avoids bleed-through). Triage reference data in `references/triage-reference-data.md` (read on-demand). GitHub App identity `lucos-issue-manager` retained for API calls. Issue-manager memory directory preserved as historical reference.
- User-Agent convention (lucos#19, closed): ADR-0001 in lucas42/lucos (`docs/adr/0001-user-agent-strings-for-inter-system-http-requests.md`). Set User-Agent to `SYSTEM` env var value for all inter-system HTTP requests.
- **Bearer auth migration (2026-04-08):** Estate migrating from `Authorization: key` to standard `Bearer`. Original advice (lucos#37, closed) was case-by-case; reversed after arachne#250 outage proved mixed state is untenable. Phase 1 (server dual-accept): eolas#147, media_manager#203. Phase 2 (client switch): media_metadata_api#123, photos#283, googlesync#118, gphotos#32. Phase 3 (drop key + update docs): lucos#74. media_metadata_api is Bearer-only server; contacts & photos are dual-accept; eolas & media_manager are key-only (Phase 1 targets).

## Auto-merge & security checks

- lucos#42: CodeQL race condition with auto-merge. Recommended Option 1: make CodeQL a required status check. No workflow changes needed -- repo settings only. Check name on lucos_photos: `Analyze (python)`. Must be added to prerequisites checklist when rolling out auto-merge to new repos.
- Dependabot auto-merge permissions: must use `pull_request_target` (not `pull_request`) because Dependabot events are fork-like with read-only GITHUB_TOKEN ceiling. See `github-actions-permissions.md`.
- Auto-merge caller workflows require at least `permissions: contents: read` -- `permissions: {}` causes `startup_failure` because GitHub Actions cannot fetch the cross-repo reusable workflow definition without it. Discovered via 2026-03-21 incident.
- `.github` smoke test suite only covers `dependabot-auto-merge`, not `code-reviewer-auto-merge` -- gap tracked in lucos#58.

## Infrastructure notes

- CI orb: `build-multiplatform` is the standard for multi-arch services (amd64+arm64 via buildx+QEMU). `build-amd64` still used for amd64-only services. Large images (>1GB) impact build/deploy times.
- `depends_on` in compose does not wait for service readiness. Projects with Postgres should have startup retry logic.
- ARM builds now use `build-multiplatform` orb job (docker buildx + QEMU). pici retired, repo archived (2026-03-17). No more remote SSH builds.
- ARM-deployed services: lucos_media_import, lucos_media_linuxplayer, lucos_private, lucos_router, lucos_static_media
- **Docker volume restore gotcha**: `docker run` with a new volume does NOT apply Docker Compose labels. lucos_backups depends on these labels. Volume restores must use `docker compose` to create the volume first, or manually apply labels. Documented in lucos_backups#64.
- **2026-03-17 incident**: EXIF reprocess -> face data loss -> DB restore -> unlabelled volume -> deploy failure -> backups crash. Lesson: "idempotent" delete-and-recreate must distinguish ML-generated vs human-curated data.
- **2026-03-19 incident**: Bulk CI push (~30 repos) -> partial .env (missing PORT) -> silent port binding loss -> 502 for ~2h. Issues: lucos_deploy_orb#40, lucos_creds#112.
- **2026-03-20 incident**: Same bulk push -> simultaneous deploys spike avalon load to ~40 -> healthcheck cascade (28/31 erroring). eolas `collectstatic` + arachne ingestor bulk fetch are CPU hotspots. Monitoring restart wiped state, inflating error count.
- **Systemic: bulk deployment waves** are new (agent automation). Four incidents in five days (03-17 through 03-21). Three healthcheck failure patterns: false-healthy (03-17, 03-19), false-unhealthy (03-20). Need: rate-limited bulk pushes, build-time collectstatic, deferred ingestor fetch, monitoring restart resilience.
- **2026-03-21 incident**: `permissions: {}` rolled out to ~45 repos without smoke testing, broke auto-merge estate-wide. Smoke test requested 5 times by lucas42, skipped twice. Corrective rollout raced a hold message. ~39 spurious audit issues + avalon load spike. Root cause: process failure (no smoke test gate in estate-rollout skill). Follow-ups: lucos#58 (smoke test coverage for code-reviewer-auto-merge), lucos#59 (batching gap). Key lesson: agent execution speed is a liability without verification gates that run at the same speed.

## Claude Code setup review (Mar 2026)

- Reviewed `lucos_claude_config`, `lucos_agent`, `lucos_agent_coding_sandbox`. See `project-details.md` for full issue list.
- Overall: well-designed isolation model. Remaining open: token caching (#9), memory path fix (#3), CLAUDE.md restructure (#5), README bot user ID (#5).
- Script consolidation (#11): recommended keeping current 3-repo split. Awaiting lucas42 decision.
- Global git identity removed (sandbox#4, closed): Option A accepted. `lucos-developer` persona created for general implementation tasks.

## Per-project summaries (details in project-details.md)

### lucos_contacts
- Django app, calendar ICS endpoint. Recommended 1-month lookback (#523), Facebook import as separate repo (#7).
- No JSON API yet. Only HTML + RDF (content negotiation). `serializePerson()` returns dict but only used for templates. JSON endpoint filed as #529 (extends content negotiation on `/people/all`).

### lucos_media_manager (ceol.l42.eu)
- Java, long-polling. Domain: `ceol.l42.eu`. **Not** lucos_media_metadata_manager (which is the PHP frontend at media-metadata.l42.eu).
- Flaky test (#79): race condition fix. Device list cleanup (#112): lazy filtering via `lastSeen`.
- Receives loganne webhooks for trackUpdated, trackDeleted, collection events. CustomGson deserialiser has dual v2/v3 format support (PR #182 merged).

### lucos_media_metadata_manager
- PHP front-end. Recommended client-side Typesense via arachne (#51). Dedicated `tracks` collection (arachne#47).

### lucos_configy
- Rust API serving YAML config. Single-host-for-domain constraint (#25): recommended Option A (validation test in existing test suite). dns_sync depends on `hosts[0]` -- silent misconfiguration if violated. Option B (schema split host/hosts) deferred.

### lucos_arachne
- nginx + Typesense + Fuseki + Python ingestor. configy#33: recommended closing.
- **ADR-0001 (2026-03-07):** MCP server for knowledge graph access. Container `lucos_arachne_mcp` in arachne stack, routed via nginx at `/mcp/`. Five tools (`search`, `list_types`, `get_entity`, `find_entities`, `count_by_property`). No raw SPARQL — server generates it from typed parameters. Read-only, reasoning endpoint. Streamable HTTP transport (not SSE — updated from original design). No auth on incoming requests (keys only used for outbound Fuseki/Typesense calls). Configured in Claude Code settings as of 2026-04-07. Implementation: #63-#69, all closed/completed.
- **Key insight: LLMs cannot reliably generate SPARQL** against custom ontologies (killed lucos_comhra). MCP server solves this by hiding SPARQL behind structured tool parameters. Fundamental constraint, not a model quality issue.
- Two Fuseki endpoints: `raw_arachne` (read-write) and `arachne` (read-only, OWL reasoning). `systems_to_graphs` in `ingestor/triplestore.py`.
- Memory #86: lucas42 reframed -- values inferencing (transitive containedIn), not wedded to Fuseki. Recommended pre-computing closures in ingestor. RDFS reasoner alone insufficient (no owl:TransitiveProperty).
- Monitoring #87: lucas42 wants /_info delegated to explore container with real authenticated checks, not sidecar script. Revised design posted.
- Agent sandbox has drift problem (lima provisioning vs actual VM state) — prefer Docker containers for iterative development.

### lucos_monitoring
- Erlang OTP, in-memory state, email notifications. `/api/status` endpoint proposed (#26).
- Flappiness threshold (#74): recommended per-check `failThreshold` in `/_info` (default 1, no recovery threshold). lucas42 raised concern about two parallel retry mechanisms (`unknown_count` + `failThreshold`). Architect argued they are complementary (data quality vs signal quality). Recommended Option 3: keep `unknown` for internal checks, `failThreshold` for external. Awaiting lucas42 decision.

### lucos_root
- Static site, Apache. /_info 3-tier schema accepted (lucos#35). Spec doc: `docs/info-endpoint-spec.md` in lucos repo (PR #41). CLAUDE.md updated. Follow-up: monitoring title ticket, per-service compliance tickets.

### lucos_media_seinn
- Node.js music player. Playback sync gap (#14): design posted, awaiting split into tickets.

### lucos_media_linuxplayer
- Node.js + mplayer on ARM. Primary cause of stale position on device switch (#14).

### pici (archived 2026-03-17)
- Retired. All services migrated to `build-multiplatform` (buildx + QEMU). Repo archived. `build-arm64` and `build-armv7l` orb jobs deprecated.

### lucos_repos
- Greenfield redesign (#22): Go + SQLite, convention auditing. Tickets #23-#30. Audit lifecycle (#30) awaiting approval.
- Convention quality guide (#50): design posted. Key proposal: add `Rationale` and `Guidance` fields to Convention struct so generated issues explain why + how to fix. Awaiting lucas42 decision on scope (docs only vs struct changes).
- Auto-merge holistic checking (#64): design posted. Recommended reusable workflows (central repo) + thin per-repo caller stubs. Option A for configy metadata (add `UnsupervisedAgentCode bool` to `RepoContext`). 6 conventions proposed. Awaiting lucas42 decision on reusable workflow location.
- Rate limit (#66): GitHub Search API 30 req/min limit. Fix: switch to Issues List API. Also: rate-limit backoff + fix misleading "completed successfully" on partial failures.
- Blast radius (#159): lucas42 rejected per-convention cap (too reactive, interferes with deliberate changes). Revised design: dry-run sweep in CI on PRs, diff against production `/api/status`, post as PR comment for reviewer. Needs: `--dry-run` CLI mode, `diff` subcommand, GitHub Actions workflow. ADR-0003. Awaiting lucas42 decision.
- ADR-0004 (#248, PR #251 merged): auto-close audit-finding issues when conventions pass. Amends ADR-0002. Close on first pass with comment; no consecutive-pass threshold. Implementation pending.
- Dependabot PR monitoring (#250): recommended extending PR dashboard + /_info check (not a convention). Stale = >48h open. Awaiting lucas42 decision.

### lucas42/.github
- Reusable workflow repo. Contains dependabot-auto-merge, code-reviewer-auto-merge, convention-check (reusable) + auto-merge, smoke-test (local).
- Structure confusion: no naming distinction between reusable and local workflows. Filed #36 (reusable- prefix).
- Dependabot auto-merge broken estate-wide (#34): callers pinned to broken SHA d514cd6 (secrets in if: condition). Fix on main (68508cf) but never re-rolled-out.
- Tag-based versioning (#35): enable Dependabot to propagate workflow updates. No tags/releases currently exist.
- Smoke test gate (#38): estate rollouts should require smoke test pass on target ref.
- Stale branches (#37): 15 branches from merged PRs never deleted.

### lucos_creds
- Go server, AES-GCM. SSH key .env quoting (#61). See `project-details.md`.
- **CLIENT_KEYS is fully automated**: built from linked credential relationships, not manually editable. To add a token, create a linked credential (client → server); lucos_creds auto-populates the server's CLIENT_KEYS and gives the client a `KEY_<SERVER>` env var. Rotation is per-pair and automatic.
- Scoped permissions (#87): agent-approved. `|` delimiter in `CLIENT_KEYS` (`client:env=key|scope1,scope2`). No scope = no permissions on migrated systems.
- SFTP concurrency concern (#112): bulk CI pushes (~30 simultaneous) may cause partial .env files. PORT now built-in (#109, closed). General concurrency investigation open.

### lucos_loganne
- Node.js, static webhook config (`webhooks-config.json`: event type → URL[]). 5 consumer hosts.
- Webhook auth (#374): per-consumer linked credentials agreed (v2 design). Loganne as client of each consumer. `consumerTokens` hostname→tokenVar map in config. 3-phase zero-downtime migration. 2 consumers need CLIENT_KEYS support added (media_weightings, arachne ingestor).

### lucos_media_weightings
- Python, cron-based. Weighting explosion (#39): agent-approved. Soft cap on multiplier product: `cap * (1 - e^(-raw/cap))`, cap=100 (lucas42 chose to match highest individual multiplier). Collection size is separate problem.

### lucos_time
- Node.js, raw http.createServer. `/current-items` (#70): design agreed, ready for implementation. New requirement (2026-03-05): festivals with `commemorates` predicate (P547) should transitively include HistoricalEvents in the response. Design comment posted.
- Follow-ups: lucos_time#74, lucos_eolas#67, lucos_eolas#68.

### lucos_eolas
- Django, personal metadata/ontology, Postgres. Festival duration (#68): Option C decided, agent-approved, awaiting implementation.
- FestivalPeriod data population (#71): recommended Django data migration with name-based lookups. Removes dependency on arachne MCP (#15). Blocked by #68. lucos_time#76 blocked on #68.
- People modelling (#19): Option C (split by type) agreed. Names deferred. Contact linking owned by lucos_contacts (`eolas_uri` field). Search filtering: revised to `is_contact` boolean (not `source` field) -- simpler for merged records where one person appears in both contacts and eolas. Merge logic in arachne ingestor using `owl:sameAs`; eolas URI used as primary `id` in merged records (revised -- contacts URI would cause mixed-URI tags in media_metadata_api). Open: whether `contact_id` stores full URI or numeric ID. Endpoint rename: `/persons` -> `/people` (lucas42 preference, landed in production).
- Write API (#75): agent-approved, priority:low. `POST /metadata/{type}/`, returns `{id, name, uri}`, 409 for duplicates on unique-name models. Uses existing `@api_auth`. Security note: extract only `name` from request body (no mass assignment).

### lucos_locations
- OwnTracks stack: mosquitto MQTT broker + OwnTracks recorder + custom frontend. 3 containers.
- TLS cert renewal (#4): recommended inotify + SIGHUP hybrid (not full restart). Mosquitto 2.x supports SIGHUP for TLS cert reload (confirmed in docs). inotify reliable on named Docker volumes. Existing `mosquitto-tls` check in `/_info` (20-day threshold) serves as safety net.
- TLS protocol errors (#9): `/_info` health check causes mosquitto log noise. Assigned to SRE.
- Shared `lucos_router_letsencrypt` volume (external) provides TLS certs.

### lucos_docker_health (lucos#45)
- Go binary, push model via schedule_tracker. Deployed to all 3 hosts (avalon, xwing, salvare). ADR-0001 merged.
- Runs as root (distroless base). Non-root impractical: Docker socket GID varies per host (994/985), distroless has no `/etc/group`. Socket access is root-equivalent regardless of UID — distroless (no shell/package manager) is the real security layer.
- Heartbeat healthcheck pattern: `--healthcheck` flag on same binary checks `/tmp/heartbeat` file age. Works on distroless (exec form, no shell). Good pattern for push-only services.
- **Reviewed 2026-04-05** (PR #50). Issues raised: #43 (Dependabot missing gomod), #44 (binary not in .gitignore), #45 (no CodeQL). GitHub reports 2 existing Dependabot vulns (1 high, 1 moderate) confirming #43.
- High implementation churn: 38 issues for ~180 lines. Docker socket permissions needed 3 rounds (#33/#34, #37, #38). Pattern to watch for agent-implemented services.

### lucos_media_metadata_api
- Go + SQLite, multi-value fields (#34): design agreed, tickets #35-#42. Predicate registry (#37) awaiting confirmation.
- 6 multi-value predicates: composer, producer, language, offence, about, mentions. `album` is single-value, RequiresURI.
- v3 ideation (#45): agent-approved, priority:low. API changes decided (trackid->id, debug removal, structured errors, pagination). Data modelling: controlled vocabs, freetext migration, people/groups -- see project-details.md. Sequencing: API changes in v3, data modelling post-v3. Key proposal: extensible tag value objects (`{name, uri}`) so post-v3 migrations are non-breaking. Field name: `name` (agreed). Data sync: belt-and-braces (Loganne webhook + periodic reconciliation). Deletion: Option A (clear URI, keep name) -- all confirmed.
- **Album RDF (#157, 2026-04-11):** type `mo:Record` (not `mo:AlbumRecord` -- avoid LP connotations); skos:prefLabel = name; predicate `<manager>/ontology#onAlbum` declared as `owl:inverseOf mo:track` (track→album direction, arachne `compute_inferences()` materialises inverse). Three places to wire up: `/v3/albums/{id}` conneg, `ExportRDF` extra album walk, `OntologyToRdf` mo:Record metadata + onAlbum/mo:track inverseOf. Knock-on: `lucos_media_metadata_manager` has no per-album route -- vhost.conf needs `^/albums[/$]` rewrite + albums.php conneg-and-redirect mirroring tracks.php (separate issue, hard prereq for arachne#326 webhook path).
- **Album importer (lucos_media_import#118):** upsert pattern -- GET ?q=name + exact-match filter, POST on miss, retry-GET on 409. No name normalisation in importer (data quality is separate concern). Importer is currently broken since #137: predicate `album` RequiresURI but importer sends `[{"name": value}]` only. priority:high for that reason.
- **Latent bug in arachne searchindex.py:166-176** (found while reviewing #326): `graph_to_track_docs` parses `dc:isPartOf` as a search URL -- freetext-era leftover. Since #137, album field on tracks Typesense collection has been silently empty. Fix: lookup album entity prefLabel from same graph using new `onAlbum` predicate. Tracked in arachne#326 alongside album integration work.
