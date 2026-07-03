# SRE Agent Memory

Index only — one line per entry, detail in the linked file. Verify ticket state before citing.

## Consolidated topic files (bulk inline knowledge)
- [Per-repo known issues + host facts + hostname→repo map](topic_per_repo_known_issues.md) — all repos' quirks/open tickets; xwing; media-api/media-metadata/ceol map.
- [CI + infra patterns](topic_ci_infra_patterns.md) — deploy_orb, docker_mirror, DOCKER_HOST=ssh deploys, rate limits, healthcheck-by-base-image, manual container-swap, GitHub API/App conventions, Loganne retry ops, creds snapshot.
- [Monitoring mechanics](topic_monitoring_mechanics.md) — poll interval=60s (not 10s); post-restart cold-state ~2-3min cascade.

## Method: don't trust local checkouts / logs
- [Container restart clears docker logs → false "onset"](pattern_container_restart_log_buffer_artifact.md) — check StartedAt + full status distribution + job-success stream + live probe before reporting an onset/ongoing failure. arachne#711.
- [Sandbox checkouts months-stale + undeployed repos](pattern_stale_sandbox_checkouts.md) — verify vs `git show origin/main:<path>` AND live probes before any migration/decom finding; logs show symptoms not the blocking mechanism.

## aithne / auth
- [PWA service-worker render drops aithne_origin → dead navbar keepalive → 15-min re-login storm](pattern_pwa_sw_render_drops_aithne_origin.md) — diagnose via router log `/auth/login` vs `/auth/remint` per consumer referer; notes#445 (SW client-render, 0 remints vs seinn 160). NOT the #441 JWKS gap.
- [eolas dual auth: @api_auth static-key vs AithneAuthMiddleware JWT](pattern_eolas_dual_auth_static_key_vs_jwt_middleware.md) — "Not enough segments" middleware log is NOISE, never blocks @api_auth.
- [contacts returns 403 (not 401) for an unrecognised key](pattern_contacts_403_for_unrecognised_key.md) — decider=read server's live CLIENT_KEYS; stuck-403 after consumer redeploy = redeploy the SERVER.
- [Scope-cutover convergence + holder-enumeration gap](pattern_scope_cutover_convergence_and_enumeration_gap.md) — verify via router access log; monitoring board (not log) catches infrequent-read 403s.
- [aithne signing_key_age is NOT a deploy signal](pattern_aithne_signing_key_age_not_deploy_signal.md) — key persists across restarts; verify deploy via StartedAt+image tag.
- [aithne KEK breaking-migration deploy race + recovery gotchas](pattern_aithne_kek_migration_deploy_race.md) — 2026-06-30 46min outage; migrate-kek quote/PORT/redeploy gotchas.
- [aithne contact id: string (principal) vs int (contacts proxy)](pattern_aithne_contactid_string_vs_int_divergence.md) — JS cross-ref MUST String()-coerce.
- [Scratch Go image has no CA bundle → x509 unknown authority on outbound](pattern_scratch_image_no_ca_bundle.md) — latent until first outbound HTTPS; /_info green ≠ fixed.

