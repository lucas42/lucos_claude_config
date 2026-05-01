# Memory

## Dispatcher Workflows

- **PR review loop**: The review loop is now the responsibility of the implementation teammate, not the dispatcher. After creating a PR, the teammate drives the loop itself (messaging `lucos-code-reviewer`, addressing feedback, handling specialist reviews) and reports the outcome when done. See `~/.claude/pr-review-loop.md`.

## User Preferences

- **Workflow and config changes**: The team-lead (coordinator) can now edit `~/.claude` workflow files directly (persona files, skills, routine docs). Infrastructure scripts go to `lucos-system-administrator`. The `lucos-issue-manager` teammate no longer exists — its role is absorbed into the coordinator (loaded via `/team` skill).
- **Repository secrets and settings** (e.g. setting GitHub secrets, enabling auto-merge) must be done via the `lucos-system-administrator` persona, as it's the only one with permissions for these changes.
- **ADRs after system design**: Always create an ADR after completing a full system design or re-design. Route to `lucos-architect` persona.
- **Don't paraphrase agent output in ad-hoc conversations.** When relaying what a persona said back to the user, show the agent's full response verbatim. Only summarise during pre-defined skills (e.g. `/routine`, `/next`). The user wants to see exactly what the persona said, in its own words.
- **Don't debug post-merge failures yourself.** When a build or deployment fails after a PR is merged, hand the investigation to the appropriate specialist persona (e.g. `lucos-site-reliability`) rather than diagnosing and pushing fixes directly. The dispatcher lacks the context and patience to trace through execution paths properly — specialist personas are better equipped for root cause analysis. (Learned from a Kotlin DSL variable-shadowing bug that was misdiagnosed as an empty env var.)

## External Tool References

- [arachne MCP tool name lookups](reference_arachne_mcp_tools.md) — `find_entities` returns `rdfs:label` (alternate names); use `get_entity` by URI for canonical `skos:prefLabel`

## GitHub Comment Conventions

- **Never use `#N` syntax for Dependabot alerts, CodeQL alerts, or secret-scanning alerts** in GitHub comments or PR descriptions. The `#N` syntax always links to issues/PRs, and alert numbering is separate. Instead, use the CVE or GHSA identifier (e.g. `CVE-2026-0540`, `GHSA-v2wj-7wpq-c8vv`) — GitHub auto-links these. If no CVE/GHSA exists, refer descriptively or use the full alert URL.

## Feedback

- [Don't auto-revert agent work](feedback_revert_policy.md) — when user says an agent shouldn't have done something, ask whether to revert rather than assuming revert is needed
- [Check before chasing](feedback_check_before_chasing.md) — don't repeatedly ask user to merge PRs; check PR state or system status first
- [Delegate questions to agents](feedback_delegate_not_guess.md) — when unsure about something, ask the most suitable agent rather than guessing
- [Labels managed by coordinator](feedback_labels_owner.md) — label creation/management is the coordinator's responsibility, not other personas
- [Developer message queue](feedback_developer_message_queue.md) — wait for developer to acknowledge corrections before dispatching new work; messages sent in quick succession get processed out of order
- [Audit tool architecture is intentional](feedback_audit_architecture.md) — don't treat missing functionality as a bug; consult architect before proposing scope changes
- [Complete triage inline](feedback_triage_inline_consultation.md) — don't park issues as "needs-design"; do agent consultation inline and finish the triage
- [Never revert label changes blindly](feedback_never_revert_labels.md) — always read comments before changing labels back; someone changed them deliberately
- [Estate rollouts should use PRs](feedback_estate_rollout_prs.md) — prefer PRs over direct pushes; exceptions for trivial version-bump-style changes
- [Auto-commit ~/.claude changes](feedback_claude_config_commits.md) — commit and push changes to ~/.claude without asking
- [Developer rebase issues](feedback_developer_rebase.md) — developer doesn't reliably rebase; verify results or use alternative approaches
- [Auto-merge on approval](feedback_auto_merge_workflow.md) — PRs auto-merge when approved; don't ask user to manually merge
- [No transient dismissals](feedback_no_transient_dismissals.md) — never hand-wave unhealthy systems as "transient"; name them, explain the cause, and state when/how alerts will clear
- [Correct agents when wrong](feedback_correct_agents.md) — when an agent reports something factually incorrect, correct them and prompt instruction updates
- [Don't broadcast shutdown requests](feedback_shutdown_no_broadcast.md) — structured messages can't be broadcast; send individual shutdown_request to each teammate
- [Follow archival checklist](feedback_follow_archival_checklist.md) — always use lucos/docs/repo-archival.md when decommissioning repos or systems
- [Triage agent-raised issues immediately](feedback_triage_agent_raised_issues.md) — when an agent says they've raised an issue, triage it inline; don't wait for the next triage run
- [No semver-major ignore rules](feedback_no_semver_major_ignore.md) — don't raise issues proposing Dependabot semver-major ignores; major bumps should flow through and CI should catch breakage
- [Consult github-workflow.md first](feedback_consult_github_workflow_doc.md) — when composing GitHub API instructions for agents, read the doc rather than recalling syntax (some PATCH fields silently ignored)

## Active Projects

- [Stuck PR workflow overhaul](project_stuck_pr_workflow.md) — new detection/resolution process in agent instructions (2026-03-19), with known stuck PRs left as a live test for the next session
- [Media API v2→v3 migration](project_v3_migration.md) — parked as of 2026-04-05; dual-format in weightings nearly done, broader migration deferred
- [Auth fail-open/fail-closed unresolved](project_auth_failopen_question.md) — verify and document when auth service work happens; raised during 2026-04-11 incident investigation

## Agent Instruction Compliance (ADR-0001 in lucos_claude_config)

- Long persona files suffer from attention degradation — agents skip instructions deep in the file and confabulate when asked why.
- Key mitigations applied (2026-03-06): ops checks for SRE, sysadmin, and security were extracted into separate `*-ops-checks.md` files with explicit counts, criticality ordering, schedule grouping, and mandatory completion manifests. **These changes are untested** due to the caching issue above — need a fresh Claude session to verify.
- The architect's MEMORY.md is 203 lines (3 over the 200-line truncation limit) — needs trimming.

