# Architect Memory

Index only — one short line per entry; detail lives in each linked topic file (and per-project depth in `project-details.md`). **Trim before adding if this loads with a truncation warning.**

## Architectural review convention (lucas42/lucos#24)

- Reviews = committed Markdown in `docs/reviews/`, `YYYY-MM-DD-review.md`; separate from ADRs; no summary issues; via PR. Mandatory "Sensitive findings" section. lucos#25 tracks Security Advisory practice.

## Cross-project patterns

- Module-level side effects in shared packages = recurring fragility.
- Auth origin = env-varying `AITHNE_ORIGIN` (aithne#148); `lucos_authentication` decommissioned 2026-06-29.
- Always specify sequencing deps for cross-repo infra changes. lucas42 prefers splitting multi-concern issues.
- **`git fetch` before reviewing EACH repo** (fetch is load-bearing, not checkout); read source from a fresh-origin/main worktree or `git show origin/main:file`, never the shared `~/sandboxes` tree. Refuting-grep on a stale tree is worse than none. Fix in implement-issue Step 4.
- One-service-per-repo; naming `lucos_{subsystem}_{qualifier}`.
- claude_config ADR-0001 (instruction compliance: short task files, counts, manifests, 200-line max); ADR-0002 (agent-teams/SendMessage). Issue-manager merged into team-lead (2026-04-02).
- User-Agent = `SYSTEM` env value for inter-system HTTP (lucos ADR-0001).
- Bearer auth migration (lucos#74): key→Bearer, 3-phase (server dual-accept→client switch→drop key).

## Feedback memories

- [Slow-cooker symptoms are a smell](feedback_slow_cooker_symptoms.md)
- [Check the ADR before advising on v3 contract](feedback_check_adr_before_advising.md)
- [Check repo history before SSH/transport changes](feedback_check_history_before_proposing_ssh.md)
- [SPARQL OPTIONAL chains cross-product on labels](feedback_sparql_optional_crossproduct.md)
- [Sequence labels autolink to unrelated issues](feedback_no_sequence_label_issue_refs.md)
- [Verify a mechanism's properties before designing around them](feedback_verify_ci_mechanism_before_relying_on_it.md)
- [Apply frame-review to your own prior reasoning](feedback_apply_frame_review_to_own_reasoning.md)
- [Implementation surface needs code-trace evidence](feedback_implementation_surface_code_trace.md)
- [Don't spawn teammates as subagents — use SendMessage](feedback_dont_spawn_teammates_as_subagents.md)
- [Scope test-scaffolding assertions against existing code](feedback_test_harness_assertions_reachable.md)
- [Flag-day plans need a verification gate, not just an order](feedback_flag_day_verification_gate.md)
- [Verify the premise, not just the quote](feedback_verify_premise_not_just_quotes.md)
- [File follow-up tickets during design](feedback_file_followups_during_design.md)
- [Don't grep-and-conclude on consumer wiring](feedback_grep_and_conclude_anti_pattern.md)
- [Ready vs startability — unresolved dep = Blocked](feedback_ready_vs_startability.md)
- [Verify path before defensive code](feedback_verify_path_before_defensive_code.md)
- [Don't assume from service name](feedback_dont_assume_from_service_name.md)
- [Design merge/aggregation for ALL consumers](feedback_design_for_all_consumers.md)
- [Pressure-test detectors for the inverse failure mode](feedback_detector_inverse_failure_mode.md)
- [Alertable check must be able to recover](feedback_alertable_check_must_recover.md)
- [Verify past-tense work claims against git](feedback_verify_past_tense_work_claims.md)
- [Re-fetch state before writing it into a final artifact](feedback_refetch_state_before_writing_final_artifact.md)
- [Read the PR, not the description of it](feedback_read_the_pr_not_the_description.md)
- [Don't publish in the same batch as your evidence](feedback_dont_publish_in_same_batch_as_evidence.md)
- [Check special cases before extending a pipeline](feedback_check_special_cases_before_extending_pipeline.md)
- [Qualify cross-repo ADR references](feedback_qualify_cross_repo_adr_refs.md)
- [Commit your own agent-memory for attribution](feedback_commit_own_memory_for_attribution.md)
- [Parse reference data, never hand-build it](feedback_parse_reference_data_never_handbuild.md)
- [Test prescribed values against the rule](feedback_test_prescribed_values_against_rule.md)
- [Check originating decision before forking](feedback_check_originating_decision_before_forking.md)
- [Shared-lib break = testing gap, not version caps](feedback_check_protocol_contract_before_accepting_break.md)
- [Check shared failure domain before a "two-paths" split](feedback_check_shared_failure_domain_before_diagnosing_split.md)
- [Crossed-message thrash: let the decisive event settle it](feedback_crossed_message_thrash_let_decisive_event_settle.md)
- [Defense-in-depth failure reverts to baseline](feedback_defense_in_depth_reverts_to_baseline.md)
- [Route-registration order for auth exemption](feedback_route_registration_order_for_auth_exemption.md)
- [Scope-first, not principal_class; don't accrete ADR complexity](feedback_scope_first_not_principal_class.md)
- [Verify protocol interop, not just feature support](feedback_verify_protocol_interop_not_feature_support.md)
- [Prefer self-healing finding over silent suppression](feedback_prefer_self_healing_finding_over_silent_suppression.md)

## Reference memories

- [`network_only` in /_info is NOT access control](reference_info_endpoint_network_only.md)
- [External access to a LAN host: 3 patterns](reference_external_access_to_lan_host.md)
- [gh api template-substitutes {owner}/{repo} in body text](reference_gh_api_template_substitution.md)
- [Named Docker volumes shadow image contents indefinitely](reference_named_volume_shadows_image.md)
- [Loganne consumer test — name the async consumer first](reference_loganne_consumer_test.md)
- [Media-ecosystem URI namespace (ADR-0005)](reference_media_ecosystem_uri_namespace.md)
- [Webhook consumer accept-202-enqueue (ADR-0006)](reference_webhook_consumer_accept_202_enqueue.md)
- [Service-worker-backed UI is a system component](reference_service_worker_ui_as_system_component.md)
- [Encryption-at-rest ≠ ransomware defence](reference_encryption_at_rest_vs_ransomware.md)
- [Quiesce-during-read backup pattern](reference_quiesce_during_read_backup.md)
- [navbar keepalive vs consumer service workers](reference_navbar_keepalive_sw_interception.md)
- [Convention catalogue + enforced-vs-guidance boundary](reference_convention_catalogue.md)
- [lucos_creds deploy reads CI snapshot, not live store](reference_lucos_creds_deploy_snapshot.md)
- [GitHub code search is lossy for estate sweeps](reference_github_codesearch_lossy_for_sweeps.md)
- [Test environments in lucos_creds (ADR-0002)](reference_creds_test_environments.md)
- [Deployment model has no on-host source of truth](reference_no_onhost_source_of_truth.md)
- [Docker Healthy ≠ reachability — recurring estate pattern](reference_docker_healthy_not_reachability.md)
- [Reconcile empty-source guard](reference_reconcile_empty_source_guard.md)
- [auth_scopes vocabulary design](reference_auth_scopes_vocabulary.md)
- [creds key value and scope are independent](reference_creds_scope_keyvalue_independent.md)
- [aithne `next=` must be a full URL, not a path](reference_aithne_next_param_full_url.md)
- [calc-version semver + dependabot gap](reference_calcversion_semver_dependabot_gap.md)
- [scratch vs distroless/static + CA bundle](reference_scratch_vs_distroless_ca_bundle.md)
- [BookStack OIDC is https-only (breaks local-dev worlds login)](reference_bookstack_oidc_https_only.md)
- [Firewall DOCKER-USER polices inter-container traffic](reference_firewall_dockeruser_scope.md)
- [/_info fetch mechanics + adopted-app shim pattern](reference_info_fetch_and_shim_pattern.md)

## Project memories

- [lucos_aithne auth design](project_machine_principal_sessions.md) — ADR-0001 MERGED 2026-06-09; Go, aithne.l42.eu; OIDC OP + passkeys + local-JWKS; mints NO identities; scope-GRANT crown jewel
- [aithne migration guide](project_aithne_migration_guide.md) — ADR-0003 + guide MERGED; deferred impl aithne#181 + navbar#174
- [File uploader](project_file_uploader.md) — lucos#209 PARKED; ADR-0013 draft CLOSED; revive as ADR-0001 in a new repo
- [Google Photos migration](project_photos_google_migration.md) — lucos_photos#424 plan finalised; #425/#427/#426 + backups#318 blocker
- [DNS secondary modelling](project_dns_secondary_modelling.md) — two-systems-one-repo; ADR lucos#213; on hold
- [C4 estate model](project_c4_estate_model.md) — lucos_repos ADR-0006 draft PR #423; typed-by-source, divergence-as-audit
- [lucos_worlds](project_lucos_worlds.md) — ADOPT BookStack (2026-07-07), types-as-tags, aithne OIDC; ADR-0001 draft PR lucos_worlds#1; follow-ups #2-#6
- [Artist modelling](project_artist_modelling_decision.md) — Artist as `mo:MusicArtist` in media_api
- [Auto-merge approval policy](project_auto_merge_approval_policy.md) — lucos ADR-0013 Accepted; configy `additionalReviewers`, workflow-enforced, fail-closed
- [loganne event level](project_loganne_event_level.md) — per-event `level` (#506), named ordinal scale, awaiting taxonomy sign-off

## Auto-merge & security checks

- lucos#42: CodeQL race — make CodeQL a required status check (repo settings). lucos_photos check name `Analyze (python)`.
- Dependabot auto-merge needs `LUCOS_CI_APP_ID`/`LUCOS_CI_PRIVATE_KEY` in the Dependabot secret scope. See [reference_github_dependabot_secrets.md](reference_github_dependabot_secrets.md).
- Auto-merge caller workflows need ≥ `permissions: contents: read` (`{}` = startup_failure).
- `.github` smoke tests cover `dependabot-auto-merge` only, not `code-reviewer-auto-merge` (gap lucos#58).

## Infrastructure notes

- CI token migration (lucos_deploy_orb ADR-0001): PAT→App token `lucos-ci`; MUST pass `repositories:["$CIRCLE_PROJECT_REPONAME"]`.
- CI orb: `build-multiplatform` (amd64+arm64), `build-amd64` (amd64-only).
- `depends_on` does NOT wait for readiness; Postgres/DB consumers need startup retry.
- ARM-deployed: media_import, media_linuxplayer, private, router, static_media.
- Volume restore gotcha: `docker run` new volume skips compose labels — use `docker compose` or apply labels (backups#64).
- Bulk-deploy waves (Mar 2026): agent execution speed is a liability without verification gates at the same speed.
- avalon memory pressure (photos_worker + docker_mirror OOM) — resist greenfield memory-hungry workloads there.

## Per-project pointers (depth in project-details.md)

- **lucos_photos** — FastAPI+worker+Postgres+Redis. ADR-0001 pgvector. Face→contact #104 needs contacts #529.
- **lucos_contacts** — Django. JSON API #529. Relationship deletion #53 → ADR-0001/0002.
- **lucos_arachne** — nginx+Typesense+Fuseki+Python ingestor. Webhook-driven. Fuseki `raw_arachne`(RW)+`arachne`(RO); inference in ingestor. Merge: search-index #539 done, item-page #567, sameAs #566 open.
- **lucos_eolas** — Django. Canonical cross-domain metadata; write API shipped. ADR-0001 established `docs/adr/`.
- **lucos_media_metadata_api** — Go+SQLite. v3 shipped; arrays-everywhere wire format. Album=`mo:Record`. arachne#326 latent bug.
- **lucos_media_manager** (ceol.l42.eu) — Java long-polling. NOT media_metadata_manager.
- **lucos_media_metadata_manager** — PHP front-end. Client-side Typesense via arachne (#51).
- **lucos_media_weightings** — Python cron. Multiplier soft cap 100 (#39).
- **lucos_media_seinn** — Node.js player. Playback sync #14.
- **lucos_media_linuxplayer** — Node.js+mplayer on ARM. Stale-position on device switch.
- **lucos_configy** — Rust API. Single-host-for-domain (#25) Option A.
- **lucos_monitoring** — Erlang OTP. Flappiness #74 CLOSED; no open warning-tier issue — don't cite #74 for that.
- **lucos_root** — Static+Apache. /_info 3-tier schema (lucos#35).
- **lucos_repos** — Go+SQLite convention auditing. ADR-0003 dry-run sweep; ADR-0004 auto-close audit issues.
- **lucas42/.github** — Reusable workflows. Dependabot SHA pinning #34; tag versioning #35; smoke gate #38.
- **lucos_creds** — Go AES-GCM. CLIENT_KEYS automated from linked creds. Scoped perms #87.
- **lucos_loganne** — Node.js, static webhook config. Auth migration #374 (per-consumer linked creds).
- **lucos_time** — Node.js. `/current-items` #70; `commemorates` predicate.
- **lucos_locations** — OwnTracks (mosquitto+recorder+frontend). TLS reload inotify+SIGHUP #4.
- **lucos_docker_mirror** — Pull-through cache docker.l42.eu on avalon. ADR-0001/0002. Incident 2026-04-17.
- **lucos_docker_health** (lucos#45) — Go distroless, heartbeat healthcheck. Runs as root (socket=root-equiv).
