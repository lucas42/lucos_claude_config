# SRE Agent Memory

Index only; the detail is in each linked file. Verify ticket state before citing.

## Recent incident (resolved)
- [avalon disk failure — ALL data recovered 2026-09-16 22:34](project_avalon_disk_failure_294.md) — #294 CLOSED 2026-09-18; report lucas42/lucos#297 merged, follow-up lucas42/lucos#305. ⚠️ photos were NEVER lost; nobody checked configy. Still out: lucos_dns#135.

## Consolidated topic files (read first)
- [Per-repo known issues + host facts](topic_per_repo_known_issues.md) · [CI + infra patterns](topic_ci_infra_patterns.md) · [Monitoring mechanics](topic_monitoring_mechanics.md) — poll is 60s · [⛔ RESOLVED/benign](topic_resolved_historical.md).

## aithne / auth
- [PWA SW render drops aithne_origin → re-login storm](pattern_pwa_sw_render_drops_aithne_origin.md) · [aithne contact id: string vs int](pattern_aithne_contactid_string_vs_int_divergence.md) — String()-coerce in JS.
- [eolas dual auth: static-key vs JWT](pattern_eolas_dual_auth_static_key_vs_jwt_middleware.md) — "Not enough segments" never blocks · [contacts 403s (not 401) an unknown key](pattern_contacts_403_for_unrecognised_key.md) — read live CLIENT_KEYS.
- [Scope-cutover convergence + holder-enumeration gap](pattern_scope_cutover_convergence_and_enumeration_gap.md) — verify via the router log · [signing_key_age ≠ deploy signal](pattern_aithne_signing_key_age_not_deploy_signal.md).
- [aithne KEK migration deploy race](pattern_aithne_kek_migration_deploy_race.md) — 46min outage 2026-06-30 · [Scratch Go image has no CA bundle](pattern_scratch_image_no_ca_bundle.md) — x509 on first outbound HTTPS.

## lucos-search / eolas / arachne
- [lucos-search emits the eolas URI even in contact mode](pattern_lucos_search_emits_eolas_uri_not_contacts.md) · ["502 could not reach X" = DECODE failure of a 200](pattern_misleading_502_decode_not_unreachable.md).
- [arachne: 2 eolas ingest paths; hyphenated pks fail the webhook one](pattern_arachne_eolas_dual_ingest_hyphen_pk.md) — regex `\w+` · [multi-component CI dep-skew](project_arachne_multicomponent_ci_depskew.md).
- [media_metadata → arachne pipeline landmines](pattern_media_metadata_arachne_pipeline.md) — a torn export wipes tracks; #834.

