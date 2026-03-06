# Memory

## Dispatcher Workflows

- **PR review loop**: Whenever ANY persona creates a PR, the dispatcher MUST follow the structured loop in `~/.claude/pr-review-loop.md`. This means: tracking iteration count, launching `lucos-code-reviewer`, checking for approval/changes-requested/specialist-review, and routing feedback back to the implementation persona if needed. Never just fire-and-forget the code reviewer.

## User Preferences

- **Workflow changes** (issue lifecycle, dispatch workflows, agent prompts, label conventions, process documentation) should be routed to the `lucos-issue-manager` persona via the Task tool, not handled directly by the dispatcher. This includes edits to `~/.claude/skills/routine/SKILL.md` and similar workflow files.
- **Repository secrets and settings** (e.g. setting GitHub secrets, enabling auto-merge) must be done via the `lucos-system-administrator` persona, as it's the only one with permissions for these changes.
- **ADRs after system design**: Always create an ADR after completing a full system design or re-design. Route to `lucos-architect` persona.

## GitHub Comment Conventions

- **Never use `#N` syntax for Dependabot alerts, CodeQL alerts, or secret-scanning alerts** in GitHub comments or PR descriptions. The `#N` syntax always links to issues/PRs, and alert numbering is separate. Instead, use the CVE or GHSA identifier (e.g. `CVE-2026-0540`, `GHSA-v2wj-7wpq-c8vv`) — GitHub auto-links these. If no CVE/GHSA exists, refer descriptively or use the full alert URL.

## Loganne as a Communication Channel

- **Planned maintenance events**: When performing planned maintenance (reboots, migrations, etc.), post a custom Loganne event so other agents (especially lucos-site-reliability) can distinguish planned downtime from incidents. POST to `https://loganne.l42.eu/events` with `source`, `type` (e.g. `plannedMaintenance`), `humanReadable`, and optionally `url`. No auth required for writes. Note: Loganne is in-memory, so also leave a durable record (e.g. GitHub comment) for long-term reference.

## Agent Persona File Caching

- **Claude Code caches persona files at conversation start.** Changes to `~/.claude/agents/*.md` made mid-conversation are NOT picked up by new Task tool invocations — agents still receive the old version. A Claude restart is required to load updated persona files.
- This was confirmed on 2026-03-06: sysadmin restructured SRE persona files mid-conversation, but the SRE agent's system prompt still contained the old inline checks on subsequent launches.

## Agent Instruction Compliance (ADR-0001 in lucos_claude_config)

- Long persona files suffer from attention degradation — agents skip instructions deep in the file and confabulate when asked why.
- Key mitigations applied (2026-03-06): ops checks for SRE, sysadmin, and security were extracted into separate `*-ops-checks.md` files with explicit counts, criticality ordering, schedule grouping, and mandatory completion manifests. **These changes are untested** due to the caching issue above — need a fresh Claude session to verify.
- The architect's MEMORY.md is 203 lines (3 over the 200-line truncation limit) — needs trimming.

## CircleCI Access

- A CircleCI Personal API Token is available in `~/sandboxes/lucos_agent/.env` as `CIRCLECI_API_TOKEN` (pulled from lucos_creds)
- Use v2 API with basic auth: `source ~/sandboxes/lucos_agent/.env && curl -s -u "$CIRCLECI_API_TOKEN:" "https://circleci.com/api/v2/..."`
- Authenticated as `lucas42` (user ID `a1cc5f79-b635-4772-800d-3001f47aa9ee`)
