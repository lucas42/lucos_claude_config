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
