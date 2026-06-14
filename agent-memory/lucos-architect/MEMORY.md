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
- **`git fetch` before reviewing EACH repo — the fetch is the load-bearing step, not the checkout.** `git checkout origin/main` alone reuses a possibly-stale remote-tracking ref; you can be reviewing month-old code while believing it's current. Never assume freshness because you fetched a *different* repo this session. Slip 2026-06-10: reviewed stale eolas+media_metadata_api auth code (checkout without fetch), concluded scopes were "inert" and told lucas42 — both had merged scope-enforcement PRs (#298/#315) my local refs didn't have. If a conclusion hinges on absence-of-a-feature, `git fetch` and re-check before asserting it.
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
- [Verify the mechanism's properties before designing around them](feedback_verify_ci_mechanism_before_relying_on_it.md) — CI-sequencing (2026-04-29), lucos_repos warning-tier fiction (2026-05-28), `/_info`-assumes-HTTP-server (2026-06-05), exit-0≠env-exists (creds#363, 2026-06-07)
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
- [Verify the premise, not just the quote](feedback_verify_premise_not_just_quotes.md) — structural claims AND incident-causation; attribute/hedge causation in artifacts, never restate as fact (#278, 2026-05-29)
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
- [Verify past-tense work claims against git](feedback_verify_past_tense_work_claims.md) — "pushed commit", "amended PR", "filed ticket" are not verified facts; check before concurring (lucos#189 amendment didn't land, 2026-05-22)
- [Re-fetch state before writing it into a final artifact](feedback_refetch_state_before_writing_final_artifact.md) — multi-ticket summary footers must re-fetch each ticket's live state, not assert from memory of when last seen (lucos_claude_config#97, 2026-05-28)
- [Read the PR not the description of it](feedback_read_the_pr_not_the_description.md) — when an argument hinges on what a referenced PR does, read the PR; report-phrasing is a pointer, not a substitute (seinn#483 detector-keying misread, 2026-05-27)
- [Don't publish in the same batch as your evidence](feedback_dont_publish_in_same_batch_as_evidence.md) — a comment POST/PATCH or claim-bearing SendMessage must not share a parallel tool block with the reads that ground it; it runs before you see them (monitoring#264 fabricated loganne send_event/3, 2026-05-30)
- [Check special cases before extending a pipeline](feedback_check_special_cases_before_extending_pipeline.md) — when proposing a new walk/lookup on top of existing logic, start from the post-special-case output, not raw input (ADR-0004 LanguageFamily catch, 2026-05-27)
- [Qualify cross-repo ADR references](feedback_qualify_cross_repo_adr_refs.md) — ADR numbers are unique within a repo, not globally; write `lucos_arachne ADR-0004`, not bare `ADR-0004` (2026-05-27)
- [Commit your own agent-memory for attribution](feedback_commit_own_memory_for_attribution.md) — commit+push your own memory in-session (cron is backstop only); on non-ff use autoStash rebase, don't drop the step (2026-05-31)
- [Parse reference data, never hand-build it](feedback_parse_reference_data_never_handbuild.md) — audit/diff against the parsed source-of-truth file, never a memory-reconstructed registry list (creds#333 false gap, 2026-05-31)
- [Test prescribed values against the rule](feedback_test_prescribed_values_against_rule.md) — when you verify a validation rule AND prescribe values to enter against it, run each value through the rule first (auth_scopes#6 hyphen, 2026-06-14)
- [Check originating decision before forking](feedback_check_originating_decision_before_forking.md) — read the ticket that settled the design before framing an A/B fork; "divergence" may be an unfinished design half, and an option may re-open a deliberately-rejected approach (arachne#597 Option B, 2026-05-31)
- [Shared-lib break: testing gap, not caps](feedback_check_protocol_contract_before_accepting_break.md) — don't call a strict-client/permissive-server major "gratuitous"; real fix is consumer tests exercising the REAL lib interface (real-transport > fixture > autospec), not version caps (loganne v2, lucas42 corrected my caps/revert framing, 2026-06-06)
- [Check shared failure domain before diagnosing a "two-paths" split](feedback_check_shared_failure_domain_before_diagnosing_split.md) — divergent answers from two endpoints during an incident may be probe-timing artifact, not a resilience difference, if both share a failure domain (#410 per-repo-vs-bulk configy was one DNS outage, 2026-06-07; real fix was fail-closed-and-silent → .github#68)
- [Crossed-message thrash: let the decisive event settle it](feedback_crossed_message_thrash_let_decisive_event_settle.md) — in a fast crossed-message loop over an equivalent/reversible choice, re-verify live state each turn, hold the reversible action, and converge on the irreversible event (ADR-0012 tracker #107↔#227 flipped 3×, 2026-06-08; the merge settled it)
- [Defense-in-depth failure reverts to baseline](feedback_defense_in_depth_reverts_to_baseline.md) — don't pitch a 2nd-layer control's failure as high-leverage if the base layer (app-auth) independently holds; failure reverts to an accepted baseline (monitoring#285 perimeter-check overkill, 2026-06-15)

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
- [Encryption-at-rest ≠ ransomware defence](reference_encryption_at_rest_vs_ransomware.md) — encryption=confidentiality; ransomware-availability lever is append-only/immutable destination (backups ADR-0002 PR#319, 2026-06-09)
- [lucos_creds deploy reads CI snapshot, not live store](reference_lucos_creds_deploy_snapshot.md)
- [Enumerating the lucos_creds store over SSH](reference_creds_store_enumeration.md) — `ls` lists all system/env pairs; agent key is dev-scoped only (no prod visibility); sync manages only PORT/APP_ORIGIN
- [Test environments in lucos_creds (ADR-0002)](reference_creds_test_environments.md) — open env namespace; single-valued allowed-environment; bright-line no-prod-secrets rule; agents get standard test envs via set-valued key (#360); creds#363/PR#364
- [Dependabot security updates are independent of dependabot.yml schedule](reference_dependabot_security_vs_version_feeds.md)
- [Deployment model has no on-host source of truth](reference_no_onhost_source_of_truth.md) — compose files live transiently on CI; recovery requires CI redeploy, not local recreate (xwing 2026-05-28)
- [Docker Healthy ≠ network reachability — recurring estate-wide pattern](reference_docker_healthy_not_reachability.md) — 2 of last 3 incidents (creds CRLF 2026-05-09, xwing 2026-05-28); systemic healthcheck-design concern
- [Reconcile empty-source guard](reference_reconcile_empty_source_guard.md) — delete-on-absence loops must raise on an empty-but-non-erroring source, else they wipe everything (creds#333 ADR-0001, 2026-06-04)
- [Sweep-vs-CI race false positives](reference_sweep_vs_ci_race.md) — required-status-checks-coherent flags the slow CircleCI rollup as "stale" when the ~07:15 sweep collides with dependabot auto-merges; NOT a stale cache; fix lucos_repos#413 (2026-06-09)
- [auth_scopes vocabulary design](reference_auth_scopes_vocabulary.md) — flat scope list; `domain:` ≠ owning service; enforcement backend-side/default-deny; NO scope→backend mapping exists (so don't filter scope pickers by backend — creds#386)

## Project memories

- [Artist modelling decision](project_artist_modelling_decision.md) — Artist as `mo:MusicArtist` in media_api alongside Album
- [lucos_aithne auth design](project_machine_principal_sessions.md) — **ADR-0001 MERGED/Accepted 2026-06-09** (PR #2), 13 tickets raised (build #3-#10, audit #11, migrate #12; scope-repo `lucos_auth_scopes` created+ticket=lucos_auth_scopes#1 (transferred from lucos#236); creds#375; configy#224). Stack=Go, domain aithne.l42.eu. OIDC OP + WebAuthn passkeys(RP=l42.eu) + local-JWKS signed-JWT + identity-only + full-OIDC-day-1 + admin-invite enrol=recovery. **aithne mints NO identities** (external authorities: contacts/agent-registry-slug/configy-system-codes; services stay on creds short-term). authN-easy/authZ-hard, default-deny, scope-GRANT crown jewel. M2M-convergence parked (door open)
- [File uploader](project_file_uploader.md) — lucos#209: **PARKED (Ideation) 2026-06-08**; ADR-0013 draft PR #235 **CLOSED 2026-06-09** + branch deleted; build tickets held; revive as ADR-0001 in a new repo (don't reopen #235); design/Q&A valid for future revisit
- [Google Photos migration](project_photos_google_migration.md) — lucos_photos#424: PLAN FINALISED 2026-06-09; date-cutoff dedup (taken<1Feb2026); 4 tickets: #425 desc / #427 migration-script(Blocked) / #426 face-spike / lucos_backups#318 incremental-backup-ADR(blocker); aurora 954.4G
- [DNS secondary modelling](project_dns_secondary_modelling.md) — configy one-system/one-domain/one-host vs heterogeneous multi-host; recommend two-systems-one-repo; ADR lucos#213; dns#79/#95/configy#208 on hold
- [C4 estate model](project_c4_estate_model.md) — lucos_repos ADR-0006 (draft PR #423, tracking #422); generated from configy/_info/loganne/compose/creds, typed-by-source, divergence-as-audit; first-cut 41 systems

## Auto-merge & security checks

- [calc-version semver + dependabot gap](reference_calcversion_semver_dependabot_gap.md) — orb calc-version derives semver from conventional commits; dependabot auto-merges non-conventional merge commits → dependency-major never majors the artifact (estate-wide; surfaced 2026-06-07)
- lucos#42: CodeQL race with auto-merge. Make CodeQL a required status check (repo settings only). Check name on lucos_photos: `Analyze (python)`. Required for new auto-merge rollouts.
- Dependabot auto-merge on `pull_request` works **if** `LUCOS_CI_APP_ID`/`LUCOS_CI_PRIVATE_KEY` are in the Dependabot secret scope (separate from Actions scope). See [reference_github_dependabot_secrets.md](reference_github_dependabot_secrets.md).
- Auto-merge caller workflows need ≥ `permissions: contents: read` (`{}` causes `startup_failure`). Discovered 2026-03-21 incident.
- `.github` smoke-test suite covers `dependabot-auto-merge` only, not `code-reviewer-auto-merge` — gap tracked in lucos#58.
- [Auto-merge approval policy](project_auto_merge_approval_policy.md) — **lucos ADR-0013 Accepted** (PR lucos#237 approved+ready); configy `additionalReviewers` + workflow-enforced required-set, fail-closed; supervised=bot+lucas42. Impl: configy#231→.github#70→claude_config#114

## Infrastructure notes

- [scratch vs distroless/static + CA bundle](reference_scratch_vs_distroless_ca_bundle.md) — `FROM scratch` ships no CA bundle/tzdata; prefer distroless/static for Go services doing outbound HTTPS (aithne incident 2026-06-12, lucos#240/PR#241)
- [Firewall DOCKER-USER polices inter-container traffic](reference_firewall_dockeruser_scope.md) — terminal DROP + origin-blind allow-list hits container↔container, not just external; diverges from ADR-0007; bridge-nf-call-iptables determinant; firewall#13 gates avalon enforce (2026-06-08)
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
- **lucos_eolas** — Django. Canonical home for cross-domain metadata; write API shipped (`POST /api/metadata/<type>/`, 409-on-single-dup/201). ADR-0001 (canonical-home contract, PR #288) established `docs/adr/`. 0 open issues as of 2026-05-31.
- **lucos_media_metadata_api** — Go+SQLite. v3 shipped. ADR-001 §2: arrays-everywhere wire format. Album as `mo:Record` (#157). Person-tag migration in #237. Latent bug in arachne searchindex.py (album field empty since #137) tracked in arachne#326.
- **lucos_media_manager** (ceol.l42.eu) — Java long-polling. **Not** lucos_media_metadata_manager.
- **lucos_media_metadata_manager** — PHP front-end. Client-side Typesense via arachne (#51).
- **lucos_media_weightings** — Python cron. Multiplier soft cap = 100 (#39).
- **lucos_media_seinn** — Node.js player. Playback sync #14.
- **lucos_media_linuxplayer** — Node.js + mplayer on ARM. Primary cause of stale-position on device switch.
- **lucos_configy** — Rust API. Single-host-for-domain (#25) Option A.
- **lucos_monitoring** — Erlang OTP. Flappiness/consecutive-failure threshold #74 = CLOSED (was per-check `failThreshold`). No open warning-tier/degraded-vs-unhealthy issue exists (verified 2026-06-12) — don't cite #74 for that.
- **lucos_root** — Static+Apache. /_info 3-tier schema accepted (lucos#35).
- **lucos_repos** — Go+SQLite, convention auditing. Greenfield #22. Blast radius #159 → ADR-0003 dry-run sweep. ADR-0004 auto-close audit-finding issues (#248, PR #251 merged).
- **lucas42/.github** — Reusable workflow repo. Dependabot auto-merge SHA pinning issue (#34). Tag-based versioning (#35), smoke test gate (#38).
- **lucos_creds** — Go AES-GCM. CLIENT_KEYS fully automated from linked credentials. Scoped permissions (#87) approved.
- **lucos_loganne** — Node.js, static webhook config. Auth migration #374 (per-consumer linked creds, 3-phase). Per-event `level` field ([project_loganne_event_level.md](project_loganne_event_level.md), #506): named ordinal scale, client-side filter, awaiting taxonomy sign-off.
- **lucos_time** — Node.js. `/current-items` #70. `commemorates` predicate for festivals (2026-03-05).
- **lucos_locations** — OwnTracks (mosquitto + recorder + frontend). TLS reload via inotify+SIGHUP (#4).
- **lucos_docker_mirror** — Self-hosted pull-through cache at docker.l42.eu on avalon. ADR-0001 (replaces GHCR static). ADR-0002 (Flask→nginx). Incident 2026-04-17 documented.
- **lucos_docker_health** (lucos#45) — Go, distroless, push via schedule_tracker. Heartbeat healthcheck pattern. Runs as root (socket access is root-equiv regardless of UID).
