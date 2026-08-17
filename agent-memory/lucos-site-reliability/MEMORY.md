# SRE Agent Memory

Index only — detail in linked file. Verify ticket state before citing.

## Consolidated topic files (read first — bulk knowledge)
- [Per-repo known issues + host facts + hostname→repo](topic_per_repo_known_issues.md) — all repos' quirks/open tickets; xwing…
- [CI + infra patterns](topic_ci_infra_patterns.md) — deploy_orb, docker_mirror, DOCKER_HOST=ssh…
- [Monitoring mechanics](topic_monitoring_mechanics.md) — poll interval=60s (not 10s); post-restart…
- [⛔ RESOLVED / benign — 14 patterns](topic_resolved_historical.md) — fixed at source, closed, or self-resolving.

## aithne / auth
- [PWA SW render drops aithne_origin → re-login storm](pattern_pwa_sw_render_drops_aithne_origin.md) — router log `/auth/login` vs render.
- [eolas dual auth: static-key vs JWT middleware](pattern_eolas_dual_auth_static_key_vs_jwt_middleware.md) — "Not enough segments" log never blocks.
- [contacts returns 403 (not 401) for an unrecognised key](pattern_contacts_403_for_unrecognised_key.md) — read server's live CLIENT_KEYS.
- [Scope-cutover convergence + holder-enumeration gap](pattern_scope_cutover_convergence_and_enumeration_gap.md) — verify via router access log.
- [aithne signing_key_age is NOT a deploy signal](pattern_aithne_signing_key_age_not_deploy_signal.md) — key persists across restarts.
- [aithne KEK breaking-migration deploy race + recovery gotchas](pattern_aithne_kek_migration_deploy_race.md) — 2026-06-30 46min outage.
- [aithne contact id: string (principal) vs int (contacts proxy)](pattern_aithne_contactid_string_vs_int_divergence.md) — JS cross-ref MUST String()-coerce.
- [Scratch Go image has no CA bundle → x509 unknown authority on outbound](pattern_scratch_image_no_ca_bundle.md) — latent until first outbound HTTPS.

