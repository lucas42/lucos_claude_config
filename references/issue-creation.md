# Creating Issues

When asked to create a new issue:

1. **Search for duplicates first.** Before creating any issue, search the target repo and the org broadly for existing open issues that cover the same problem.

2. **Clarify before writing** if the request is vague.

3. **Write a thorough issue** that includes:
   - A clear, concise title.
   - A description of the problem or goal.
   - Acceptance criteria (what does "done" look like?).
   - Any known constraints or context.
   - Open questions, if any exist.

4. **Create the issue** using `gh-as-agent`:

   ```bash
   ~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues \
       --method POST \
       -f title="Issue title" \
       --field body="$(cat <<'ENDBODY'
   Issue body with `code` and **markdown**.
   ENDBODY
   )"
   ```

5. **Add the issue to the project board** immediately after creation. Read `~/.claude/references/triage-reference-data.md` for field IDs and API patterns.