## lucos-search / eolas / arachne
- [lucos-search option value = eolas person URI even in contact mode](pattern_lucos_search_emits_eolas_uri_not_contacts.md) — reverse-map, don't string-munge.
- [arachne has TWO eolas ingest paths; hyphenated pks fail webhook path](pattern_arachne_eolas_dual_ingest_hyphen_pk.md) — eolas urls.py pk regex `\w+` excludes hyphens; bulk masks it.
- [arachne skos:prefLabel makes ontology meta-entity look indexable](pattern_arachne_preflabel_makes_indexable.md) — is_meta_type excludes OWL/RDFS not SKOS.
- [media_metadata → /v2/export → arachne pipeline landmines](pattern_media_metadata_arachne_pipeline.md) — torn/empty export wipes tracks; no shrink-guard.
- [arachne multi-component CI dep-skew + #633 regression](project_arachne_multicomponent_ci_depskew.md) — one pip resolve across components → ResolutionImpossible; per-component venvs (#652).
- [Misleading "502 could not reach X" = DECODE failure of a 200 upstream](pattern_misleading_502_decode_not_unreachable.md) — test upstream directly; suspect mock/prod JSON type divergence.

## Backups
- [Backups localhost:8027 reset but 127.0.0.1 ok = enable_ipv6 dual-stack publish mismatch](pattern_backups_sshadd_gates_server_start.md) — test 127.0.0.1 AND localhost AND [::1].
- [DB-specific backups walked back → engine-agnostic quiesce](project_backups_db_consistency_walkback.md) — docker pause owner around read; all hosts plain ext4.
- [aurora access + rsync facts](reference_aurora_access_and_rsync.md) — no direct SSH; route via container ProxyJump; real hardlinks.
- [home-host backups red = ISP dropped upstream IPv6 transit](pattern_salvare_ipv6_prefix_withdrawal.md) — self-resolves; don't force IPv4.
- [backup-without-original red forever on decommissioned system's retained backups](pattern_backups_without_original_on_decommission.md) — benign; fix=configy-absence signal (#359).
- [host-tracking "<host>: 'low'" = invalid recreate_effort in configy](pattern_backups_invalid_effort_crashes_host_tracking.md) — KeyError repr; fix configy value.
- [backups create-backups red on empty (zero-commit) repo](pattern_backups_empty_repo_fails_run.md) — wget exit 8 on ref-less codeload. #298.
- [#311 scp→rsync: rsync runs on SOURCE HOST via Fabric; avalon has no rsync](pattern_backups_rsync_binary_missing_from_image.md) — check `which rsync` on the HOST.
- [Incremental rsync path: ProxyJump host-key + unquoted rm&&mv bugs — RESOLVED](pattern_incremental_rsync_container_proxyjump_hostkey.md) — shlex.quote in runOnRemote; StrictHostKeyChecking=no doesn't reach ProxyJump hop.

## Router / DNS / firewall
- [New service TLS check failing = router hasn't issued cert yet](pattern_router_newdomain_cert_latency.md) — update-domains.sh on startup + daily 22:16 UTC; NOT an incident.
- [router has TWO cert-renewal paths](pattern_router_dual_cert_renewal_paths.md) — configy certonly + stock certbot renew; reaping = "not HTTP-served".
- [All l42.eu SERVFAIL = apex zone failed to load on avalon](pattern_l42_dns_apex_zone_outage.md) — dig SOA @avalon; reload via kill -HUP named PID.
- [Firewall enforce rollout — hairpin is single point of failure](project_firewall_rollout.md) — COMPLETE 2026-06-08; durable: DRY_RUN override, Compose reuses stale network.
- [avalon enable_ipv6 bridges reach global IPv6 via NAT66; monitoring/time IPv4-only](reference_avalon_ipv6_bridging.md) — enable_ipv6 per-network.
- [Compose silently REUSES a stale network](compose-reuses-stale-network.md) — inspect live net, not compose; network rm+recreate to reconcile.

## Dev wiring / creds
- [Dev cross-service wiring + stale-.env 403 trap](pattern_dev_cross_service_wiring.md) — *_ORIGIN=host.docker.internal; diff local .env vs fresh creds before writing.
- [Use commit-claude-main for ~/.claude files, not hand-rolled rebase/stash](feedback_commit_claude_main_for_dotclaude.md) — shared tree; manual rebase drops others' in-flight memory.
- [lucos_creds reads .env from CircleCI snapshot, not live store](reference_lucos_creds_self_deploy.md) — check snapshot on "fix didn't take".
- [Three-stage env-var wiring required](pattern_three_stage_env_var_wiring.md) — code read + compose passthrough + creds value.
- [Walk the env-var chain before concluding which link is the gap](feedback_walk_env_chain_before_concluding.md) — usually link 3 (compose), not link 1 (creds).

## Monitoring
- [monitoring API uses `status` field not `ok`](pattern_monitoring_api_status_field.md) — use `summary` for counts.
- [docker_mirror_registry OnExpire errors benign](pattern_docker_mirror_registry_onexpire_benign.md) — TTL noise, not disk.
- [Estate circleci alert storm = CircleCI API outage tripping UnknownsGate](pattern_circleci_unknownsgate_estate_storm.md) — check Loganne failingChecks[].debug first; fix=UnknownsGate threshold.
- [monitoring self fetch-info flap → ACCEPT, don't build](pattern_monitoring_self_fetchinfo_flap_accept.md) — global 1s timeout; #186 closed.
- [fetch-info requires http_port; non-HTTP boxes via schedule_tracker](pattern_monitoring_coverage_http_vs_scheduled.md) — /systems/http filters; use full /systems for non-http attrs.
- [public-port TCP reachability checks](pattern_monitoring_public_port_reachability.md) — liveness floor only; /systems/http filters out dns/router.
- [schedule-tracker detection semantics (ADR-0004): red needs 2 CONSECUTIVE fails](reference_schedule_tracker_detection_semantics.md) — intermittent stays GREEN by design.
- [Media cross-probe flap in rollout burst = LEGIT 401 during key-rotation convergence](pattern_deploy_window_boundary_crossprobe_flap.md) — alerts CORRECT, don't suppress.
- [dependsOn suppresses ONLY during deploy windows](pattern_dependson_deploy_window_only.md) — worthless on lagging schedule_tracker checks.
- [dependsOn has TWO read sites — trace both](pattern_dependson_two_read_sites.md) — suppress filter + unsuppress cascade.
- [`/suppress` is a 10-min deploy window, NOT a known-issue annotation](pattern_monitoring_suppress_is_deploy_window_only.md) — ignores pre-existing failures.
- [red-means-down — no ack/known-issue board state](feedback_red_means_down_no_ack_state.md) — don't pitch mute/ack features.
- [Repeated alerts for SAME failing check = one re-alert per deploy](pattern_monitoring_realert_per_deploy.md) — not flapping.
- [Alert suppression asymmetric → orphaned "Everything OK" emails](pattern_monitoring_suppression_asymmetry.md) — #264.
- [Don't accept flaps as "expected"](feedback_no_flap_tolerance.md) — fix via dependsOn/failThreshold/window or ticket.
- [Checks AND thresholds live in /_info, not lucos_monitoring](feedback_failthreshold_lives_in_info.md) — monitoring is aggregation only.
- [/_info = availability/config, NOT content-rendering correctness](pattern_info_endpoint_boundary.md) — content integrity → CI assertion/synthetic probe.

## Scheduled-job / service-specific failures
- [loganne client `level` now REQUIRED positional arg](pattern_loganne_client_level_required_arg.md) — missing → TypeError, skips success tick.
- [reconcile_tag_names silent-success masking](pattern_reconcile_silent_success_masking.md) — reports success on total eolas-fetch failure (resolved=0). mma#302.
- [uri-integrity flaps = intentional requiresURI migrations](pattern_media_metadata_uri_integrity_requiresuri_migration.md) — not a bug.
- [lucos_locations stops recording silently; /_info only checks TLS](pattern_locations_silent_data_gap.md) — monitor OUTCOME not each cause. #91.
- [media_import all_files red = weekly full scan hard-killed by redeploys](pattern_media_import_fullscan_killed_by_redeploy.md) — cron grandchild SIGKILLed. #173.
- [seinn playback-error thrash ≠ cache-eviction thrash](pattern_seinn_playback_thrash_distinct_from_cache_thrash.md) — decodeAudioData/fetch fails; #482 fixed #483.
- [Daily 02:00Z bulk weighting recompute → loganne flap](pattern_daily_weighting_cron_loganne_flap.md) — known, don't refile.
- [linuxplayer phantom ?action=error DELETEs — RESOLVED #123](pattern_linuxplayer_phantom_error_deletes.md) — re-open if recurs.

## CI / build / deploy
- [python:3.15.0b2-alpine bump breaks psycopg/libpq](pattern_python_beta_alpine_libpq_break.md) — fix `apk add libpq`; not a flake.
- [Auto-merged base-image bump breaks at deploy/runtime not build](pattern_baseimage_bump_runtime_break.md) — durable fix = CI test job booting the stack, not a Dependabot ignore.
- [deploy-avalon exit 18 "pull access denied for *_test" = orb pull profile-blind](pattern_deploy_orb_pull_profile_blind.md) — FIXED orb 0.0.185; fresh pipeline to pick up orb fix.
- [lucos_repos audit mass 403s = GitHub secondary rate-limit, not lost access](pattern_repos_audit_dryrun_secondary_ratelimit.md) — non-incident.
- [lucos_creds `test` job flake gates deploy](pattern_creds_envrestrict_flaky_test.md) — flaky scp assertion; re-run from failed. #358.
- [Docker Login (mirror) exit 1 = TIMEOUT reaching docker.l42.eu, transient](pattern_docker_mirror_login_timeout_transient.md) — confirm mirror healthy then rerun.
- ["blob unknown to registry" on push = upstream Hub transient](pattern_docker_push_blob_unknown_upstream.md) — rerun clears; not our code.
- [Slow deploy to home hosts = ISP image pull, not a stall](pattern_homehost_deploy_pull_slowness.md) — don't ticket.
- [lucos_repos deploy auto-triggers a fresh audit sweep](pattern_lucos_repos_deploy_triggers_sweep.md) — recovery ~17-18min; POST /api/sweep manual.
- [GitHub Actions outage: check status page early](pattern_github_actions_outage_diagnosis.md) — don't close/reopen/empty-commit during outage.

## Docker daemon / recovery
- [Docker live-restore:true skips network init when containers running](pattern_docker_live_restore_skips_network_init.md) — stop all containers → restart daemon → redeploy.

## Diagnostic methodology / standing rules
- [Access-log first for webhook-error-rate bursts](pattern_access_log_first_for_webhook_bursts.md) — pull router nginx log before theorising.
- [Avoid coincidence as default framing](feedback_avoid_coincidence_default.md) — default to causation; coincidence needs evidence.
- [Correlation is not "confirmed" root cause](feedback_correlation_is_not_confirmed.md) — add distinguishing instrumentation before shipping the correlation's fix.
- [Verify incident root cause by reproduction before publishing](feedback_verify_root_cause_by_reproduction.md) — plausible mechanism is a lead, not a cause.
- [Diagnose through to root cause when next step is more diagnostics](feedback_diagnose_through_to_root_cause.md) — park only for genuine developer-side work.
- [Check user-agent first when hunting a misbehaving HTTP client](feedback_check_user_agent_first.md) — read receiver access-log UA before hypothesising.
- [Check file reachability from entry point before "deployed code misbehaves"](feedback_check_reachability_first.md) — bundlers drop unreachable code.
- [Narrow the event window before counting categories](feedback_narrow_event_window_before_categorising.md) — filter to burst [start,end] first.
- [named volume shadows image contents at mount path](pattern_named_volume_shadows_image.md) — first-init-only semantics shadow image updates; also "used-to-be-fine"=slow-cooker (check data/index/log growth) and proxy-over-content-addressed-store partial-write = many signatures one cause.
- [credential rotation must distribute the public material](pattern_rotation_must_distribute.md) — latent gap until first real rotation; ping architect on 2nd case.
- [The `url` field of an event is an identifier, not an API path](pattern_url_field_is_not_an_api_path.md) — extract ID, use own path conventions.

## Standing rules — process / GitHub / PRs
- [Finalize + push all content before dispatching to an auto-merging reviewer](feedback_finalize_pr_before_dispatch_automerge.md) — approval auto-merges the reviewed SHA in seconds; keep incident reports DRAFT until final.
- [Flag follow-up disposition to coordinator, don't set it](feedback_flag_followup_disposition_to_coordinator.md) — don't toggle issue state on crossed messages.
- [PR state checks must include `merged` field first](feedback_pr_check_merged_field_first.md) — merged PR shows UNKNOWN like an open one mid-compute.
- [Verify issue state before citing a #N](feedback_refetch_state_before_writing_final_artifact.md) — strongest in final-artifact follow-up tables.
- [Verify closed-issue disposition (body+closing comment) before citing as preference evidence](feedback_verify_closed_issue_disposition.md).
- [Check recent fixes before filing flap-investigation issues](feedback_check_recent_fixes_before_filing.md) — pre-fix alerts persist in lookback for days.
- [Probe before requesting a feature](feedback_check_before_requesting.md) — one curl/grep it doesn't already exist.
- [Verify token/invite lifecycle claims before asserting](feedback_verify_token_lifecycle_claims.md) — grep store/handler or hedge.
- [`gh api --jq` on a 404 outputs `null`, not empty](feedback_jq_on_error_response.md) — use `--silent`+$? for existence.
- [Verify body-file content before create-pr / gh body-file calls](feedback_verify_body_file_before_pr.md) — unique tempfile names; Write may fail silently when batched.
- [`gh api` file-backed body needs `@` prefix](feedback_gh_api_body_at_prefix.md) — else empty body silently.
- [Use canonical persona name for SendMessage, not envelope teammate_id](feedback_teammate_id_vs_name.md).
- [Don't file GitHub artifacts on behalf of another agent](feedback_dont_file_on_behalf_of_other_agents.md) — unblock them instead.
- [Sandbox branch hygiene: reset --hard origin/main before branching](feedback_sandbox_branch_hygiene.md).
- [No destructive remediation without a recovery path](feedback_no_destructive_without_recovery_path.md) — compose files live only on CI runners transiently.
- [Treat empty tool output as unknown, never data](feedback_treat_empty_tool_output_as_unknown.md) — re-run/wait before asserting.

## Standing rules — incident reports / proposals
- [Read the originating PR/issue body in full when writing causation](feedback_read_pr_body_for_causation.md) — don't reflex-frame triggers as "routine".
- [Don't overclaim attributions in incident reports](feedback_no_attribution_overclaim.md) — restrict to what people actually said.
- [Confirm with team-lead before shipping a report when verification is externally gated](feedback_parallel_drafting_verification_scope.md) — parallel-drafting rule is for minutes-hours, not multi-day.
- [Active recurrence justifies priority above default-P3](feedback_priority_active_recurrence.md).
- [Test follow-ups must be deterministic AND actionable](feedback_test_proposals_must_be_actionable.md) — no alarm clocks for third-party bugs.
- [Loganne is for cross-estate events, not fine-grained instrumentation](feedback_loganne_scope.md) — enumerate alternatives.
- [Enumerate existing surfaces before proposing new persistence](feedback_enumerate_existing_mechanisms.md) — inverse of loganne_scope.
- [Verify "alternative" implementations are actually equivalent](feedback_verify_alternatives_are_equivalent.md) — SPARQL COUNT(DISTINCT) over OPTIONAL gotcha.
- [Silent fallbacks are a security risk, not just operational](feedback_silent_fallbacks_are_a_security_risk.md).
- [Don't game API contracts to work around design issues](feedback_dont_game_api_contracts.md) — fix at source.
- [Read library READMEs before reverse-engineering APIs from source](feedback_read_readmes.md).
- [ADR-0006 covers consumer-side only](reference_adr_0006_consumer_side_only.md) — not producer-side outbound saturation.
- [Keep the docker.l42.eu mirror in the orb](feedback_keep_docker_mirror.md) — fix mirror-side bugs at the mirror layer.
- [When a fix to live state doesn't take, ask whether deploy reads live state or a snapshot](feedback_snapshot_indirection.md).
- [Healthcheck depth varies — `Healthy` ≠ end-to-end working](feedback_healthcheck_depth_varies.md) — read the healthcheck.test line.

## Loganne webhook retry (actionable — never "self-heals")
- [Self-verify cred/deploy events via loganne](reference_loganne_read_self_verify.md) — bearer KEY_LUCOS_LOGANNE; /events filters client-side only.
- [webhook-error-rate never clears itself — retry via API](feedback_rescan_before_webhook_cleanup.md) — fresh-scan all failed events before retry (see topic_ci_infra_patterns for the API).
- [Sample errorMessage distribution before retrying](feedback_sample_webhook_errors_first.md) — transient-looking 504s often mask permanent data-quality fails.
- [Snapshot per-failure diagnostic fields before retry](feedback_snapshot_before_retry.md) — retry overwrites the failure-side record.
