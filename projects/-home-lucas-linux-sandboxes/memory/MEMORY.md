# Memory

## Dispatcher Workflows

- **PR review loop**: The review loop is now the responsibility of the implementation teammate, not the dispatcher. After creating a PR, the teammate drives the loop itself (messaging `lucos-code-reviewer`, addressing feedback, handling specialist reviews) and reports the outcome when done. See `~/.claude/pr-review-loop.md`.

## User Preferences

- **Workflow changes** (issue lifecycle, dispatch workflows, agent prompts, label conventions, process documentation) should be routed to the `lucos-issue-manager` teammate via SendMessage, not handled directly by the dispatcher. This includes edits to `~/.claude/skills/routine/SKILL.md` and similar workflow files.
- **All changes to `~/.claude` files** (persona files, skills, workflow docs — anything tracked in `lucos_claude_config`) must be delegated to a teammate from the start. The dispatcher should never edit these files directly then hand off to a teammate just for the commit. The teammate doing the work needs full context of the changes, so it should make the edits itself. **Route claude config changes to `lucos-issue-manager` by default** — only split the work if there's a related script to create/update, in which case `lucos-system-administrator` handles the script and `lucos-issue-manager` handles the rest.
- **Repository secrets and settings** (e.g. setting GitHub secrets, enabling auto-merge) must be done via the `lucos-system-administrator` persona, as it's the only one with permissions for these changes.
- **ADRs after system design**: Always create an ADR after completing a full system design or re-design. Route to `lucos-architect` persona.
- **Don't paraphrase agent output in ad-hoc conversations.** When relaying what a persona said back to the user, show the agent's full response verbatim. Only summarise during pre-defined skills (e.g. `/routine`, `/next`). The user wants to see exactly what the persona said, in its own words.
- **Don't debug post-merge failures yourself.** When a build or deployment fails after a PR is merged, hand the investigation to the appropriate specialist persona (e.g. `lucos-site-reliability`) rather than diagnosing and pushing fixes directly. The dispatcher lacks the context and patience to trace through execution paths properly — specialist personas are better equipped for root cause analysis. (Learned from a Kotlin DSL variable-shadowing bug that was misdiagnosed as an empty env var.)

## GitHub Comment Conventions

- **Never use `#N` syntax for Dependabot alerts, CodeQL alerts, or secret-scanning alerts** in GitHub comments or PR descriptions. The `#N` syntax always links to issues/PRs, and alert numbering is separate. Instead, use the CVE or GHSA identifier (e.g. `CVE-2026-0540`, `GHSA-v2wj-7wpq-c8vv`) — GitHub auto-links these. If no CVE/GHSA exists, refer descriptively or use the full alert URL.

## Loganne as a Communication Channel

- **Planned maintenance events**: When performing planned maintenance (reboots, migrations, etc.), post a custom Loganne event so other agents (especially lucos-site-reliability) can distinguish planned downtime from incidents. Use `~/sandboxes/lucos_agent/loganne-event <type> <humanReadable>` — no auth required, source is hardcoded to `lucos_agent`. Note: Loganne is in-memory, so also leave a durable record (e.g. GitHub comment) for long-term reference.


## Agent Instruction Compliance (ADR-0001 in lucos_claude_config)

- Long persona files suffer from attention degradation — agents skip instructions deep in the file and confabulate when asked why.
- Key mitigations applied (2026-03-06): ops checks for SRE, sysadmin, and security were extracted into separate `*-ops-checks.md` files with explicit counts, criticality ordering, schedule grouping, and mandatory completion manifests. **These changes are untested** due to the caching issue above — need a fresh Claude session to verify.
- The architect's MEMORY.md is 203 lines (3 over the 200-line truncation limit) — needs trimming.

## CircleCI Access

- A CircleCI Personal API Token is available in `~/sandboxes/lucos_agent/.env` as `CIRCLECI_API_TOKEN` (pulled from lucos_creds)
- Use v2 API with basic auth: `source ~/sandboxes/lucos_agent/.env && curl -s -u "$CIRCLECI_API_TOKEN:" "https://circleci.com/api/v2/..."`
- Authenticated as `lucas42` (user ID `a1cc5f79-b635-4772-800d-3001f47aa9ee`)
