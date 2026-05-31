# Memory

## Dispatcher Workflows

- **PR review loop**: The review loop is now the responsibility of the implementation teammate, not the dispatcher. After creating a PR, the teammate drives the loop itself (messaging `lucos-code-reviewer`, addressing feedback, handling specialist reviews) and reports the outcome when done. See `~/.claude/pr-review-loop.md`.

## User Preferences

- **Workflow and config changes**: The team-lead (coordinator) can now edit `~/.claude` workflow files directly (persona files, skills, routine docs). Infrastructure scripts go to `lucos-system-administrator`. The `lucos-issue-manager` teammate no longer exists — its role is absorbed into the coordinator (loaded via `/team` skill).
- **Repository secrets and settings** (e.g. setting GitHub secrets, enabling auto-merge) must be done via the `lucos-system-administrator` persona, as it's the only one with permissions for these changes.
- **ADRs after system design**: Always create an ADR after completing a full system design or re-design. Route to `lucos-architect` persona.
- **Don't bulk-re-quote agent output to the user.** Claude Code's UI now renders teammate messages directly to lucas42, so he reads each `<teammate-message …>` block as it arrives. Repeating its content verbatim duplicates text in his view. Limit own messages to coordinator-level framing, decisions made, and the specific user-input question. Verbatim relay still applies to SendMessage *between* agents (where the destination agent doesn't see the original). (Updated 2026-05-21 — superseded the older "always relay verbatim" rule when the UI changed.)
- **Don't debug post-merge failures yourself.** When a build or deployment fails after a PR is merged, hand the investigation to the appropriate specialist persona (e.g. `lucos-site-reliability`) rather than diagnosing and pushing fixes directly. The dispatcher lacks the context and patience to trace through execution paths properly — specialist personas are better equipped for root cause analysis. (Learned from a Kotlin DSL variable-shadowing bug that was misdiagnosed as an empty env var.)

## External Tool References

- [arachne MCP tool name lookups](reference_arachne_mcp_tools.md) — `find_entities` returns `rdfs:label` (alternate names); use `get_entity` by URI for canonical `skos:prefLabel`
- [Media systems domain mapping](media-manager-domain-mapping.md) — lucos_configy/config/systems.yaml is canonical; beware lucos_media_manager (ceol.l42.eu) vs lucos_media_metadata_manager (media-metadata.l42.eu)

## GitHub Comment Conventions

- **Never use `#N` syntax for Dependabot alerts, CodeQL alerts, or secret-scanning alerts** in GitHub comments or PR descriptions. The `#N` syntax always links to issues/PRs, and alert numbering is separate. Instead, use the CVE or GHSA identifier (e.g. `CVE-2026-0540`, `GHSA-v2wj-7wpq-c8vv`) — GitHub auto-links these. If no CVE/GHSA exists, refer descriptively or use the full alert URL.

## Feedback

- [Don't auto-revert agent work](feedback_revert_policy.md) — when user says an agent shouldn't have done something, ask whether to revert rather than assuming revert is needed
- [Check before chasing](feedback_check_before_chasing.md) — don't repeatedly ask user to merge PRs; check PR state or system status first
- [Delegate questions to agents](feedback_delegate_not_guess.md) — when unsure about something, ask the most suitable agent rather than guessing
- [Labels managed by coordinator](feedback_labels_owner.md) — label creation/management is the coordinator's responsibility, not other personas
- [Developer message queue](feedback_developer_message_queue.md) — wait for developer to acknowledge corrections before dispatching new work; messages sent in quick succession get processed out of order
- [One actively-worked issue per agent](feedback_developer_one_issue_per_session.md) — agents are dispatchable-again once PR is open + summary posted; do NOT wait for review/merge before sending the next issue
- [Audit tool architecture is intentional](feedback_audit_architecture.md) — don't treat missing functionality as a bug; consult architect before proposing scope changes
- [Complete triage inline](feedback_triage_inline_consultation.md) — don't park issues as "needs-design"; do agent consultation inline and finish the triage
- [Never revert label changes blindly](feedback_never_revert_labels.md) — always read comments before changing labels back; someone changed them deliberately
- [Estate rollouts should use PRs](feedback_estate_rollout_prs.md) — prefer PRs over direct pushes; exceptions for trivial version-bump-style changes
- [Auto-commit ~/.claude changes](feedback_claude_config_commits.md) — commit and push changes to ~/.claude without asking
- [Developer rebase issues](feedback_developer_rebase.md) — developer doesn't reliably rebase; verify results or use alternative approaches
- [Auto-merge on approval](feedback_auto_merge_workflow.md) — PRs auto-merge when approved; don't ask user to manually merge
- [No transient dismissals](feedback_no_transient_dismissals.md) — never hand-wave unhealthy systems as "transient"; name them, explain the cause, and state when/how alerts will clear
- [Correct agents when wrong](feedback_correct_agents.md) — when an agent reports something factually incorrect, correct them and prompt instruction updates
- [SendMessage has no broadcast mechanism](feedback_shutdown_no_broadcast.md) — to:"broadcast" / to:"*" goes to a phantom inbox; always fan out individual SendMessage calls per teammate
- [Follow archival checklist](feedback_follow_archival_checklist.md) — always use lucos/docs/repo-archival.md when decommissioning repos or systems
- [Triage agent-raised issues immediately](feedback_triage_agent_raised_issues.md) — when an agent says they've raised an issue, triage it inline; don't wait for the next triage run
- [No semver-major ignore rules](feedback_no_semver_major_ignore.md) — don't raise issues proposing Dependabot semver-major ignores; major bumps should flow through and CI should catch breakage
- [Consult github-workflow.md first](feedback_consult_github_workflow_doc.md) — when composing GitHub API instructions for agents, read the doc rather than recalling syntax (some PATCH fields silently ignored)
- [Don't endorse unverified analysis](feedback_no_unverified_endorsement.md) — verbatim relay is fine, but no editorial praise of agent reasoning unless I've checked the substance against ground truth
- [No inline lessons in instruction files](feedback_no_inline_lessons.md) — keep persona/skill text lean; put "Lesson from {date}" narrative in the commit message, not the file
- [Question whether an issue should exist](feedback_question_issue_existence.md) — before triaging an agent-raised issue, check if it duplicates an existing tracking surface with a fully automated resolution path
- [Dispatch what /next returns](feedback_dispatch_what_next_returns.md) — never reposition or skip an item /next returns based on labels or recent context; lucas42's manual board positioning is authoritative
- [Don't act on ambiguous user replies](feedback_ambiguous_user_reply.md) — if a reply could answer either of two posed questions, ask which; avoid parallel-labeling collisions across sections
- [Scope checks belong to reviewer](feedback_scope_checks_belong_to_reviewer.md) — PR-scope-vs-issue verification is code-reviewer's responsibility, not the coordinator's
- [Ask about the plan first](feedback_ask_about_the_plan_first.md) — when relaying a multi-part agent plan, AskUserQuestion must lead with a plan-shape question, not just the niche details the agent flagged
- [Re-fetch before accusing](feedback_refetch_before_accusing.md) — when a coordinator message contains a factual claim about another agent's GitHub state, re-fetch right before send, not at start of composing
- [Ticket decisions are async](feedback_ticket_decisions_async.md) — don't AskUserQuestion to force synchronous answers on ticket routing; the ticket itself is the asynchronous venue. Continue dispatching other ready work while waiting.
- [Template substitution in gh-as-agent](feedback_template_substitution.md) — bodies with `{repo}`/`{owner}` placeholders or leading `@`-mentions get silently corrupted by `gh api`; use the file-backed pattern
- [No every-user-turn polling](feedback_no_every_turn_polling.md) — don't propose "re-check X on every user turn" as an instruction fix; produces weird inconsistencies
- [Phantom teammate messages](feedback_phantom_teammate_messages.md) — I sometimes confabulate fake `<teammate-message>` blocks OR tool output in my own reasoning and read them back as real (esp. when primed to expect a problem); verify against the actual result block / teammate jsonls, not my own narration
- [Re-fetch issue comments before following up](feedback_refetch_issue_comments_before_following_up.md) — never post a progress/status comment on a GitHub issue without re-fetching its comments first, even on an issue I just filed
- [Disambiguate AskUserQuestion layers](feedback_askuserquestion_layer_disambiguation.md) — option labels must name the system layer when the action could happen at multiple layers (code vs detector vs config)
- [Migration scope matches spec scope](feedback_migration_scope_matches_spec.md) — when briefing a teammate to apply a spec / convention / rollout, the brief covers only what the spec requires; no adjacent "while you're at it" checks
- [Ready means fully implementable](feedback_ready_means_fully_implementable.md) — if any cross-repo dependency is open, the issue is Blocked, not Ready, regardless of "parallel unit-testable" framings
- [Verify project-state before citing](feedback_verify_project_state_before_citing.md) — never cite "parked / deferred / completed" from a MEMORY.md index line; re-read the memory file AND verify against the live ticket/board
- [Don't shift work to coordinator](feedback_dont_shift_work_to_coordinator.md) — don't add workflow rules that move issue-close work (or similar) from GitHub automation onto the coordinator without lucas42 asking; trust the automation + brief transient inconsistencies
- [Verify identifiers before propagating](feedback_verify_before_propagating.md) — when fan-out propagating a teammate's concrete identifier (URL/domain/repo/path) into multiple GitHub bodies, verify against an authoritative source first; an agent's report is not a verified fact
- [No options in specialist consultations](feedback_no_options_in_consultations.md) — relay lucas42's design question verbatim; never augment with my own option list or "options I see" framing, which biases the agent toward the obvious defaults
- [No verbatim quotes on the ticket](feedback_no_verbatim_quotes_on_ticket.md) — triage-decision comments on a ticket should be brief and reference prior comments by position; verbatim quotes are for SendMessage (where the inbox doesn't show the thread), not for the ticket itself
- [Dependabot recreate is deterministic](feedback_dependabot_recreate_deterministic.md) — never relay/endorse `@dependabot recreate` as a fix unless an input has demonstrably changed; recreate produces the same lockfile from the same inputs
- [Verify permission claims before asserting](feedback_verify_permission_claims.md) — never write "{bot} doesn't have permission to X" or "only lucas42 can X" without probing the API or the App's permission listing; propagating unverified permission claims creates work for lucas42 that a bot could have done
- [Don't gate read-only checks](feedback_no_gate_on_readonly_checks.md) — just run safe read-only verifications and report; confirm-first is only for state-changing/outward-facing actions, not for reading production state
- [Dispatch URL only](feedback_dispatch_url_only.md) — dispatch SendMessage carries only `implement issue {url}`; never restate the ticket's design (redundant + an unversioned copy that can contradict the ticket)
- [Harness problems → lucos#155](feedback_harness_problems_to_lucos155.md) — Claude Code harness/product-layer limitations (not infra/config-fixable) are tracked on lucas42/lucos#155; comment there, don't strand on per-repo tickets
- [Empty tool output = unknown, never data](feedback_treat_empty_tool_output_as_unknown.md) — treat any empty/blank/late tool result as unknown; re-run or wait before asserting (receiver-side mitigation for confabulation-on-empty; captured for SRE during 2026-05-30 shutdown)

## Active Projects

- [Stuck PR workflow overhaul](project_stuck_pr_workflow.md) — new detection/resolution process in agent instructions (2026-03-19), with known stuck PRs left as a live test for the next session
- [Media API v2→v3 migration](project_v3_migration.md) — completed and removed from strategic priorities as of 2026-04-08; lucos-lang deprecation was the final milestone
- [Auth fail-open/fail-closed unresolved](project_auth_failopen_question.md) — verify and document when auth service work happens; raised during 2026-04-11 incident investigation

## Agent Instruction Compliance (ADR-0001 in lucos_claude_config)

- Long persona files suffer from attention degradation — agents skip instructions deep in the file and confabulate when asked why.
- Key mitigations applied (2026-03-06): ops checks for SRE, sysadmin, and security were extracted into separate `*-ops-checks.md` files with explicit counts, criticality ordering, schedule grouping, and mandatory completion manifests. **These changes are untested** due to the caching issue above — need a fresh Claude session to verify.
- The architect's MEMORY.md is 203 lines (3 over the 200-line truncation limit) — needs trimming.


- [No parallel get-next/dispatch](feedback_no_parallel_getnext_dispatch.md) — run get-next to completion and dispatch exactly the URL it printed; never pre-fill /dispatch from memory (confabulated lucos_monitoring#286 on 2026-05-30)

- [No confabulated quotes in consult relay](feedback_confabulated_quote_in_consult_relay.md) — paste verbatim quotes from the just-fetched tool result, never from memory (fabricated a lucas42 #264 comment to the architect on 2026-05-30)
