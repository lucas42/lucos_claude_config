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
- Profile pictures (#149): agent-approved, priority:high. 4 criteria (det_score, frontality, face w/h); smile/hat deferred. Worker generates crops to `/data/photos/derivatives/`. Adds `profile_photo_id`, `profile_auto_generated` to person table. Requires persisting det_score + kps from InsightFace.
- Face reprocessing (#208, merged): preserves `person_confirmed=True` via embedding cosine similarity. Lesson: bounding-box IoU fragile under EXIF orientation; embeddings invariant.
- Face-to-contact linking (#104): design agreed; details in project-details.md. Sequencing depends on contacts JSON API (#529). Names managed in contacts, not photos.

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
- **Bearer auth migration (2026-04-08):** Estate-wide migration from `Authorization: key` to standard `Bearer`. Original case-by-case advice (lucos#37) reversed after arachne#250 outage. 3 phases: server dual-accept → client switch → drop key. Tracking: lucos#74. Per-repo state in project-details.md.
- [Ask about version churn before recommending snapshot mirrors](feedback_churn_rate_before_snapshot.md) — curated stores (GHCR mirror etc.) break under Dependabot-driven tag churn; pull-through caches don't
- [`network_only` in /_info is NOT access control](reference_info_endpoint_network_only.md) — Tier-3 offline-capability hint; never cite as a security boundary
- [Slow-cooker symptoms are a smell](feedback_slow_cooker_symptoms.md) — repeated defensive fixes (timeout bumps, "probably transient", threshold tweaks) on the same component are evidence of an untreated upstream cause
- [Check for a working counter-example first](feedback_check_working_counterexample_first.md) — before concluding a mechanism is universally broken, find a passing case in the estate. One counter-example disproves any "this can never work" claim.
- [Check the ADR before advising on v3 contract](feedback_check_adr_before_advising.md) — on post-ADR APIs, read the ADR and reconcile against earlier issue-thread positions before advising; ADRs may have reversed agreements
- [Check repo history before SSH/transport changes](feedback_check_history_before_proposing_ssh.md) — partial application bites cross-cutting code (multi-site SSH, auth, transport); search closed PRs for prior reverts before designing
- [SPARQL OPTIONAL chains cross-product on labels](feedback_sparql_optional_crossproduct.md) — adding a 2nd label OPTIONAL to a query whose consumer doesn't dedupe rows multiplies rendered values; flag dedup risk in the issue body, not after the regression
- [External access to a LAN host: 3 patterns](reference_external_access_to_lan_host.md) — IPv6+allowlist vs WireGuard tunnel vs ProxyJump; route security review BEFORE recommending public exposure
- [gh api template-substitutes {owner}/{repo} in body text](reference_gh_api_template_substitution.md) — API path placeholders in comment/issue bodies get silently rewritten. Use `--field body=@file` to avoid.
- [configy serialises absent optional fields as explicit null](reference_configy_optional_field_nulls.md) — `dict.get(key, default)` doesn't fall back; use `get(key) or default`. YAML-only tests miss this.
- [Inter-image build deps: single multi-target Dockerfile](reference_buildx_bake_additional_contexts.md) — `target:` scheme is bake-only and breaks compose; use `build.target` + `COPY --from=<stage>`
- [Verify CI mechanism before claiming it gives sequencing](feedback_verify_ci_mechanism_before_relying_on_it.md) — read the orb/.circleci config; "implicit ordering" is a yellow flag, not an answer
- [Reference-implementation defects propagate with confidence amplification](feedback_reference_implementation_propagation.md) — "follow X" copies treat X as already-reviewed; defects in X compound across services (eolas/contacts collectstatic, 2026-04-29)
- [Named Docker volumes shadow image contents indefinitely](reference_named_volume_shadows_image.md) — first-init only; later image updates never refresh; masks build-time defects until volume is removed (eolas/contacts 2026-03-20 + 2026-04-29)
- [Compare channels honestly when proposing instrumentation](feedback_compare_channels_for_instrumentation.md) — don't anchor on Loganne for telemetry; weigh service logs / `/_info` / tracing first. Loganne = cross-estate state changes; service logs = local detail (lucos#126, 2026-05-05)

## Auto-merge & security checks

- lucos#42: CodeQL race condition with auto-merge. Recommended Option 1: make CodeQL a required status check. No workflow changes needed -- repo settings only. Check name on lucos_photos: `Analyze (python)`. Must be added to prerequisites checklist when rolling out auto-merge to new repos.
- Dependabot auto-merge on `pull_request` trigger works fine **if** `LUCOS_CI_APP_ID` and `LUCOS_CI_PRIVATE_KEY` are populated in the repo's Dependabot secret scope (distinct from Actions scope). Previous memory said "must use `pull_request_target`" — that was wrong; `pull_request` is the current working pattern (v1.16.0). See [reference_github_dependabot_secrets.md](reference_github_dependabot_secrets.md). Outdated note in `github-actions-permissions.md` needs a sweep.
- Auto-merge caller workflows require at least `permissions: contents: read` -- `permissions: {}` causes `startup_failure` because GitHub Actions cannot fetch the cross-repo reusable workflow definition without it. Discovered via 2026-03-21 incident.
- `.github` smoke test suite only covers `dependabot-auto-merge`, not `code-reviewer-auto-merge` -- gap tracked in lucos#58.

## Infrastructure notes

- **CI token migration (ADR-0001 in lucos_deploy_orb, PR #90):** Replacing broad-scoped PAT with GitHub App installation token (`lucos-ci` app). Key: must pass `repositories: ["$CIRCLE_PROJECT_REPONAME"]` at token generation to get per-repo scoping — without it, token has access to all repos. New orb command `generate-github-token`. Blocked on lucas42 creating the GitHub App. `Refs #83` (security), also addresses #82 (rate limits).
- CI orb: `build-multiplatform` is the standard for multi-arch services (amd64+arm64 via buildx+QEMU). `build-amd64` still used for amd64-only services. Large images (>1GB) impact build/deploy times.
- `depends_on` in compose does not wait for service readiness. Projects with Postgres should have startup retry logic.
- ARM builds now use `build-multiplatform` orb job (docker buildx + QEMU). pici retired, repo archived (2026-03-17). No more remote SSH builds.
- ARM-deployed services: lucos_media_import, lucos_media_linuxplayer, lucos_private, lucos_router, lucos_static_media
- **Docker volume restore gotcha**: `docker run` with a new volume does NOT apply Docker Compose labels. lucos_backups depends on these labels. Volume restores must use `docker compose` to create the volume first, or manually apply labels. Documented in lucos_backups#64.
- **Bulk deployment waves (2026-03-17 to 2026-03-21, 4 incidents in 5 days):** new failure class from agent automation. Healthcheck failed 3 ways: false-healthy (partial .env, data loss + DB restore, #lucos_deploy_orb#40, #lucos_creds#112), false-unhealthy (load spike, eolas collectstatic + arachne ingestor bulk fetch are CPU hotspots), estate-wide auto-merge break (`permissions: {}` rollout without smoke testing, lucos#58, #59). Systemic lesson: agent execution speed is a liability without verification gates running at the same speed.
- **avalon memory-pressure pattern (2026-04-17):** two independent symptoms in one day -- `lucos_photos_worker` at 1.55 GiB with no limit (photos#316) and `lucos_docker_mirror_web` OOM-ing under parallel CI load. Swap alert firing for 240+ consecutive runs. Treat as systemic: resist greenfield memory-hungry workloads landing on avalon until capacity envelope is re-established. Capacity planning is primarily sysadmin territory.
- **Partial-failure signal ambiguity behind proxies:** when a reverse proxy fronts a content-addressed store (container registry, CAS, git), a mid-stream truncation surfaces upstream as multiple plausible-but-wrong errors (manifest unknown, cache-key precondition, digest mismatch, context deadline). Three-errors-one-cause pattern observed 2026-04-17 on lucos_docker_mirror. Watch for this whenever reviewing a service with proxy + CAS shape.

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
- **ADR-0001 (2026-03-07):** MCP server (`lucos_arachne_mcp`, routed at `/mcp/`) exposes 5 structured tools over the reasoning endpoint. Read-only. Streamable HTTP transport. Shipped 2026-04-07 (#63-#69 all closed). Key insight: LLMs cannot reliably generate SPARQL against custom ontologies (killed lucos_comhra) — MCP hides SPARQL behind typed parameters.
- Two Fuseki endpoints: `raw_arachne` (read-write) and `arachne` (read-only, OWL reasoning). `systems_to_graphs` in `ingestor/triplestore.py`.
- Memory #86: lucas42 reframed -- values inferencing (transitive containedIn), not wedded to Fuseki. Recommended pre-computing closures in ingestor. RDFS reasoner alone insufficient (no owl:TransitiveProperty).
- Monitoring #87: lucas42 wants /_info delegated to explore container with real authenticated checks, not sidecar script. Revised design posted.
- Agent sandbox has drift problem (lima provisioning vs actual VM state) — prefer Docker containers for iterative development.
- **Ingestion strategy (#386, 2026-04-20):** TDB2 tombstones bloated indexes to 93GB vs 227K live quads after 40 days of DROP+INSERT. Compaction recovered 93GB→76MB in 50s (arachne#387). Incident: `lucos/docs/incidents/2026-04-20-arachne-sparql-timeouts-tdb2-index-bloat.md`. Recommended direction: Option 2 (conditional refresh, SHA-256 per source graph) → Option 1 (diff-based SPARQL INSERT/DELETE) → Option 3 (scheduled compaction) as belt-and-braces. Skip Options 4 (incremental inference) and 5 (different engine). Awaiting lucas42 steer; ADR-0002 to follow. Flagged: atomicity of raw→inferred switch, blank-node check, hash state in-triplestore.

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

### lucos_docker_mirror
- Self-hosted Docker Hub pull-through cache (`registry:2` proxy mode) at `docker.l42.eu` on avalon. Replaces earlier GHCR static mirror (ADR-0001, 2026-04-17). Consumed via BuildKit `registry-mirrors` config in the deploy orb -- no per-Dockerfile changes.
- **ADR-0002 (2026-04-17, PR #21 approved):** replace Flask/gunicorn `web` container with stock nginx + small Python `info` sidecar. Motivated by 2026-04-17 incident: sync gunicorn workers SIGABRT on 46-91MB blobs (30s default timeout), then OOM'd under 8 concurrent CI pipelines. Python/Flask is wrong shape for a streaming reverse proxy (`request.get_data()` buffers in memory, `-w 2` caps concurrency at 2, dep surface disproportionate to role). Implementation tracked in #22. Tactical fix (gthread + stream) explicitly rejected as end state but kept as rollback position.
- **Incident 2026-04-17** (`docs/incidents/2026-04-17-docker-mirror-overload-and-orb-publish-bug.md`): orb rollout #118 → `docker tag` after buildx driver broken (need `imagetools create`, fixed orb #120) → parallel re-trigger of 8 pipelines overloaded mirror. 3 distinct error messages (deadline exceeded, manifest unknown, unexpected commit digest) from one cause: mid-stream blob truncation. Follow-up orb #122 (graceful fallback).

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
- **ADR-001 §2 (2026-03-24, Accepted)**: arrays-everywhere wire format -- `map[string][]TagValueV3` for ALL predicates including single-value. Single-value enforced by `len<=1` validation, not scalar typing. **Reversed #34's agreed mixed-type position** (single-value=string, multi-value=array). Rationale: uniform shape enables post-v3 controlled-vocab migration without v4 API. Cost seen in production (#189, 2026-04-24): arrays-everywhere introduces more empty-ish shapes (`null`/`[]`/`[{name:""}]`/`[{name:"",uri:""}]`) -- `trackV3ToInternal` and `updateTagsV3` independently handle empties, caused 153 spurious Loganne events/week. Remediation per #189: reject empty `name` at v3 boundary with 400 (contract fix), plus `updateNeeded` should use `IsMultiValue` to branch between scalar and slice comparison (internal consistency). Do not revert ADR unless similar bug class recurs.
- **Album RDF (#157, 2026-04-11):** type `mo:Record` (not `mo:AlbumRecord` -- avoid LP connotations); skos:prefLabel = name; predicate `<manager>/ontology#onAlbum` declared as `owl:inverseOf mo:track` (track→album direction, arachne `compute_inferences()` materialises inverse). Three places to wire up: `/v3/albums/{id}` conneg, `ExportRDF` extra album walk, `OntologyToRdf` mo:Record metadata + onAlbum/mo:track inverseOf. Knock-on: `lucos_media_metadata_manager` has no per-album route -- vhost.conf needs `^/albums[/$]` rewrite + albums.php conneg-and-redirect mirroring tracks.php (separate issue, hard prereq for arachne#326 webhook path).
- **Album importer (lucos_media_import#118):** upsert pattern -- GET ?q=name + exact-match filter, POST on miss, retry-GET on 409. No name normalisation in importer (data quality is separate concern). Importer is currently broken since #137: predicate `album` RequiresURI but importer sends `[{"name": value}]` only. priority:high for that reason.
- **Latent bug in arachne searchindex.py:166-176** (found while reviewing #326): `graph_to_track_docs` parses `dc:isPartOf` as a search URL -- freetext-era leftover. Since #137, album field on tracks Typesense collection has been silently empty. Fix: lookup album entity prefLabel from same graph using new `onAlbum` predicate. Tracked in arachne#326 alongside album integration work.