## Backups
- [DB-specific → engine-agnostic quiesce](project_backups_db_consistency_walkback.md) — docker pause the owner · [recreate_effort and skip_backup are INDEPENDENT](reference_recreate_effort_vs_skip_backup_semantics.md).
- [aurora access + rsync](reference_aurora_access_and_rsync.md) — no direct SSH; go via the container · [host-tracking "<host>: 'low'" = bad recreate_effort](pattern_backups_invalid_effort_crashes_host_tracking.md) — fix in configy.
- [Backups needs NO rsync on hosts](pattern_backups_rsync_binary_missing_from_image.md) — copyTo=scp; incremental rsync runs in the image (#315 reverted #311).
- [Triggering + verifying an ad-hoc create-backups run](pattern_verifying_a_create_backups_run.md) — no HTTP trigger; log FIFO eats tracebacks; ~15min; ⚠️72h check blind spot, trust loganne.
- [localhost:8027 reset but 127.0.0.1 ok = enable_ipv6 mismatch](pattern_backups_sshadd_gates_server_start.md) — test v4, localhost and [::1].

## Router / DNS / firewall
- [New-service TLS failing = cert not issued yet](pattern_router_newdomain_cert_latency.md) — startup + daily 22:16 · [router has TWO cert-renewal paths](pattern_router_dual_cert_renewal_paths.md).
- [All l42.eu SERVFAIL = apex zone failed on avalon](pattern_l42_dns_apex_zone_outage.md) — dig SOA @avalon · [⚠️ `*-v4.s.l42.eu` is a deploy route, not a host alias](pattern_s_l42_eu_v4_names_are_not_host_aliases.md) — ssh salvare-v4 → xwing.
- [avalon IPv6 bridging via NAT66](reference_avalon_ipv6_bridging.md) — monitoring/time are IPv4-only · [Duplicate `fd00:*::/64` blocks network recreate](pattern_duplicate_ula_subnet_blocks_network_recreate.md) — "Pool overlaps".
- [Compose silently REUSES a stale network](compose-reuses-stale-network.md) — inspect the live net.

## Dev wiring / creds
- [Dev cross-service wiring + stale-.env 403](pattern_dev_cross_service_wiring.md) · [commit-claude-main for ~/.claude; `git status` LIES](feedback_commit_claude_main_for_dotclaude.md) — check `git diff origin/main`.
- [lucos_creds deploys from its CircleCI snapshot](reference_lucos_creds_self_deploy.md) · [SSH auth = per-key ENVIRONMENT only](reference_lucos_creds_ssh_auth_model.md) — a new path needs no server change.
- Env vars: [3-stage wiring](pattern_three_stage_env_var_wiring.md) · [walk the chain first](feedback_walk_env_chain_before_concluding.md) — usually compose · [multi-line secrets truncated](pattern_multiline_secret_truncated_at_first_line.md).

## Monitoring
- [Checks + thresholds live in /_info](feedback_failthreshold_lives_in_info.md) — monitoring only aggregates · [⚠️ failThreshold counts SOURCE UPDATES](pattern_failthreshold_counts_source_updates.md) — =2 fires on one bad reading.
- [/_info = availability, not correctness](pattern_info_endpoint_boundary.md) — ⚠️ stays green through outages; lucos#273 · [/_info 1s dep probe > 1s poll timeout](pattern_info_inband_dependency_probe_exceeds_poll_timeout.md) — alerts the WRONG service.
- [monitoring's state server = head-of-line bottleneck](pattern_monitoring_selfpoll_mailbox_burst.md) — ⚠️loganne/mail down ⇒ in-band alerts 500 the WHOLE API; CPU 0.01%=blocked vs ~18%=rendering.
- [New service: monitoring REBUILD vs root RUNTIME](pattern_surfacing_new_service_monitoring_vs_root.md) · [API field is `status`, not `ok`](pattern_monitoring_api_status_field.md) — use `summary` for counts.
- [fetch-info needs http_port](pattern_monitoring_coverage_http_vs_scheduled.md) — else use schedule_tracker · [schedule-tracker: red needs N CONSECUTIVE fails](reference_schedule_tracker_detection_semantics.md) — ⚠️ false recovery nulls last_success.
- [⚠️ Losing schedule_tracker_db forgets stopped jobs](pattern_schedule_tracker_db_loss_forgets_stopped_jobs.md) — NEVER wipe it · [history from loganne, not /api/status](feedback_monitoring_history_from_loganne_not_snapshots.md).
- [No ack state; red means down](feedback_red_means_down_no_ack_state.md) · [`/suppress` = deploy window](pattern_monitoring_suppress_is_deploy_window_only.md) · [dependsOn only in deploy windows](pattern_dependson_deploy_window_only.md) · [two read sites](pattern_dependson_two_read_sites.md).
- Flapping: [re-alerts once per deploy isn't flapping](pattern_monitoring_realert_per_deploy.md) · [a crash-loop flaps docker_health](pattern_docker_health_crashloop_flapping.md) · [cross-probe flap in a rollout = LEGIT 401](pattern_deploy_window_boundary_crossprobe_flap.md) · [don't accept flaps as "expected"](feedback_no_flap_tolerance.md).
- [Estate circleci storm = CircleCI outage](pattern_circleci_unknownsgate_estate_storm.md) — a rerun fakes recovery.

## Scheduled jobs / services
- [media_import: one bad file kills the scan](pattern_new_files_unguarded_loop_poison_file.md) · [RQ `with_scheduler=False` drops retries](pattern_rq_scheduler_disabled_silently_drops_retries.md) · [loganne client `level` is required](pattern_loganne_client_level_required_arg.md).
- [Hung Python: no py-spy/gdb on prod](pattern_hung_python_process_no_pyspy_use_faulthandler.md) — faulthandler+SIGUSR1 · [Python stdout buffered → print() lost](pattern_python_stdout_buffered_swallows_diagnostics.md).
- [reconcile_tag_names silent-success masking](pattern_reconcile_silent_success_masking.md) · [A piped copy can't detect a dead sender](pattern_piped_copy_receiver_cannot_detect_truncation.md) — a 0-byte "final" file.
- [⚠️ locations `location-freshness` is untrustworthy](pattern_locations_silent_data_gap.md) — check `.rec` created_at · [/map 500 + /_info green = oauth2_proxy crash-loop](pattern_locations_oauth2proxy_sidecar_crashloop.md) — only lucas42 can fix.
- [uri-integrity flaps = requiresURI migrations](pattern_media_metadata_uri_integrity_requiresuri_migration.md)

## CI / build / deploy
- [Stuck-PR taxonomy](pattern_stuck_pr_taxonomy_and_rate.md) — 4 mechanisms; p98 merge 19min · [lucos_repos deploy triggers a sweep](pattern_lucos_repos_deploy_triggers_sweep.md) — ~17min.
- [Base-image bump breaks at runtime](pattern_baseimage_bump_runtime_break.md) — ⚠️ 4 times, latent to 11d; lucos#273 · [Python beta alpine breaks libpq](pattern_python_beta_alpine_libpq_break.md) — `apk add libpq`.
- [pipenv 2026.4.0 hash change fails `--deploy`](pattern_pipenv_hash_algorithm_skew.md) — not drift · [exit 127 after pip = machine image rolled back](pattern_rolling_machine_image_tag_moves_backwards.md) — use a venv.
- [Repo `test` job bypasses the docker mirror](pattern_repo_test_job_bypasses_docker_mirror.md) — a Hub blip turns it red · [repos audit discards Retry-After](pattern_ratelimit_maxwait_ceiling_reds_background_jobs.md).
- [GitHub Actions outage: check the status page first](pattern_github_actions_outage_diagnosis.md) — never relax branch protection · [Checks never fired = CircleCI 400'd the webhook](pattern_circleci_400_webhook_drops_pr.md).
- [GitHub silently disables auto-merge](pattern_github_silently_disables_automerge.md) — look for `auto_merge_disabled` · [`curl -w '%{http_code}' … || echo "000"` → `000000`](pattern_curl_httpcode_or_echo_concatenates.md) — orb#188.

## Estate topology / docker
- [Agent is root-equivalent via docker group → sandbox#102](reference_agent_root_equivalence_sandbox_102.md) — "agent can read X on a host" is NOT new; check #102 first.
- [⚠️ avalon = ONE disk, no RAID](reference_avalon_single_disk_no_raid.md) — ioerr_cnt + diskstats; lucos#294 · [Repo name ≠ container name](pattern_repo_name_not_container_name.md).
- [live-restore:true skips network init](pattern_docker_live_restore_skips_network_init.md) · [A named volume shadows the image's contents](pattern_named_volume_shadows_image.md) — only on first init.
- [`docker pause` ⇒ unhealthy until an interval after unpause](pattern_docker_pause_reports_unhealthy.md) — docker_health#117.

## Diagnostic methodology
- Causation: [not coincidence by default](feedback_avoid_coincidence_default.md) · [correlation ≠ confirmed](feedback_correlation_is_not_confirmed.md) · [reproduce before publishing](feedback_verify_root_cause_by_reproduction.md) · [diagnose through to root cause](feedback_diagnose_through_to_root_cause.md).
- Evidence limits: [⏳ establish a source's SCOPE before "never happened"](feedback_establish_source_scope_before_never_happened.md) · [a working-state file is not a history](feedback_verify_state_file_semantics_before_reading_history.md) · ["0 in N" needs exposure](pattern_stale_line_race_needs_exposure_not_absence.md) · [empty tool output = unknown](feedback_treat_empty_tool_output_as_unknown.md).
- [Verify claims; write falsifiably](feedback_verify_check_claim_against_underlying_store.md) · [don't infer the fix's mechanism from the bug's](feedback_dont_infer_fix_mechanism_from_bug_mechanism.md) · [flat-or-shrink targets DUPLICATE rules](feedback_consolidation_rule_scope.md).
- First moves: [user-agent first for a misbehaving client](feedback_check_user_agent_first.md) · [check reachability before "deployed code misbehaves"](feedback_check_reachability_first.md) · [narrow the event window before categorising](feedback_narrow_event_window_before_categorising.md) · [access log first for webhook bursts](pattern_access_log_first_for_webhook_bursts.md).
- False signals: [a restart clears docker logs → false "onset"](pattern_container_restart_log_buffer_artifact.md) — check StartedAt · [a DB `ERROR:` line ≠ an app failure](pattern_db_error_line_is_not_app_failure.md) · [`Healthy` ≠ working end to end](feedback_healthcheck_depth_varies.md) · [fix didn't take? live state vs snapshot](feedback_snapshot_indirection.md).
- [CONNECT_TIMEOUT at ~510ms = Happy Eyeballs](pattern_happy_eyeballs_amplifies_syn_loss.md) — SYN loss at 1.03s/3.06s · [bare "aborted due to timeout" = the probe discarded the latency](pattern_probe_measures_then_discards_latency.md).
- [Orphaned agent `ssh "… &"` job at 100% CPU](pattern_orphaned_ssh_background_job.md) — `ps --sort=-%cpu` every visit · [sandbox checkouts: stale AND on a branch](pattern_stale_sandbox_checkouts.md) — name `origin/main`.
- [⚠️ `docker logs X 2>&1 > f` captures NOTHING](pattern_capturing_large_container_logs.md) — Python logs to stderr; use `> f 2>&1`, then histogram shapes before grepping.
- [A guard keyed on a symptom is absent during incidents](pattern_guard_keyed_on_symptom_absent_during_incident.md) · [router gap analysis](pattern_router_log_gap_analysis.md) — ⚠️ avalon's router only logs its own vhosts.
- [fork() shares the DB pool → Postgres desync](pattern_fork_shares_db_connection_pool.md) · [optimistic cache of a remote process's state](pattern_optimistic_cache_of_remote_process_state.md) · [credential rotation must distribute](pattern_rotation_must_distribute.md) · [an event's `url` is an id, not an API path](pattern_url_field_is_not_an_api_path.md).

## Standing rules — process / GitHub
- Verify before citing: [GitHub state+identity](feedback_refetch_state_before_writing_final_artifact.md) · [closed-issue disposition](feedback_verify_closed_issue_disposition.md) · [token lifecycle](feedback_verify_token_lifecycle_claims.md) · [recent fixes](feedback_check_recent_fixes_before_filing.md) · [probe before requesting](feedback_check_before_requesting.md) · [the ticket body is the spec](feedback_ticket_body_is_the_spec.md).
- PRs: [check `merged` first](feedback_pr_check_merged_field_first.md) · [finalize before an auto-merging review](feedback_finalize_pr_before_dispatch_automerge.md) · [check a trap's PRECONDITION](feedback_check_trap_precondition_before_firing.md).
- gh foot-guns: [`--jq` on a 404 → `null`](feedback_jq_on_error_response.md) · [avoid `body=@FILE`](feedback_gh_api_body_at_prefix.md) · [unique body-files](feedback_verify_body_file_before_pr.md).
- Lanes: [flag a follow-up's disposition, don't set it](feedback_flag_followup_disposition_to_coordinator.md) · [don't file for other agents](feedback_dont_file_on_behalf_of_other_agents.md) · [canonical SendMessage name](feedback_teammate_id_vs_name.md).
- Ops safety: [no destructive step without a recovery path](feedback_no_destructive_without_recovery_path.md) · [branch hygiene](feedback_sandbox_branch_hygiene.md) · [Monitor, not bg-bash](feedback_monitor_over_bg_bash_for_waits.md) · [crash-loop Monitor](pattern_crashloop_recovery_monitor_design.md).

## Standing rules — reports / proposals
- [Apply your OWN evidence to your OWN positions](feedback_apply_own_evidence_to_own_positions.md) — especially priority · [ask "what problem?" of the QUESTION](feedback_ask_what_problem_before_accepting_scope.md) — "too narrow" isn't evidence.
- Incident reports: [causation from the PR body](feedback_read_pr_body_for_causation.md) · [no attribution overclaim](feedback_no_attribution_overclaim.md) · [external-verification gate](feedback_parallel_drafting_verification_scope.md) · [recurrence >P3](feedback_priority_active_recurrence.md).
- Proposals: [tests must be deterministic + actionable](feedback_test_proposals_must_be_actionable.md) · [enumerate existing surfaces](feedback_enumerate_existing_mechanisms.md) · [loganne scope](feedback_loganne_scope.md) · [equivalent alternatives](feedback_verify_alternatives_are_equivalent.md).
- Fix at source: [silent fallbacks = security risk](feedback_silent_fallbacks_are_a_security_risk.md) · [don't game API contracts](feedback_dont_game_api_contracts.md) · [keep the docker mirror](feedback_keep_docker_mirror.md).
- [The alert→action gap is SETTLED](project_response_gap_290_settled.md) — lucos#290; 3 named escalation triggers.

## Mail / Loganne
- [A relay 2xx is NOT delivery](pattern_relay_accepted_mail_still_silently_lost.md) — check lucos_mail_smtp per queue-id.
- [Self-verify cred/deploy events via loganne](reference_loganne_read_self_verify.md) — bearer KEY_LUCOS_LOGANNE · [retry webhook errors via the API](feedback_rescan_before_webhook_cleanup.md) — first [sample](feedback_sample_webhook_errors_first.md) + [snapshot](feedback_snapshot_before_retry.md).
