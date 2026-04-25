# Persona Consistency Audit Procedure

This file is read by `lucos-system-administrator` when running a persona consistency audit.

## When to Run

- When asked directly (e.g. "audit persona consistency", "check persona files for drift")
- When a new persona has just been created via `/agents`
- When an issue is raised requesting it

## How to Run

1. **Read the reference**: `~/.claude/agents/common-sections-reference.md` defines the canonical version of each common section with `{placeholder}` markers.

2. **Read identity data**: `~/sandboxes/lucos_agent/personas.json` provides the persona-specific values (`bot_name`, `bot_user_id`, etc.) to substitute into the placeholders.

3. **Read each persona file**: `~/.claude/agents/lucos-*.md` (excluding `common-sections-reference.md` itself).

4. **Compare each common section** in the persona file against the reference, substituting the correct persona-specific values. Check every section defined in the reference file — some sections have notes indicating they don't apply to certain personas (e.g. "The coordinator does NOT have this section"). Respect those exclusions.

5. **Fix drift** by editing the persona file. Preserve the surrounding persona-specific context — only update the common section content to match the reference. Be careful not to remove persona-specific additions (e.g. lucos-security has an extra dependabot step between the issue discovery steps — that's an addition, not drift).

5.5. **Check the coordinator persona.** `~/.claude/agents/coordinator-persona.md` is not matched by the `lucos-*.md` glob, but it may still need updating when common sections change. Review the reference file's exclusion notes — if a new common section does NOT have a coordinator exclusion note, check whether it should be added to the coordinator persona too. The coordinator has its own versions of some sections (e.g. its own `~/.claude` maintenance instructions instead of the "Committing ~/.claude Changes" section), so use judgement.

6. **Check memory directory paths**: The canonical path is `/home/lucas.linux/.claude/agent-memory/{persona-name}/`. Flag and fix any that use a different base path (e.g. `/Users/lucas/`).

7. **Report findings**: List each persona checked, what drift was found (if any), and what was fixed. If a persona file is missing a common section entirely (e.g. a newly created persona that doesn't have the label workflow section), add it.

7.5. **Check `~/.bash_aliases`**: Verify that `~/.bash_aliases` contains a shell function for each persona file found in `~/.claude/agents/lucos-*.md`. Each persona should have a function (e.g. `lucos-architect() { _lucos_persona lucos-architect "$@"; }`) that calls the `_lucos_persona` helper. If any are missing, add them.

## Drift vs. Intentional Variation

- **Drift**: Different wording for the same instruction, wrong paths, wrong persona name in a command, missing warnings (e.g. the amend caveat in git commit identity).
- **Not drift**: Persona-specific sections that don't exist in the reference (e.g. "Reptile Facts" in code-reviewer, "Dependabot Alerts" step in security). Additional persona-specific "What to save" items in the memory section. Different section ordering or heading names, as long as the content is equivalent.

## After Fixing Drift

Commit all changes to the `~/.claude` repo (`lucas42/lucos_claude_config`) with a clear commit message listing which personas were updated and what was fixed.
