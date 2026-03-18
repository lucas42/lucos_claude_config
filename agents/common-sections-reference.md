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

## Section: Teammate Communication

**All communication with teammates must use the `SendMessage` tool.** Plain text output is only visible to the user — it is NOT delivered to other agents. This applies to every message you send to a teammate: reporting task completion, asking a question, requesting a review, flagging a blocker.

If you respond to a teammate message in plain text rather than via `SendMessage`, they will never receive your reply. From their perspective, you ignored them.

This is not optional. It applies to every response to every teammate, including the dispatcher (team-lead), lucos-code-reviewer, and lucos-issue-manager.

---

## Section: GitHub Interactions

All GitHub interactions — posting comments, creating issues, creating pull requests, posting reviews — must use the `{persona-name}` GitHub App persona via the `gh-as-agent` wrapper script with `--app {persona-name}`:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app {persona-name} repos/lucas42/{repo}/issues \
    --method POST \
    -f title="Issue title" \
    --field body="$(cat <<'ENDBODY'
Issue body here with `code` and **markdown**.

Multi-line content, backticks, and special characters are all safe inside a heredoc.
ENDBODY
)"
```

**Important:** Always use a `<<'ENDBODY'` heredoc for the `body` field (as shown above). Using `-f body="..."` with inline content breaks newlines (they become literal `\n`) and backticks (the shell tries to execute them as commands). The heredoc pattern avoids both problems.

**Never** use `gh api` directly or `gh pr create` — those would post under the wrong identity. Never fall back to `lucos-agent` when acting as a different persona.

---

## Section: Git Commit Identity

Use the `git-as-agent` wrapper for all commit-writing git operations — **never** run `git config user.name` or `git config user.email`, as that would affect all future commits in the environment.

```bash
~/sandboxes/lucos_agent/git-as-agent --app {persona-name} commit -m "..."
~/sandboxes/lucos_agent/git-as-agent --app {persona-name} commit --amend
~/sandboxes/lucos_agent/git-as-agent --app {persona-name} cherry-pick abc123
~/sandboxes/lucos_agent/git-as-agent --app {persona-name} pull --rebase origin main
~/sandboxes/lucos_agent/git-as-agent --app {persona-name} rebase main
```

`git-as-agent` looks up the persona's `bot_name` and `bot_user_id` from `~/sandboxes/lucos_agent/personas.json` and prepends the correct `-c user.name=... -c user.email=...` flags automatically. All remaining arguments are passed through to `git`.

**Critical**: The `-c` flags set both the author and the committer. When git amends a commit, it preserves the original author but sets a **new committer** using the current identity — which without the wrapper will be the global git config (`lucos-agent[bot]`). This produces a commit where author and committer differ, which is incorrect.

**Always use `git-as-agent` for every git command that writes a commit**, including:
- `git commit -m "..."`
- `git commit --amend`
- `git cherry-pick`
- `git pull --rebase`
- `git rebase`
- Any other operation that creates or rewrites a commit

There is no safe "do this once" shortcut — every commit-writing operation needs the wrapper.

---

## Section: Working on GitHub Issues (PR/Commit Workflow)

When assigned to or asked to work on a GitHub issue:
1. **Post a starting comment** before any code changes — brief, first-person overview of your approach, posted via `gh-as-agent` as `{persona-name}`. Also update the project board status to "In Progress" (see "Project Board: In Progress" below).
2. **Start from an up-to-date main branch.** Before creating a feature branch, always pull the latest main: `git checkout main && git pull origin main`, then branch from there. This prevents the PR from being "behind main" — which blocks auto-merge on repos with strict branch protection and requires a manual rebase after the fact.
3. **Create PRs via `gh-as-agent`** — never `gh pr create`
4. **Tag commits and PRs** with the issue number (`Refs #N` in commits, `Closes #N` in PR body)
5. **Comment on unexpected obstacles** — don't silently get stuck
6. **Don't close issues manually** — they're closed automatically by the merged PR's closing keyword
7. **Follow the PR review loop** — after opening a PR, you are responsible for driving the review loop defined in [`pr-review-loop.md`](../pr-review-loop.md). Send a message to the `lucos-code-reviewer` teammate to request a review, address any feedback, and handle specialist reviews if requested. Do not report back to whoever asked you to do the work until the review loop completes (approval or 5-iteration cap). **Never merge PRs yourself** — they are merged either automatically (via the auto-merge workflow) or by a human. Just report the approval.

This section is also the workflow for the "implement issue {url}" prompt. The "Review and Implementation" intro tells the agent to follow this workflow then stop after opening one PR and completing the review loop. There is no separate "Implementing Issues" section — the PR/commit workflow here covers both review-triggered work and dispatcher-triggered implementation.

Some personas add persona-specific guidance below the 7-step list (e.g. lucos-architect notes that its implementation work is typically ADRs). These additions are NOT drift.

---

## Section: Scope of Work

This section appears in all implementation personas (developer, architect, sysadmin, SRE, security) near the top, after the prompts listing and inline consultation paragraph. The exact examples in parentheses vary per persona (e.g. "a drive-by bug" for developer, "a monitoring gap" for SRE). This variation is NOT drift.

**Only work on issues you have been explicitly assigned via SendMessage.** Issue selection and dispatch is handled by the team lead — you do not pick up issues yourself, even if you spot them while working in a repo. If you notice something worth fixing while working on your assigned issue (e.g. {persona-specific examples}), **raise a GitHub issue** for it rather than fixing it yourself. This ensures the work is triaged, prioritised, and tracked properly.

---

## Section: Project Board: In Progress

When starting work on an issue (step 1 of the "Working on GitHub Issues" workflow), update the **lucOS Issue Prioritisation** project board to set the issue's status to "In Progress". Use `~/sandboxes/lucos_agent/gh-projects` (not `gh-as-agent`) for project board API calls.

```bash
# Get the issue's node ID
ISSUE_NODE_ID=$(~/sandboxes/lucos_agent/gh-as-agent --app {persona-name} repos/lucas42/{repo}/issues/{number} --jq '.node_id')

# Add to project (idempotent) and get the project item ID
ITEM_ID=$(~/sandboxes/lucos_agent/gh-projects graphql -f query="
mutation {
  addProjectV2ItemById(input: {projectId: \"PVT_kwHOAAaLL84BRh5d\", contentId: \"$ISSUE_NODE_ID\"}) {
    item { id }
  }
}" --jq '.data.addProjectV2ItemById.item.id')

# Set status to "In Progress"
~/sandboxes/lucos_agent/gh-projects graphql -f query="
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: \"PVT_kwHOAAaLL84BRh5d\"
    itemId: \"$ITEM_ID\"
    fieldId: \"PVTSSF_lAHOAAaLL84BRh5dzg_VMcg\"
    value: {singleSelectOptionId: \"a24089a4\"}
  }) {
    projectV2Item { id }
  }
}"
```

If the issue is not yet on the project board, the `addProjectV2ItemById` call adds it. If it's already there, the call is a no-op and returns the existing item ID.

**Note:** lucos-issue-manager does NOT have this section — it manages the board separately as part of triage (see its "Project Board Sync" section). lucos-code-reviewer also does NOT have this section — it does not implement issues.

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
