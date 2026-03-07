# Architect Memory

Detailed per-project notes are in `project-details.md`. This file is an index with key facts only.

## lucos_photos

- Architecture: FastAPI API + Python worker + Postgres + Redis, 4 containers
- ADR-0001: pgvector instead of Qdrant (decided #23, implemented #29, both closed)
- Worker-Loganne constraint lifted (#24, closed): worker CAN call Loganne directly. Key learning: question architectural constraints early.
- database.py engine issue (#25) closed, split into #39 (pg_isready retry) and #40 (engine function wrap)
- No docker-compose healthchecks -- reliability gap
- Android backup client (#3): separate repo `lucos_photos_android`
- Photo serving (#26, closed): Option 1 (API serves files directly) confirmed. Stable URLs: `/photos/{id}/original`, `/photos/{id}/thumbnail`.
- Video upload (#60): needs-refining. See `project-details.md`.

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
- Strong one-service-per-repo convention. Naming: `lucos_{subsystem}_{qualifier}`
- Agent instruction compliance ADR: `~/.claude/docs/adr/0001-agent-instruction-compliance.md` in lucos_claude_config. Key practices: extract task lists into short files, explicit counts + completion manifests, dispatcher verification, order by criticality, group by schedule, 200-line max. Originally placed in lucos repo (PR #39, merged then removed), moved to lucos_claude_config as it is specific to agent config.
- lucos_claude_config ADRs live in `~/.claude/docs/adr/`. `.gitignore` updated to allow `docs/` directory. Numbering is independent from lucos repo ADRs.
- User-Agent convention (lucos#19, closed): ADR-0001 in lucas42/lucos (`docs/adr/0001-user-agent-strings-for-inter-system-http-requests.md`). Set User-Agent to `SYSTEM` env var value for all inter-system HTTP requests.

## Auto-merge & security checks

- lucos#42: CodeQL race condition with auto-merge. Recommended Option 1: make CodeQL a required status check. No workflow changes needed -- repo settings only. Check name on lucos_photos: `Analyze (python)`. Must be added to prerequisites checklist when rolling out auto-merge to new repos.

## Infrastructure notes

- `lucos/build-amd64` CI orb builds and pushes Docker images; large images (>1GB) impact build/deploy times
- `depends_on` in compose does not wait for service readiness. Projects with Postgres should have startup retry logic.
- ARM builds use pici (DinD+SSH). Recommended replacing with `docker buildx` + QEMU (pici#9). Decision pending.
- ARM-deployed services: lucos_media_import, lucos_media_linuxplayer, lucos_private, lucos_router, lucos_static_media

## Claude Code setup review (Mar 2026)

- Reviewed `lucos_claude_config`, `lucos_agent`, `lucos_agent_coding_sandbox`. See `project-details.md` for full issue list.
- Overall: well-designed isolation model. Remaining open: token caching (#9), memory path fix (#3), CLAUDE.md restructure (#5), README bot user ID (#5).
- Script consolidation (#11): recommended keeping current 3-repo split. Awaiting lucas42 decision.

## Per-project summaries (details in project-details.md)

### lucos_contacts
- Django app, calendar ICS endpoint. Recommended 1-month lookback (#523), Facebook import as separate repo (#7).

### lucos_media_manager
- Java, long-polling. Flaky test (#79): race condition fix. Device list cleanup (#112): lazy filtering via `lastSeen`.

### lucos_media_metadata_manager
- PHP front-end. Recommended client-side Typesense via arachne (#51). Dedicated `tracks` collection (arachne#47).

### lucos_configy
- Rust API serving YAML config. Single-host-for-domain constraint (#25): recommended Option A (validation test in existing test suite). dns_sync depends on `hosts[0]` -- silent misconfiguration if violated. Option B (schema split host/hosts) deferred.

### lucos_arachne
- nginx + Typesense + Fuseki + Python ingestor. configy#33: recommended closing.
- **ADR-0001 (2026-03-07):** MCP server for knowledge graph access. Container `lucos_arachne_mcp` in arachne stack, routed via nginx at `/mcp/`. Five tools (`search`, `list_types`, `get_entity`, `find_entities`, `count_by_property`). No raw SPARQL — server generates it from typed parameters. Read-only, reasoning endpoint. SSE transport. Implementation: #63-#69.
- **Key insight: LLMs cannot reliably generate SPARQL** against custom ontologies (killed lucos_comhra). MCP server solves this by hiding SPARQL behind structured tool parameters. Fundamental constraint, not a model quality issue.
- Two Fuseki endpoints: `raw_arachne` (read-write) and `arachne` (read-only, OWL reasoning). `systems_to_graphs` in `ingestor/triplestore.py`.
- Agent sandbox has drift problem (lima provisioning vs actual VM state) — prefer Docker containers for iterative development.

### lucos_monitoring
- Erlang OTP, in-memory state, email notifications. `/api/status` endpoint proposed (#26).

### lucos_root
- Static site, Apache. /_info 3-tier schema accepted (lucos#35). Spec doc: `docs/info-endpoint-spec.md` in lucos repo (PR #41). CLAUDE.md updated. Follow-up: monitoring title ticket, per-service compliance tickets.

### lucos_media_seinn
- Node.js music player. Playback sync gap (#14): design posted, awaiting split into tickets.

### lucos_media_linuxplayer
- Node.js + mplayer on ARM. Primary cause of stale position on device switch (#14).

### pici
- DinD CI for ARM. Stale images (#3): proposed `docker system prune` after push.

### lucos_repos
- Greenfield redesign (#22): Go + SQLite, convention auditing. Tickets #23-#30. Audit lifecycle (#30) awaiting approval.
- Convention quality guide (#50): design posted. Key proposal: add `Rationale` and `Guidance` fields to Convention struct so generated issues explain why + how to fix. Awaiting lucas42 decision on scope (docs only vs struct changes).

### lucos_creds
- Go server, AES-GCM. SSH key .env quoting (#61). See `project-details.md`.

### lucos_time
- Node.js, raw http.createServer. `/current-items` (#70): design agreed, ready for implementation.
- Follow-ups: lucos_time#74, lucos_eolas#67, lucos_eolas#68.

### lucos_eolas
- Django, personal metadata/ontology, Postgres. Festival duration (#68): Option C decided, agent-approved, awaiting implementation.
- FestivalPeriod data population (#71): recommended Django data migration with name-based lookups. Removes dependency on arachne MCP (#15). Blocked by #68. lucos_time#76 blocked on #68.

### lucos_media_metadata_api
- Go + SQLite, multi-value fields (#34): design agreed, tickets #35-#42. Predicate registry (#37) awaiting confirmation.
- 6 multi-value predicates: composer, producer, language, offence, about, mentions.
