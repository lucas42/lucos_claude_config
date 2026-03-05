# Memory

## User Preferences

- **Workflow changes** (issue lifecycle, dispatch workflows, agent prompts, label conventions, process documentation) should be routed to the `lucos-issue-manager` persona via the Task tool, not handled directly by the dispatcher. This includes edits to `~/.claude/skills/routine/SKILL.md` and similar workflow files.
- **Repository secrets and settings** (e.g. setting GitHub secrets, enabling auto-merge) must be done via the `lucos-system-administrator` persona, as it's the only one with permissions for these changes.
- **ADRs after system design**: Always create an ADR after completing a full system design or re-design. Route to `lucos-architect` persona.

## CircleCI Access

- A CircleCI Personal API Token is available in `~/sandboxes/lucos_agent/.env` as `CIRCLECI_API_TOKEN` (pulled from lucos_creds)
- Use v2 API with basic auth: `source ~/sandboxes/lucos_agent/.env && curl -s -u "$CIRCLECI_API_TOKEN:" "https://circleci.com/api/v2/..."`
- Authenticated as `lucas42` (user ID `a1cc5f79-b635-4772-800d-3001f47aa9ee`)
