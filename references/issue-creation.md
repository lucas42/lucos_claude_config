# Creating Issues

When asked to create a new issue:

1. **Search for duplicates first.** Before creating any issue, search the target repo and the org broadly for existing open issues that cover the same problem.

   **Regressions get new issues — never re-open old ones.** If a bug was previously fixed and has now regressed, create a new issue describing the regression. Re-opening the original issue conflates two separate occurrences, loses the history of the original fix, and confuses the timeline. Reference the original issue in the new one for context.

2. **Clarify before writing** if the request is vague.

3. **Write a thorough issue** that includes:
   - A clear, concise title.
   - A description of the problem or goal.
   - Acceptance criteria (what does "done" look like?).
   - Any known constraints or context.
   - Open questions, if any exist.

   **Issue-number references inside the body must always be real issue numbers, never sequence labels.** When drafting a series of related issues (e.g. "ticket 1 / ticket 2 / ticket 3"), it is tempting to write `#1`, `#2`, `#3` as ordinal labels for the sequence — but GitHub autolinks `#N` to issue number N **in the same repo**, which on any active repository will be a real, unrelated ticket from years ago. The link is silent and the corruption is invisible in the source markdown. Two safe patterns: (a) file the earlier issues first and then reference their actual numbers in the later bodies, or (b) draft with a non-`#` placeholder (e.g. `[seq-1]`) and substitute the real numbers as you file. If you've already filed a body with sequence labels, fix it via PATCH before triage runs.

   **When a ticket is Blocked on another, the "## Dependencies" section MUST include the blocker's literal `#N` (or cross-repo `lucas42/other_repo#N`).** The `/dispatch` skill's auto-unblock check finds dependencies via literal substring grep — prose like "Blocked on the phase-1 ticket" without the number is invisible to the check, so dependents never auto-unblock when the prerequisite closes. Any form with `#N` works: `Blocked on #254`, `Blocked on the phase-1 ticket (#254)`, or a list-style `Blocked by: #254`. Keep the prose description for humans — just make sure the number is also literally present.

   **Acceptance criteria that search `~/.claude` for stale references must use `git -C ~/.claude grep`, never `grep -r ~/.claude`.** The `~/.claude/.gitignore` file starts with `*` / `.*` followed by negation rules (`!agents/`, `!agent-memory/**`, …), which is an "ignore everything then un-ignore the tracked subtrees" pattern. Any grep tool that respects `.gitignore` / `.ignore` files (ripgrep when run inside a git repo, fd, several editor greps) honours the leading `*` and silently skips entire subdirectories — exiting 0 with no output, as if no matches existed. The failure mode is **invisible**: the acceptance check passes while stale references remain in `agents/`, `agent-memory/`, `references/`, `skills/`, etc. Two safe patterns:

   - **Preferred:** `git -C ~/.claude grep PATTERN` — greps everything in the git index regardless of file type, fully respects `.gitignore` semantics rather than just the leading `*`, and is one short command.
   - **Alternative when narrowing by extension:** `find ~/.claude -name "*.md" -not -path "*/.git/*" -print0 | xargs -0 grep -l PATTERN` — bypasses `.gitignore` entirely by using `find` rather than recursive grep. Use this only when you specifically want to filter by extension; otherwise prefer `git grep`.

   When drafting an acceptance criterion that checks for stale references in `~/.claude`, write the command in the criterion itself so reviewers (and the implementing teammate) use the safe form. Example: "Acceptance: `git -C ~/.claude grep LUCOS_CONTACTS_URL` returns no matches." Lesson from `lucos_claude_config#85`: an acceptance check that used `grep -rn LUCOS_CONTACTS_URL ~/.claude/` matched only `CLAUDE.md` and missed the same string in `agents/lucos-system-administrator.md` and `agent-memory/lucos-site-reliability/MEMORY.md`, allowing an incomplete rollout to land.

4. **Create the issue** using `gh-as-agent`. There are two patterns; **pick the right one for your body content**:

   **Pattern A — inline heredoc** (use only for short, simple bodies with no path-template placeholders):

   ```bash
   ~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues \
       --method POST \
       -f title="Issue title" \
       --field body="$(cat <<'ENDBODY'
   Short issue body with `code` and **markdown**.
   ENDBODY
   )"
   ```

   **Pattern B — file-backed body (REQUIRED whenever the body contains `{owner}`, `{repo}`, or any other curly-brace placeholder, even inside backticks or markdown code blocks):**

   ```bash
   BODY_FILE=$(mktemp)
   cat > "$BODY_FILE" <<'ENDBODY'
   Issue body that mentions API paths like `GET /repos/{owner}/{repo}/issues`,
   placeholder syntax, or any other curly-brace text.
   ENDBODY
   ~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues \
       --method POST \
       -f title="Issue title" \
       --field "body=@$BODY_FILE"
   rm "$BODY_FILE"
   ```

   **Why Pattern B is required:** `gh api` performs template substitution on `{owner}/{repo}` (and similar tokens) **inside argument values**, including inside `--field body="..."`. The single-quoted heredoc only blocks shell expansion; the substitution happens downstream inside `gh` itself. Documentation-style placeholders get silently rewritten to real repo names in the posted text — and the corruption is not visible in the heredoc you wrote, only in the final issue. If in doubt, use Pattern B.

   The same rule applies to `PATCH` calls that update an existing issue body (`repos/.../issues/{number}` with `--method PATCH`) and to comments (`repos/.../issues/{number}/comments`).

5. **Add the issue to the project board** immediately after creation. Read `~/.claude/references/triage-reference-data.md` for field IDs and API patterns.

6. **Hand off to the coordinator for triage.** Workflow state management (setting Status, Priority, and Owner fields on the project board) beyond initial placement are coordinator-only responsibilities — non-coordinator personas have a standing rule against managing labels or project field values (see `~/.claude/references/label-workflow.md`). After filing the issue and adding it to the board, send the issue URL to the coordinator (`team-lead`) via SendMessage so they can complete triage.

   **If you ARE the coordinator**, triage the issue inline yourself — assess against the triage criteria, set the Status/Priority/Owner fields on the board, and position by priority. Follow the procedure in `~/.claude/references/triage-procedure.md`. Do not park the issue and wait for a separate triage pass.
