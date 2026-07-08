# Memory

## Dispatcher Workflows

- **PR review loop** — implementation teammate drives it (not the dispatcher): messages `lucos-code-reviewer`, addresses feedback, handles specialist reviews, reports outcome. See `~/.claude/pr-review-loop.md`.

## User Preferences

- **Coordinator edits `~/.claude` directly** (persona/skill/routine files); infra scripts → `lucos-system-administrator`. The `lucos-issue-manager` teammate no longer exists — role absorbed into coordinator (via `/team`).
- **Repo secrets & settings** (GitHub secrets, auto-merge) → `lucos-system-administrator` only.
- **ADRs after system design** — always create one after a full system design/re-design; route to `lucos-architect`.
- **Don't bulk-re-quote agent output to lucas42** — the UI renders `<teammate-message>` blocks to him directly; limit own messages to coordinator framing + decisions + the user-input question. Verbatim relay still applies to SendMessage *between* agents. (2026-05-21)
- **Don't debug post-merge failures yourself** — hand build/deploy-after-merge investigations to the specialist persona (e.g. `lucos-site-reliability`); dispatcher lacks context for root-cause tracing.

## External Tool References

- [issue-manager App lacks PR write](reference_issue_manager_no_pr_write.md) — coordinator App 403 on PR comments/closes (Issues:write only); route to lucos-code-reviewer. Stuck Dependabot PR: CLOSE it (recreate fails for all Apps)
- [arachne MCP tool name lookups](reference_arachne_mcp_tools.md) — `find_entities` returns `rdfs:label`; use `get_entity` by URI for canonical `skos:prefLabel`
- [aithne agent-principal model](reference_aithne_agent_principal_model.md) — agent creds in lucos_agent/**development**; prod cutover needs lucas42 to mint prod machine key + grant a scope (ADR-0001 §6: non-human resources gate on a scope). Default-deny is at the resource, not token issuance. JWT: `principal_class`/`scopes`/`aud=="l42.eu"`
- [Media systems domain mapping](media-manager-domain-mapping.md) — configy systems.yaml canonical; lucos_media_manager (ceol.l42.eu) vs lucos_media_metadata_manager (media-metadata.l42.eu)
- [lucos_creds key rotation](reference_lucos_creds_key_rotation.md) — linked-cred/scope changes rotate the key → coordinated redeploys. The 401/403 window is during convergence (client+server redeploys), NOT at the creds-change moment. Consult before describing any cutover window
- [aithne is ES256-only](project_lucos_worlds_state.md) — signs ID tokens ES256/EC only (deliberate; lucos_locations relies on it). Any adopted OIDC tool must support ES256 — verify signing-alg interop at adopt-eval, not just "has OIDC" (BookStack broke on this, #21)

## GitHub Comment Conventions

- **Never use `#N` for Dependabot/CodeQL/secret-scanning alerts** in comments/PRs (`#N` links issues/PRs; alert numbering is separate). Use the CVE/GHSA id (auto-links) or the full alert URL.

## Feedback

- [Dep "removed transitive" may be a rename](feedback_dep_rename_vs_repin.md) — check for an upstream RENAME before re-pinning a vanished bundled dep; migrate the import
- [Don't auto-revert agent work](feedback_revert_policy.md) — ask whether to revert rather than assuming
- [Check before chasing](feedback_check_before_chasing.md) — check PR/system state before asking user to merge
- [Delegate questions to agents](feedback_delegate_not_guess.md) — ask the most suitable agent rather than guessing
- [Labels managed by coordinator](feedback_labels_owner.md) — not other personas
- [Developer message queue](feedback_developer_message_queue.md) — wait for ack before dispatching next; rapid messages process out of order
- [One actively-worked issue per agent](feedback_developer_one_issue_per_session.md) — dispatchable again once PR open + summary posted; don't wait for merge
- [Audit tool architecture is intentional](feedback_audit_architecture.md) — consult architect before proposing scope changes
- [Complete triage inline](feedback_triage_inline_consultation.md) — do agent consultation inline; don't park as "needs-design"
- [Never revert label changes blindly](feedback_never_revert_labels.md) — read comments first; changes are deliberate
- [Estate rollouts should use PRs](feedback_estate_rollout_prs.md) — prefer PRs; exception for trivial version bumps
- [Auto-commit ~/.claude changes](feedback_claude_config_commits.md) — commit + push without asking
- [Developer rebase issues](feedback_developer_rebase.md) — verify rebase results or use alternatives
- [Auto-merge on approval](feedback_auto_merge_workflow.md) — don't ask user to manually merge
- [No transient dismissals](feedback_no_transient_dismissals.md) — name unhealthy systems, explain cause, say when alerts clear
- [Correct agents when wrong](feedback_correct_agents.md) — correct factual errors and prompt instruction updates
- [SendMessage has no broadcast](feedback_shutdown_no_broadcast.md) — fan out individual SendMessage per teammate
- [Follow archival checklist](feedback_follow_archival_checklist.md) — use lucos/docs/repo-archival.md when decommissioning
- [Triage agent-raised issues immediately](feedback_triage_agent_raised_issues.md) — inline, don't wait for next triage run
- [No semver-major ignore rules](feedback_no_semver_major_ignore.md) — let major bumps flow; CI catches breakage
- [Consult github-workflow.md first](feedback_consult_github_workflow_doc.md) — read the doc, don't recall syntax (some PATCH fields silently ignored)
- [Don't endorse unverified analysis](feedback_no_unverified_endorsement.md) — no editorial praise unless checked against ground truth
- [No inline lessons in instruction files](feedback_no_inline_lessons.md) — narrative goes in the commit message, not the file
- [Question whether an issue should exist](feedback_question_issue_existence.md) — check for a duplicate auto-resolving tracking surface
- [Dispatch what /next returns](feedback_dispatch_what_next_returns.md) — don't reposition/skip; lucas42's board positioning is authoritative
- [Don't act on ambiguous user replies](feedback_ambiguous_user_reply.md) — if it could answer either question, ask which
- [Scope checks belong to reviewer](feedback_scope_checks_belong_to_reviewer.md) — PR-scope-vs-issue is code-reviewer's job
- [Ask about the plan first](feedback_ask_about_the_plan_first.md) — AskUserQuestion leads with the plan-shape question
- [Re-fetch before accusing](feedback_refetch_before_accusing.md) — re-fetch GitHub state right before send
- [Ticket decisions are async](feedback_ticket_decisions_async.md) — don't force synchronous answers on ticket routing; keep dispatching ready work
- [Template substitution in gh-as-agent](feedback_template_substitution.md) — `{repo}`/`@`-mention bodies get corrupted; use the file-backed pattern
- [No every-user-turn polling](feedback_no_every_turn_polling.md) — don't propose "re-check X every turn" fixes
- [Phantom teammate messages](feedback_phantom_teammate_messages.md) — I confabulate fake teammate blocks/tool output; verify against the real result block
- [Re-fetch issue comments before following up](feedback_refetch_issue_comments_before_following_up.md) — even on an issue I just filed
- [Disambiguate AskUserQuestion layers](feedback_askuserquestion_layer_disambiguation.md) — labels must name the system layer (code vs detector vs config)
- [Migration scope matches spec scope](feedback_migration_scope_matches_spec.md) — brief covers only what the spec requires; no "while you're at it"
- [Ready means fully implementable](feedback_ready_means_fully_implementable.md) — open cross-repo dependency ⇒ Blocked, not Ready
- [Ready = no deferred design choices](feedback_ready_no_deferred_design_choices.md) — settle design/UX/mechanism at triage; tell is "implementer should pick…"
- [Verify project-state before citing](feedback_verify_project_state_before_citing.md) — re-read the memory file AND the live ticket/board, not the index line
- [Don't shift work to coordinator](feedback_dont_shift_work_to_coordinator.md) — don't move automation's work onto coordinator unasked
- [Verify identifiers before propagating](feedback_verify_before_propagating.md) — verify a teammate's URL/repo/path before fan-out into GitHub bodies
- [No options in specialist consultations](feedback_no_options_in_consultations.md) — relay lucas42's question verbatim; don't add my own option list
- [No verbatim quotes on the ticket](feedback_no_verbatim_quotes_on_ticket.md) — brief ticket comments referencing prior by position; verbatim is for SendMessage
- [Ticket is the venue, not AskUserQuestion](feedback_ticket_is_venue_not_askuserquestion.md) — when a design discussion lives on a ticket, lucas42 answers there
- [Dependabot recreate is deterministic](feedback_dependabot_recreate_deterministic.md) — don't endorse `recreate` unless an input changed
- [Verify permission claims before asserting](feedback_verify_permission_claims.md) — probe the API/App perms before "{bot} can't X" / "only lucas42 can X"
- [Don't gate read-only checks](feedback_no_gate_on_readonly_checks.md) — run safe read-only verifications and report; confirm-first is for state-changing actions
- [Dispatch URL only](feedback_dispatch_url_only.md) — dispatch carries only `implement issue {url}`; never restate the ticket's design
- [Harness problems → lucos#155](feedback_harness_problems_to_lucos155.md) — track Claude Code harness limits there, not per-repo
- [Empty tool output = unknown, never data](feedback_treat_empty_tool_output_as_unknown.md) — re-run or wait before asserting
- [Don't offer unschedulable /schedule](feedback_no_unschedulable_schedule_offer.md) — remote routines lack prod SSH/gh/local files; gate at offer time
- [No parallel get-next/dispatch](feedback_no_parallel_getnext_dispatch.md) — run get-next to completion; dispatch exactly the URL it printed
- [No confabulated quotes in consult relay](feedback_confabulated_quote_in_consult_relay.md) — paste verbatim from the just-fetched result, never from memory
- [SendMessage running teammates, not subagents](feedback_sendmessage_not_subagents.md) — dispatch to existing teammates; don't spawn fresh Agent subagents
- [No extra host binaries](feedback_no_extra_host_binaries.md) — favour estate-wide tools (scp over rsync); get lucas42's nod before adding a host dependency
- [Rejected command ≠ no side effects](feedback_rejected_command_side_effects.md) — an interrupted compound Bash may still have created the issue/item; re-fetch state
- [aithne key-age ≠ deploy signal](feedback_aithne_key_age_not_deploy_signal.md) — `/_info` `signing_key_age` is liveness, not deploy confirmation; confirm via container/image
- [CHANGES_REQUESTED ≠ hard block](feedback_changes_requested_not_a_hard_block.md) — only blocks if required-review branch protection is set; the reliable block is converting the PR to draft
- [Serialize same-repo dispatch](feedback_serialize_same_repo_dispatch.md) — don't run two concurrent PRs on one repo; wait for the first to merge. Parallelise only across repos
- [No secondary sign-off gate](feedback_no_secondary_signoff_gate.md) — /next IS lucas42's sign-off; don't park implementable irreversible tickets in Awaiting Decision
- [ADR authorship is architect-only](feedback_adr_authorship_architect_only.md) — when a decision needs both an ADR and implementation, don't put "capture in the ADR" in the impl ticket (implementer writes a duplicate); commission the ADR separately to the architect
- [Track out-of-band specialist reviews to merge](feedback_track_out_of_band_specialist_reviews.md) — if the coordinator dispatches a security/SRE review out-of-band, it owns re-triggering the code-reviewer's final verdict + confirming the merge; a specialist-APPROVE + code-reviewer-COMMENT is NOT merged (aithne#300 sat 3h16m)

## Active Projects

- [lucos_worlds deploy + login](project_lucos_worlds_state.md) — BookStack worldbuilding, deployed 2026-07-07. **Login WORKS 2026-07-08** (verified by lucas42's real login) after fixing three sequential root causes: ES256 signing (patch BookStack, #26/#28, ADR-0002), client-auth method (aithne client_secret_basic, #295/#296/#297), missing email claim (primary-email in lucos_contacts, ADR-0003 + #766/#769; aithne emits it, #299/#300). RBAC #17/#19 now unblocked (resume — re-check dormant PR #19). Low follow-ups: #764 (radio widget), #767 (PersonName constraint), aithne#301 (gate `name`), #29/#30 (alg-binding)
- [Stuck PR workflow overhaul](project_stuck_pr_workflow.md) — detection/resolution process in agent instructions (2026-03-19)
- [Media API v2→v3 migration](project_v3_migration.md) — COMPLETE 2026-04-08 (lucos-lang deprecation was final milestone)
- [Auth fail-open/fail-closed](project_auth_failopen_question.md) — RESOLVED 2026-06-30: consumers FAIL CLOSED; residual is the JWKS serve-stale gap (aithne#241/arachne#697/lucos#255)
- [metadata→eolas migration](project_migration_finishoff.md) — RESOLVED 2026-06-01; lucos_firewall became sole #1 strategic priority
- [lucos_firewall rollout](project_firewall_rollout.md) — COMPLETE 2026-06-08 (all 3 hosts enforcing, lucos#182 closed). Durable lessons in file: DRY_RUN override, Compose-reuses-stale-network foot-gun, host-net+router INPUT pattern

## Agent Instruction Compliance

- Long persona files cause attention degradation (agents skip deep instructions + confabulate); mitigated 2026-03-06 by extracting SRE/sysadmin/security ops checks into separate `*-ops-checks.md` files with explicit counts + completion manifests.
