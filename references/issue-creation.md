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

   **Issue references in bodies and comments must use GitHub's autolinkable forms.** Two reasons: (i) the references then render as proper links in the GitHub UI, with hover-preview info that's useful when reviewing on the web; (ii) the `/dispatch` auto-unblock check finds dependencies by matching the same forms — a reference that doesn't autolink is also unlikely to be matchable. The autolinkable forms are:

   - Same-repo: bare `#N` (e.g. `#254`)
   - Cross-repo: `lucas42/other_repo#N` (the full `owner/repo` prefix is required)
   - Full URL: `https://github.com/lucas42/other_repo/issues/N` or `.../pull/N`

   Four common ways to break linking — avoid all of them in real ticket bodies (this documentation file uses backticks around examples for typographic reasons; bodies you file should not):

   - **Wrapping the reference in backticks.** A backticked reference is a code span; GitHub's linker skips it. The number remains for some greppers but the UI loses the link and the hover info.
   - **Short-form cross-repo references.** `other_repo#N` without the `lucas42/` prefix does not autolink. Always use `lucas42/other_repo#N` for cross-repo references.
   - **Sequence labels as `#N`.** When drafting a series of related issues (e.g. "ticket 1 / ticket 2 / ticket 3"), it is tempting to write `#1`, `#2`, `#3` as ordinal labels — but those autolink to whatever real issues those numbers happen to be in the repo, which on any active repository will be unrelated tickets from years ago. The link is silent and the corruption is invisible in the source markdown. Two safe patterns: (a) file the earlier issues first and then reference their actual numbers in later bodies, or (b) draft with a non-`#` placeholder (e.g. `[seq-1]`) and substitute the real numbers as you file. If you've already filed a body with sequence labels, fix it via PATCH before triage runs.
   - **Prose-only blocker references in `## Dependencies` sections.** Even when the prose is unambiguous to humans ("Blocked on the phase-1 ticket"), the `/dispatch` auto-unblock check needs the autolinkable reference to be literally present, or dependents never unblock when the prerequisite closes. Any of these work: `Blocked on #254`, `Blocked on the phase-1 ticket (#254)`, or a list-style `Blocked by: #254`. Keep the prose for readers — just make sure the reference is also there.

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

   **The body-file path must be absolute** (`mktemp` gives you one). `gh-as-agent` resolves an `@`-path from a different working directory than your interactive shell, so a relative path like `body=@notes.md` fails with `error parsing "body" value: open notes.md: no such file or directory` and nothing is posted. Don't hand-write body files to a local dir and reference them relatively.

   **`-f` and `--field` are NOT interchangeable for an `@file` value, even though plain `gh api` treats them as the same flag.** Only the long form, `--field "body=@$BODY_FILE"`, expands the `@`-path and reads the file. Using the short form for the body (`-f "body=@$BODY_FILE"`) posts the **literal string** `@/tmp/tmp.xxxxxx` as the issue body — silently, with no error, no warning, and a 200-status success response. This is easy to miss because `-f title="..."` for a plain string value is fine and is exactly what the pattern above uses — the bug only bites when `-f` is used for the `@file` argument specifically. Always use `--field` for the body in Pattern B; if you do use `-f` for it by mistake, the resulting issue's `body` field will literally start with `@/tmp/...` in the API response — check for that after every issue creation that uses Pattern B, and `PATCH` the correct body via `--field` if you spot it.

   **Why Pattern B is required:** `gh api` performs template substitution on `{owner}/{repo}` (and similar tokens) **inside argument values**, including inside `--field body="..."`. The single-quoted heredoc only blocks shell expansion; the substitution happens downstream inside `gh` itself. Documentation-style placeholders get silently rewritten to real repo names in the posted text — and the corruption is not visible in the heredoc you wrote, only in the final issue. If in doubt, use Pattern B.

   The same rule applies to `PATCH` calls that update an existing issue body (`repos/.../issues/{number}` with `--method PATCH`) and to comments (`repos/.../issues/{number}/comments`).

   **Before you POST, grep the body for backticked references.** The rules in step 3 are widely known and still get broken, because backticks are *correct* formatting for filenames, env vars and function names — the habit is right everywhere except here, and it misfires specifically while authoring a structured body, not while writing prose in a comment. So check mechanically rather than relying on recall:

   ```bash
   grep -nE '`[^`]*#[0-9]+[^`]*`' "$BODY_FILE"   # any hit: inspect it before posting
   ```

   **This is a warning to eyeball, never a gate — do not "fix" it into a hard block.** It has known, legitimate hits: a six-digit hex colour (`#123456`) in a UX ticket, and any fenced block that deliberately shows a backticked reference while documenting this very rule (this file would trip it). Blocking on those would stop correct bodies being filed.

   On a real hit, there are two remedies and the right one depends on intent: if it *is* a reference, strip the backticks (`lucas42/lucos#292` → lucas42/lucos#292); if you meant to name a number **without** linking it, drop the `#` instead ("issue 292 in lucos") — never reach for backticks to suppress a link.

   Note the check covers **one** of the four failure modes in step 3. A clean grep says nothing about short-form cross-repo references, sequence labels, or a `## Dependencies` section with no autolinkable reference in it at all — those still need reading the body. Treat a pass as "not this bug", not "body is fine".

   **Why it earns a check when a prose rule already exists:** the failure is silent and machine-only. A backticked blocker leaves the ticket stranded in Blocked with its prerequisite already merged — `skills/dispatch/check-dependent` strips code spans before matching, deliberately, to mirror the autolinker — while the body reads perfectly to a human and states its dependency unambiguously. Nothing errors and nothing alerts; the ticket simply never becomes Ready. (2026-08-30: both lucas42/lucos#250 follow-ups filed this way. The unblock sweep returned "not dependent" for both, and it was caught only because the coordinator had read the bodies earlier that session and remembered — luck, not a control.)

5. **Add the issue to the project board** immediately after creation, using **`~/sandboxes/lucos_agent/gh-projects`** — *not* `gh-as-agent`. GitHub Apps cannot access v2 user projects, so `gh-as-agent graphql … addProjectV2ItemById` returns `FORBIDDEN: Resource not accessible by integration`; `gh-projects` authenticates with a PAT that has project scope. Read `~/.claude/references/triage-reference-data.md` for field IDs and further API patterns.

   ```bash
   NODE=$(~/sandboxes/lucos_agent/gh-as-agent --app <persona> repos/lucas42/<repo>/issues/<N> --jq '.node_id')
   ~/sandboxes/lucos_agent/gh-projects graphql -f query='
   mutation($pid:ID!,$cid:ID!){ addProjectV2ItemById(input:{projectId:$pid, contentId:$cid}){ item { id } } }
   ' -f pid='PVT_kwHOAAaLL84BRh5d' -f cid="$NODE" --jq '.data.addProjectV2ItemById.item.id'
   ```

   **Run creation, board-add, and field-setting as separate commands — not one bundled script.** If they are bundled and the call is interrupted or rejected, earlier steps may have already executed, orphaning a created-but-unconfigured issue. After *any* interrupted or rejected side-effecting command, re-fetch the actual state (does the issue exist? is it on the board?) before asserting what happened — never conclude "nothing was created" from the tool verdict alone.

6. **Hand off to the coordinator for triage.** Workflow state management (setting Status, Priority, and Owner fields on the project board) beyond initial placement are coordinator-only responsibilities — non-coordinator personas have a standing rule against managing labels or project field values (see `~/.claude/references/label-workflow.md`). After filing the issue and adding it to the board, send the issue URL to the coordinator (`team-lead`) via SendMessage so they can complete triage.

   **If you ARE the coordinator**, triage the issue inline yourself — assess against the triage criteria, set the Status/Priority/Owner fields on the board, and position by priority. Follow the procedure in `~/.claude/references/triage-procedure.md`. Do not park the issue and wait for a separate triage pass.