## lucos-search / eolas / arachne
- [lucos-search option value = eolas person URI even in contact mode](pattern_lucos_search_emits_eolas_uri_not_contacts.md) — reverse-map.
- [arachne has TWO eolas ingest paths; hyphenated pks fail webhook path](pattern_arachne_eolas_dual_ingest_hyphen_pk.md) — pk regex `\w+` excludes hyphens.
- [media_metadata → /v2/export → arachne pipeline landmines](pattern_media_metadata_arachne_pipeline.md) — torn export wipes tracks.
- [arachne multi-component CI dep-skew + #633 regression](project_arachne_multicomponent_ci_depskew.md) — one pip resolve across components.
- [Misleading "502 could not reach X" = DECODE failure of a 200 upstream](pattern_misleading_502_decode_not_unreachable.md) — test upstream directly.

## Backups
- [DB-specific backups walked back → engine-agnostic quiesce](project_backups_db_consistency_walkback.md) — docker pause owner around read.
- [recreate_effort vs skip_backup: INDEPENDENT, never infer](reference_recreate_effort_vs_skip_backup_semantics.md) — INDEPENDENT.
- [Backups localhost:8027 reset, 127.0.0.1 ok = enable_ipv6 mismatch](pattern_backups_sshadd_gates_server_start.md) — test 127.0.0.1 AND localhost AND [::1].
- [aurora access + rsync facts](reference_aurora_access_and_rsync.md) — no direct SSH; route via container…
- [host-tracking "<host>: 'low'" = invalid recreate_effort in configy](pattern_backups_invalid_effort_crashes_host_tracking.md) — fix the configy value.
- [#311 rsync runs on the SOURCE HOST via Fabric](pattern_backups_rsync_binary_missing_from_image.md) — check `which rsync` on the HOST.

## Router / DNS / firewall
- [New service TLS check failing = router hasn't issued cert yet](pattern_router_newdomain_cert_latency.md) — startup + daily 22:16.
- [router has TWO cert-renewal paths](pattern_router_dual_cert_renewal_paths.md) — configy certonly + stock certbot renew…
- [All l42.eu SERVFAIL = apex zone failed to load on avalon](pattern_l42_dns_apex_zone_outage.md) — dig SOA @avalon.
- [avalon enable_ipv6 bridges reach global IPv6 via NAT66; monitoring/time IPv4-only](reference_avalon_ipv6_bridging.md) — enable_ipv6 per-network.
- [Duplicate `fd00:*::/64` blocks network recreate → service left with NO container](pattern_duplicate_ula_subnet_blocks_network_recreate.md) — "Pool overlaps"; check before deleting any net.
- [Compose silently REUSES a stale network](compose-reuses-stale-network.md) — inspect live net, not compose; network…

## Dev wiring / creds
- [Dev cross-service wiring + stale-.env 403 trap](pattern_dev_cross_service_wiring.md) — *_ORIGIN=host.docker.internal; diff local…
- [commit-claude-main for ~/.claude; ⚠️`git status` LIES](feedback_commit_claude_main_for_dotclaude.md) — verify `git diff origin/main`.
- [lucos_creds reads .env from CircleCI snapshot, not live store](reference_lucos_creds_self_deploy.md) — check snapshot on "fix didn't take".
- [Corrupted multi-line secrets in containers](pattern_multiline_secret_truncated_at_first_line.md) — docker-inspect shows only FIRST line.
- [Three-stage env-var wiring required](pattern_three_stage_env_var_wiring.md) — code read + compose passthrough + creds value.
- [Walk the env-var chain before naming the gap](feedback_walk_env_chain_before_concluding.md) — usually link 3 (compose).

## Monitoring
- [New service: monitoring REBUILD vs root RUNTIME](pattern_surfacing_new_service_monitoring_vs_root.md) — monitoring bakes at build.
- [monitoring API uses `status` field not `ok`](pattern_monitoring_api_status_field.md) — use `summary` for counts.
- [Estate circleci storm = CircleCI outage tripping UnknownsGate](pattern_circleci_unknownsgate_estate_storm.md) — #279 DONE; a rerun fakes recovery.
- [fetch-info needs http_port; non-HTTP via schedule_tracker](pattern_monitoring_coverage_http_vs_scheduled.md) — use full /systems.
- [schedule-tracker semantics: red needs N CONSECUTIVE fails](reference_schedule_tracker_detection_semantics.md) — ⚠️FALSE-RECOVERY: nulls last_success (#96).
- [Monitoring history from loganne, NOT /api/status](feedback_monitoring_history_from_loganne_not_snapshots.md) — snapshots lie about duration.
- [⚠️ schedule_tracker_db loss PERMANENTLY forgets stopped jobs](pattern_schedule_tracker_db_loss_forgets_stopped_jobs.md) — NEVER wipe. ⛔ `automatic` STAYS.
- [Media cross-probe flap in rollout = LEGIT 401](pattern_deploy_window_boundary_crossprobe_flap.md) — alerts CORRECT.
- [dependsOn suppresses ONLY during deploy windows](pattern_dependson_deploy_window_only.md) — [TWO read sites](pattern_dependson_two_read_sites.md).
- [red-means-down: no ack/known-issue state](feedback_red_means_down_no_ack_state.md) — [`/suppress`=deploy window only](pattern_monitoring_suppress_is_deploy_window_only.md).
- [Repeated alerts for SAME failing check = one re-alert per deploy](pattern_monitoring_realert_per_deploy.md) — not flapping.
- [Don't accept flaps as "expected"](feedback_no_flap_tolerance.md) — fix via dependsOn/failThreshold/window or…
- [/_info in-band 1s dep probe > monitoring's 1s poll timeout](pattern_info_inband_dependency_probe_exceeds_poll_timeout.md) — healthy service reports itself unreachable; alerts on WRONG service first.
- [monitoring self-poll blocks on its OWN mailbox burst](pattern_monitoring_selfpoll_mailbox_burst.md) — ⚠️5% duty cycle defeats slow probes; erl_call recipe; router-vhost attribution.
- [Checks AND thresholds live in /_info, not lucos_monitoring](feedback_failthreshold_lives_in_info.md) — monitoring is aggregation only.
- [/_info = availability/config, NOT content correctness](pattern_info_endpoint_boundary.md) — ⚠️REOPENED (lucos#273); boot+curl /_info goes GREEN through outages.

## Scheduled-job / service failures
- [media_import new_files.py: unguarded loop, 1 bad file kills scan](pattern_new_files_unguarded_loop_poison_file.md) — looks like "dirs don't import"; misses PERMANENT.
- [Hung Python: py-spy/gdb ABSENT on prod](pattern_hung_python_process_no_pyspy_use_faulthandler.md) — pre-armed faulthandler+SIGUSR1.
- [RQ `with_scheduler=False` silently loses retries](pattern_rq_scheduler_disabled_silently_drops_retries.md) — `ZCARD rq:scheduled:*`.
- [loganne client `level` now REQUIRED positional arg](pattern_loganne_client_level_required_arg.md) — missing → TypeError.
- [reconcile_tag_names silent-success masking](pattern_reconcile_silent_success_masking.md) — reports success on total eolas-fetch…
- [uri-integrity flaps = intentional requiresURI migrations](pattern_media_metadata_uri_integrity_requiresuri_migration.md) — not a bug.
- [⚠️locations `location-freshness` UNTRUSTWORTHY (#105)](pattern_locations_silent_data_gap.md) — verify vs `.rec` created_at (#105).
- [Python stdout block-buffered → print() lost](pattern_python_stdout_buffered_swallows_diagnostics.md) — stderr fine.
- [locations /map 500, /_info green = oauth2_proxy crash-loop](pattern_locations_oauth2proxy_sidecar_crashloop.md) — fix is lucas42-only.

## CI / build / deploy
- [python:3.15.0b2-alpine bump breaks psycopg/libpq](pattern_python_beta_alpine_libpq_break.md) — fix `apk add libpq`; not a flake.
- [Auto-merged base-image bump breaks at runtime not build](pattern_baseimage_bump_runtime_break.md) — ⚠️4x; can lie LATENT 11d; `rc` safer than `a`/`b`; rerun≠rollback. lucos#273.
- [exit 127 after pip install = machine image rolled BACK](pattern_rolling_machine_image_tag_moves_backwards.md) — fix w/ venv not a pin.
- [lucos_repos deploy auto-triggers an audit sweep](pattern_lucos_repos_deploy_triggers_sweep.md) — recovery ~17-18min.
- [repos audit reds: we discard GitHub's Retry-After](pattern_ratelimit_maxwait_ceiling_reds_background_jobs.md) — #462 dry-run fixed.
- [GitHub Actions outage: check status page early](pattern_github_actions_outage_diagnosis.md) — estate latest-run sweep; ⚠️never relax branch protection to unstick.
- [Checks that NEVER fired = CircleCI 400'd the webhook](pattern_circleci_400_webhook_drops_pr.md) — hooks/{id}/deliveries.

## Estate topology / docker
- [Repo name ≠ container name (_ui/_mcp/_explore)](pattern_repo_name_not_container_name.md) — creds_ui not creds.
- [live-restore:true skips network init](pattern_docker_live_restore_skips_network_init.md) — stop all containers → restart daemon →…
- [named volume shadows image contents at mount path](pattern_named_volume_shadows_image.md) — first-init-only semantics.

## Diagnostic methodology
- [`UND_ERR_CONNECT_TIMEOUT` @~510ms = Happy Eyeballs, not a dead server](pattern_happy_eyeballs_amplifies_syn_loss.md) — 8x amplifier; SYN loss fingerprint 1.03s/3.06s; ICMP filtered to xwing.
- [Orphaned agent `ssh "… &"` job spun at 100% CPU for 108 days](pattern_orphaned_ssh_background_job.md) — nothing alerts on host CPU; check `ps --sort=-%cpu` on every visit.
- [A guard keyed on a symptom is absent during incidents](pattern_guard_keyed_on_symptom_absent_during_incident.md) — correlate trigger vs incident window.
- [Container restart clears docker logs → false "onset"](pattern_container_restart_log_buffer_artifact.md) — check StartedAt + full status distribution…
- [Bare "aborted due to timeout"? Probe discarded the number](pattern_probe_measures_then_discards_latency.md) — read source.
- [Sandbox checkouts lie 2 ways: stale AND on a feature branch](pattern_stale_sandbox_checkouts.md) — `git pull` won't fix branch; name `origin/main`.
- [Access-log first for webhook-error-rate bursts](pattern_access_log_first_for_webhook_bursts.md) — pull router nginx log before theorising.
- [Router gap analysis: stalled vs slow vs host](pattern_router_log_gap_analysis.md) — ⚠️avalon's router only logs ITS vhosts; run a positive control.
- Causation discipline: [coincidence is not the default framing](feedback_avoid_coincidence_default.md) · [correlation is not "confirmed"](feedback_correlation_is_not_confirmed.md) — add distinguishing instrumentation · [reproduce before publishing a root cause](feedback_verify_root_cause_by_reproduction.md).
- [Verify claims; write falsifiably](feedback_verify_check_claim_against_underlying_store.md) — read the artefact, not its name; scrutinise agreement.
- [A working-state file is NOT a history](feedback_verify_state_file_semantics_before_reading_history.md) — checkpoints self-delete on success; use schedule-tracker.
- [Don't infer a FIX's mechanism from the BUG's](feedback_dont_infer_fix_mechanism_from_bug_mechanism.md) — read the diff before claiming coverage limits.
- [flat-or-shrink targets DUPLICATE rules, not wrong ones](feedback_consolidation_rule_scope.md) — a misleading rule may GROW.
- [Diagnose through to root cause when next step is more diagnostics](feedback_diagnose_through_to_root_cause.md) — park only for genuine developer-side work.
- [Check user-agent first when hunting a misbehaving HTTP client](feedback_check_user_agent_first.md) — read receiver access-log UA before…
- [Check file reachability from entry point before "deployed code misbehaves"](feedback_check_reachability_first.md) — bundlers drop unreachable code.
- [Narrow the event window before counting categories](feedback_narrow_event_window_before_categorising.md) — filter to burst [start,end] first.
- [credential rotation must distribute the public material](pattern_rotation_must_distribute.md) — latent gap until first real rotation.
- [The `url` field of an event is an identifier, not an API path](pattern_url_field_is_not_an_api_path.md) — extract ID, use own path conventions.
- [Treat empty tool output as unknown, never data](feedback_treat_empty_tool_output_as_unknown.md) — re-run/wait before asserting.
- [A DB `ERROR:` line is not an app failure](pattern_db_error_line_is_not_app_failure.md) — find the `except IntegrityError` first.
- [fork() shares the DB pool → Postgres wire desync](pattern_fork_shares_db_connection_pool.md) — "lost synchronization"; pre_ping/recycle don't help.
- [Healthcheck depth varies: `Healthy` ≠ end-to-end working](feedback_healthcheck_depth_varies.md) — read the healthcheck.test line.
- [When a fix to live state doesn't take, ask whether deploy reads live state or a snapshot](feedback_snapshot_indirection.md).

## Standing rules — process / GitHub
- Verify-before-citing: [GitHub state+identity](feedback_refetch_state_before_writing_final_artifact.md) · [closed-issue disposition](feedback_verify_closed_issue_disposition.md) · [token/invite lifecycle](feedback_verify_token_lifecycle_claims.md) · [recent fixes before flap tickets](feedback_check_recent_fixes_before_filing.md) · [probe before requesting a feature](feedback_check_before_requesting.md).
- [Ticket body is the spec — on design change AND new criteria](feedback_ticket_body_is_the_spec.md) — comment ≠ spec; re-fetch body before claiming it.
- PR/review mechanics: [check `merged` field first](feedback_pr_check_merged_field_first.md) · [finalize+push before auto-merging reviewer](feedback_finalize_pr_before_dispatch_automerge.md) · [check a trap's PRECONDITION](feedback_check_trap_precondition_before_firing.md) (`auto_merge: null` = not yet approved).
- gh/CLI foot-guns: [`--jq` on a 404 outputs `null`](feedback_jq_on_error_response.md) · [avoid `body=@FILE`](feedback_gh_api_body_at_prefix.md) · [verify body-file content, unique tempfiles](feedback_verify_body_file_before_pr.md).
- Lane discipline: [flag follow-up disposition, don't set it](feedback_flag_followup_disposition_to_coordinator.md) · [don't file on behalf of other agents](feedback_dont_file_on_behalf_of_other_agents.md) · [canonical persona name for SendMessage](feedback_teammate_id_vs_name.md).
- Ops safety: [no destructive remediation without a recovery path](feedback_no_destructive_without_recovery_path.md) · [sandbox branch hygiene](feedback_sandbox_branch_hygiene.md) · [Monitor not bg-bash for prod waits](feedback_monitor_over_bg_bash_for_waits.md) · [crash-loop Monitor design](pattern_crashloop_recovery_monitor_design.md).

## Standing rules — reports / proposals
- [Apply your OWN new evidence to your OWN open positions](feedback_apply_own_evidence_to_own_positions.md) — esp. priority + "not proposing X because Y".
- [Ask "what problem?" of the QUESTION, not just the solution](feedback_ask_what_problem_before_accepting_scope.md) — "too narrow" isn't evidence.
- Incident-report rigour: [read the originating PR/issue body for causation](feedback_read_pr_body_for_causation.md) · [don't overclaim attributions](feedback_no_attribution_overclaim.md) · [confirm before shipping a report gated on external verification](feedback_parallel_drafting_verification_scope.md) · [active recurrence justifies >P3](feedback_priority_active_recurrence.md).
- Proposal hygiene: [tests must be deterministic AND actionable](feedback_test_proposals_must_be_actionable.md) · [enumerate existing surfaces first](feedback_enumerate_existing_mechanisms.md) · [loganne is cross-estate events only](feedback_loganne_scope.md) · [verify "alternatives" are equivalent](feedback_verify_alternatives_are_equivalent.md).
- Fix at source: [silent fallbacks are a security risk](feedback_silent_fallbacks_are_a_security_risk.md) · [don't game API contracts](feedback_dont_game_api_contracts.md) · [keep the docker.l42.eu mirror in the orb](feedback_keep_docker_mirror.md).

## Mail
- [Relay 2xx is NOT delivery](pattern_relay_accepted_mail_still_silently_lost.md) — Gmail bounces after, DSN quarantined; check lucos_mail_smtp per queue-id.

## Loganne (webhook errors never self-heal)
- [Self-verify cred/deploy events via loganne](reference_loganne_read_self_verify.md) — bearer KEY_LUCOS_LOGANNE; /events filters…
- [webhook-error-rate never self-clears — retry via API](feedback_rescan_before_webhook_cleanup.md) — first [sample errors](feedback_sample_webhook_errors_first.md) + [snapshot fields](feedback_snapshot_before_retry.md).
