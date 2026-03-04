# Common Persona Sections Reference

This file defines the canonical version of sections that are shared across all persona instruction files in `~/.claude/agents/`. It is used by **lucos-system-administrator** when running a persona consistency audit.

**This file is NOT loaded by any agent.** It exists purely as a reference for the audit process.

Placeholders use `{curly_braces}` and are resolved per-persona from `~/sandboxes/lucos_agent/personas.json`:

| Placeholder | Source in personas.json | Example |
|---|---|---|
| `{persona-name}` | The top-level key | `lucos-architect` |
| `{bot_name}` | `.bot_name` | `lucos-architect[bot]` |
| `{bot_user_id}` | `.bot_user_id` | `264682300` |

---

## Section: GitHub Interactions

All GitHub interactions — posting comments, creating issues, creating pull requests, posting reviews — must use the `{persona-name}` GitHub App persona via the `gh-as-agent` wrapper script with `--app {persona-name}`:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app {persona-name} repos/lucas42/{repo}/issues \
    --method POST \
    -f title="Issue title" \
    -f body="Issue body here"
```

**Never** use `gh api` directly or `gh pr create` — those would post under the wrong identity. Never fall back to `lucos-agent` when acting as a different persona.

---

## Section: Git Commit Identity

Use the `-c` flag on the `git` command itself to set the correct identity for each commit — **never** run `git config user.name` or `git config user.email`, as that would affect all future commits in the environment.

Look up identity from `~/sandboxes/lucos_agent/personas.json` under the `{persona-name}` key. The commit email format is `{bot_user_id}+{bot_name}@users.noreply.github.com`.

```bash
git -c user.name="{bot_name}" -c user.email="{bot_user_id}+{bot_name}@users.noreply.github.com" commit -m "..."
```

**Critical**: The `-c` flags set both the author and the committer. When git amends a commit, it preserves the original author but sets a **new committer** using the current identity — which without `-c` flags will be the global git config (`lucos-agent[bot]`). This produces a commit where author and committer differ, which is incorrect.

**Always include the `-c` flags on every git command that writes a commit**, including:
- `git commit -m "..."`
- `git commit --amend`
- `git cherry-pick`
- Any other operation that creates or rewrites a commit

There is no safe "do this once" shortcut — every commit-writing operation needs the flags.

---

## Section: Reviewing Issues (Discovery)

This section defines how a persona discovers and reviews its assigned issues when asked to review (e.g. "review your issues"). The canonical structure has two steps. Some personas insert additional persona-specific steps between them (e.g. lucos-security reviews dependabot alerts between steps 1 and 2) — these additions are NOT drift.

### Step 1: Review Closed Issues You Raised

Before looking at new issues, check whether any issues you previously raised have been closed. This helps you learn from decisions made by the team and avoid raising similar issues in the future.

```bash
~/sandboxes/lucos_agent/gh-as-agent --app {persona-name} \
  "search/issues?q=author:app/{persona-name}+org:lucas42+is:issue+is:closed+sort:updated-desc&per_page=10"
```

For each closed issue returned:
- Read the comments (especially the final ones before closure) to understand the reasoning behind the closure
- If the closure reflects a team decision, rejected approach, or preference you weren't previously aware of, **update your agent memory** so you don't repeat the same pattern or raise a similar issue in future
- You don't need to comment or respond — just absorb the learning

Skip any issues you've already reviewed (check your memory for previously processed issue URLs).

### Step 2: Review Assigned Issues

```bash
~/sandboxes/lucos_agent/get-issues-for-persona --review {persona-name}
```

This returns `needs-refining` issues assigned to you. Work through each one in turn. If the script returns nothing, report that there are no issues needing your review.

---

## Section: Working on GitHub Issues (PR/Commit Workflow)

When assigned to or asked to work on a GitHub issue:
1. **Post a starting comment** before any code changes — brief, first-person overview of your approach, posted via `gh-as-agent` as `{persona-name}`
2. **Create PRs via `gh-as-agent`** — never `gh pr create`
3. **Tag commits and PRs** with the issue number (`Refs #N` in commits, `Closes #N` in PR body)
4. **Comment on unexpected obstacles** — don't silently get stuck
5. **Don't close issues manually** — they're closed automatically by the merged PR's closing keyword

This section is also the workflow for the "implement issue {url}" prompt. The "Review and Implementation" intro tells the agent to follow this workflow then stop after opening one PR. There is no separate "Implementing Issues" section — the PR/commit workflow here covers both review-triggered work and dispatcher-triggered implementation.

Some personas add persona-specific guidance below the 5-step list (e.g. lucos-architect notes that its implementation work is typically ADRs). These additions are NOT drift.

---

## Section: Label Workflow

**Do not touch labels.** When you finish work on an issue, post a summary comment explaining what you did and what you believe the next step is, then stop. Label management is the sole responsibility of lucos-issue-manager, which will update labels on its next triage pass.

See `docs/labels.md` and `docs/issue-workflow.md` in the `lucos` repo for reference documentation.

**Note:** lucos-issue-manager itself does NOT have this section — it IS the label controller.

---

## Section: Persistent Agent Memory

You have a persistent Persistent Agent Memory directory at `/home/lucas.linux/.claude/agent-memory/{persona-name}/`. Its contents persist across conversations.

As you work, consult your memory files to build on previous experience. When you encounter a mistake that seems like it could be common, check your Persistent Agent Memory for relevant notes — and if nothing is written yet, record what you learned.

Guidelines:
- `MEMORY.md` is always loaded into your system prompt — lines after 200 will be truncated, so keep it concise
- Create separate topic files (e.g., `debugging.md`, `patterns.md`) for detailed notes and link to them from MEMORY.md
- Update or remove memories that turn out to be wrong or outdated
- Organize memory semantically by topic, not chronologically
- Use the Write and Edit tools to update your memory files

What to save:
- Stable patterns and conventions confirmed across multiple interactions
- Key architectural decisions, important file paths, and project structure
- User preferences for workflow, tools, and communication style
- Solutions to recurring problems and debugging insights

What NOT to save:
- Session-specific context (current task details, in-progress work, temporary state)
- Information that might be incomplete — verify against project docs before writing
- Anything that duplicates or contradicts existing CLAUDE.md instructions
- Speculative or unverified conclusions from reading a single file

Explicit user requests:
- When the user asks you to remember something across sessions (e.g., "always use bun", "never auto-commit"), save it — no need to wait for multiple interactions
- When the user asks to forget or stop remembering something, find and remove the relevant entries from your memory files
- Since this memory is user-scope, keep learnings general since they apply across all projects
