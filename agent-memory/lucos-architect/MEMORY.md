# Architect Memory

Detailed per-project notes are in `project-details.md`. This file is an index with key facts only — keep entries to one line under ~200 chars; move detail into topic files. **Trim trigger:** if this file loads with a truncation warning, trim BEFORE saving any new memory in the session.

## Architectural review convention (agreed -- lucas42/lucos#24)

- Reviews: committed Markdown in `docs/reviews/`, filename `YYYY-MM-DD-review.md`; separate from ADRs; do NOT file summary issues; submit via PR
- Mandatory "Sensitive findings" section (link to Security Advisory or "None"); CLAUDE.md should point at `docs/reviews/`
- lucas42/lucos#25 tracks GitHub Security Advisory practice

## Cross-project patterns

- Module-level side effects in shared packages are a recurring fragility pattern
- Auth domain hardcoded as `https://auth.l42.eu` -- prefer in application code, not compose env var
- Always specify sequencing dependencies for cross-repo infrastructure changes
- lucas42 prefers splitting multi-concern issues into separate tickets
- **Always check `origin/HEAD` before reviewing code.** Sandbox copies may be stale. If lucas42 mentions a change not reflected in the code, `git fetch && git checkout origin/main`.
- Strong one-service-per-repo convention. Naming: `lucos_{subsystem}_{qualifier}`
- ADR-0001 (claude_config): agent instruction compliance. Extract task lists into short files, explicit counts + completion manifests, dispatcher verification, order by criticality, 200-line max.
- ADR-0002 (claude_config #14): Agent teams migration. SendMessage replaces Task subagent dispatch. Identity via persona instructions.
- Issue-manager merged into team-lead (claude_config#27, 2026-04-02): coordinator-persona loaded via /team skill. lucos-issue-manager GitHub App identity retained for API calls.
- User-Agent convention (lucos ADR-0001): Set User-Agent to `SYSTEM` env var value for all inter-system HTTP requests.
- **Bearer auth migration (lucos#74, 2026-04-08):** Estate-wide migration from `Authorization: key` to `Bearer`. 3 phases: server dual-accept → client switch → drop key. Per-repo state in project-details.md.

## Feedback memories (each links to its own file)

- [Ask about version churn before recommending snapshot mirrors](feedback_churn_rate_before_snapshot.md)
- [Slow-cooker symptoms are a smell](feedback_slow_cooker_symptoms.md) — repeated defensive fixes are evidence of an untreated upstream cause
- [Check for a working counter-example first](feedback_check_working_counterexample_first.md)
- [Check the ADR before advising on v3 contract](feedback_check_adr_before_advising.md)
- [Check repo history before SSH/transport changes](feedback_check_history_before_proposing_ssh.md)
- [SPARQL OPTIONAL chains cross-product on labels](feedback_sparql_optional_crossproduct.md)
- [Sequence labels in multi-issue series autolink to real unrelated issues](feedback_no_sequence_label_issue_refs.md)
- [Verify CI mechanism before claiming it gives sequencing](feedback_verify_ci_mechanism_before_relying_on_it.md)
- [Reference-implementation defects propagate with confidence amplification](feedback_reference_implementation_propagation.md)
- [Compare channels honestly when proposing instrumentation](feedback_compare_channels_for_instrumentation.md) — don't anchor on Loganne
- [Apply frame-review to your own prior reasoning](feedback_apply_frame_review_to_own_reasoning.md)
- [Don't remove implicit feedback without explicit replacements](reference_implicit_feedback_replacement.md)
- [Pressure-test decision thresholds for reachability](feedback_decision_threshold_calibration.md)
- [Don't introduce asserted/inferred class distinctions for user-facing facts](feedback_dont_split_user_facing_facts.md)
- [Implementation surface needs code-trace evidence](feedback_implementation_surface_code_trace.md)
- [Check both sides of a replaced mechanism](feedback_check_both_sides_of_replaced_mechanism.md)
- [Simplify before elaborate in multi-round threads](feedback_simplify_before_elaborate_in_multi_round.md)
- [Don't spawn teammates as subagents](feedback_dont_spawn_teammates_as_subagents.md) — use SendMessage, never Agent
- [Test-scaffolding issues must scope assertions against existing code](feedback_test_harness_assertions_reachable.md)
- [Do the mechanical check before publishing](feedback_mechanical_check_before_publishing.md)
- [Breaking change when callers must change anyway](feedback_breaking_change_when_callers_must_change_anyway.md)
- [Flag-day plans need a verification gate, not just an order](feedback_flag_day_verification_gate.md)
- [Verify the premise, not just the quote](feedback_verify_premise_not_just_quotes.md)
- [Shutdown protocol: send shutdown_response via SendMessage](feedback_shutdown_no_tool_calls.md)
- [Convention scope = failure mode scope](feedback_convention_scope_failure_mode.md)
- [File follow-up tickets during design](feedback_file_followups_during_design.md) — lucas42 doesn't trust us to remember later
- [Data-driven over code rules for federation-layer priority](feedback_data_driven_over_code_rules.md)
- [Don't grep-and-conclude on consumer wiring](feedback_grep_and_conclude_anti_pattern.md)
- [Ready vs startability](feedback_ready_vs_startability.md) — unresolved dependency = Blocked
- [Question the option list](feedback_question_the_option_list.md)
- [Verify frequency claims against data](feedback_verify_frequency_claims_against_data.md)
- [Check value when fix complexity grows](feedback_check_value_when_fix_complexity_grows.md)
- [No vague-aesthetic hedging](feedback_vague_aesthetic_hedging.md)
- [Verify path before defensive code](feedback_verify_path_before_defensive_code.md)
- [Don't assume from service name](feedback_dont_assume_from_service_name.md)
- [Design merge/aggregation layers for all consumers, not just the originating one](feedback_design_for_all_consumers.md) — arachne#539 scoped to search-index only; explorer item page was a missed consumer (arachne#566+#567, 2026-05-22)
- [Pressure-test detectors for the inverse failure mode](feedback_detector_inverse_failure_mode.md) — happy-path success counter + swallowing catch = structurally blind to operation-throwing (seinn#470, 2026-05-22)

## Reference memories

- [`network_only` in /_info is NOT access control](reference_info_endpoint_network_only.md)
- [External access to a LAN host: 3 patterns](reference_external_access_to_lan_host.md)
- [gh api template-substitutes {owner}/{repo} in body text](reference_gh_api_template_substitution.md)
- [configy serialises absent optional fields as explicit null](reference_configy_optional_field_nulls.md)
- [Inter-image build deps: single multi-target Dockerfile](reference_buildx_bake_additional_contexts.md)
- [Named Docker volumes shadow image contents indefinitely](reference_named_volume_shadows_image.md)
- [Loganne consumer test](reference_loganne_consumer_test.md) — name the async consumer before recommending a new event
- [lucos_schedule_tracker_pythonclient scope](reference_schedule_tracker_pythonclient_scope.md)
- [Indexability by exclusion vs inclusion](reference_indexability_exclusion_vs_inclusion.md)
- [Media-ecosystem URI namespace (ADR-0005)](reference_media_ecosystem_uri_namespace.md)
- [Webhook consumer accept-202-enqueue (ADR-0006)](reference_webhook_consumer_accept_202_enqueue.md)
- [Service-worker-backed UI is a system component](reference_service_worker_ui_as_system_component.md)
- [Escape-hatch design pattern](reference_escape_hatch_design_pattern.md)
- [lucos_creds deploy reads CI snapshot, not live store](reference_lucos_creds_deploy_snapshot.md)
- [Dependabot security updates are independent of dependabot.yml schedule](reference_dependabot_security_vs_version_feeds.md)

## Project memories

- [Artist modelling decision](project_artist_modelling_decision.md) — Artist as `mo:MusicArtist` in media_api alongside Album

## Auto-merge & security checks

- lucos#42: CodeQL race with auto-merge. Make CodeQL a required status check (repo settings only). Check name on lucos_photos: `Analyze (python)`. Required for new auto-merge rollouts.
- Dependabot auto-merge on `pull_request` works **if** `LUCOS_CI_APP_ID`/`LUCOS_CI_PRIVATE_KEY` are in the Dependabot secret scope (separate from Actions scope). See [reference_github_dependabot_secrets.md](reference_github_dependabot_secrets.md).
- Auto-merge caller workflows need ≥ `permissions: contents: read` (`{}` causes `startup_failure`). Discovered 2026-03-21 incident.
- `.github` smoke-test suite covers `dependabot-auto-merge` only, not `code-reviewer-auto-merge` — gap tracked in lucos#58.

## Infrastructure notes

- **CI token migration (lucos_deploy_orb ADR-0001, PR #90):** broad PAT → GitHub App installation token (`lucos-ci`). MUST pass `repositories:["$CIRCLE_PROJECT_REPONAME"]` for per-repo scoping. Blocked on lucas42 creating App.
- CI orb: `build-multiplatform` for amd64+arm64 (buildx+QEMU); `build-amd64` for amd64-only. pici retired 2026-03-17.
- `depends_on` in compose does NOT wait for readiness; Postgres consumers need startup retry.
- ARM-deployed: lucos_media_import, lucos_media_linuxplayer, lucos_private, lucos_router, lucos_static_media
- **Docker volume restore gotcha**: `docker run` with new volume doesn't apply compose labels (lucos_backups needs them). Use `docker compose` to create volume, or apply labels manually. lucos_backups#64.
- **Bulk deployment waves (2026-03-17 to 2026-03-21):** 4 incidents in 5 days. New failure class from agent automation. Healthcheck false-healthy, false-unhealthy, estate-wide auto-merge break. Systemic lesson: agent execution speed is a liability without verification gates running at the same speed.
- **avalon memory-pressure pattern (2026-04-17):** photos_worker 1.55GiB no limit + docker_mirror OOM under parallel CI. Resist greenfield memory-hungry workloads on avalon until capacity re-established. Sysadmin territory.
- **Partial-failure signal ambiguity behind proxies:** mid-stream truncation surfaces as multiple plausible-but-wrong errors (manifest unknown, cache precondition, digest mismatch). Three-errors-one-cause on lucos_docker_mirror 2026-04-17.

## Per-project pointers (depth in project-details.md)

- **lucos_photos** — FastAPI+worker+Postgres+Redis. ADR-0001 (pgvector). Profile pics #149. Face-to-contact linking #104 depends on contacts JSON API #529.
- **lucos_contacts** — Django. JSON API filed as #529. Relationship deletion #53 → ADR-0001/0002, ongoing tickets #699-#713.
- **lucos_arachne** — nginx + Typesense + Fuseki + Python ingestor. Webhook-driven (event-name suffix). ADR-0001 (MCP). Two Fuseki endpoints: `raw_arachne` (RW) + `arachne` (RO). Inference in ingestor, not Fuseki. People merge in search-index layer (#539); item-page merge open in #567; sameAs symmetry materialisation open in #566.
- **lucos_eolas** — Django. People modelling #19 design closed. Write API #75 agent-approved priority:low.
- **lucos_media_metadata_api** — Go+SQLite. v3 shipped. ADR-001 §2: arrays-everywhere wire format. Album as `mo:Record` (#157). Person-tag migration in #237. Latent bug in arachne searchindex.py (album field empty since #137) tracked in arachne#326.
- **lucos_media_manager** (ceol.l42.eu) — Java long-polling. **Not** lucos_media_metadata_manager.
- **lucos_media_metadata_manager** — PHP front-end. Client-side Typesense via arachne (#51).
- **lucos_media_weightings** — Python cron. Multiplier soft cap = 100 (#39).
- **lucos_media_seinn** — Node.js player. Playback sync #14.
- **lucos_media_linuxplayer** — Node.js + mplayer on ARM. Primary cause of stale-position on device switch.
- **lucos_configy** — Rust API. Single-host-for-domain (#25) Option A.
- **lucos_monitoring** — Erlang OTP. Flappiness threshold #74 awaiting lucas42 decision (per-check `failThreshold` in /_info).
- **lucos_root** — Static+Apache. /_info 3-tier schema accepted (lucos#35).
- **lucos_repos** — Go+SQLite, convention auditing. Greenfield #22. Blast radius #159 → ADR-0003 dry-run sweep. ADR-0004 auto-close audit-finding issues (#248, PR #251 merged).
- **lucas42/.github** — Reusable workflow repo. Dependabot auto-merge SHA pinning issue (#34). Tag-based versioning (#35), smoke test gate (#38).
- **lucos_creds** — Go AES-GCM. CLIENT_KEYS fully automated from linked credentials. Scoped permissions (#87) approved.
- **lucos_loganne** — Node.js, static webhook config. Auth migration #374 (per-consumer linked creds, 3-phase).
- **lucos_time** — Node.js. `/current-items` #70. `commemorates` predicate for festivals (2026-03-05).
- **lucos_locations** — OwnTracks (mosquitto + recorder + frontend). TLS reload via inotify+SIGHUP (#4).
- **lucos_docker_mirror** — Self-hosted pull-through cache at docker.l42.eu on avalon. ADR-0001 (replaces GHCR static). ADR-0002 (Flask→nginx). Incident 2026-04-17 documented.
- **lucos_docker_health** (lucos#45) — Go, distroless, push via schedule_tracker. Heartbeat healthcheck pattern. Runs as root (socket access is root-equiv regardless of UID).
- **Claude Code setup review (Mar 2026)** — claude_config, lucos_agent, sandbox. Well-designed isolation. Open: token caching, memory path, CLAUDE.md restructure.
