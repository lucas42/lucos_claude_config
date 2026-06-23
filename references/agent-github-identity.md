# Agent GitHub & git identity

How agents on the lucos team interact with GitHub and write commits. Applies to **every** persona.

Each persona has a corresponding GitHub App (`lucos-architect`, `lucos-developer`, `lucos-security`, etc.). All GitHub API calls and all commit-writing git operations must be attributed to the persona's own app — never the default `lucos-agent`, never personal credentials.

The persona's own bot identity is set by the `--app <persona>` flag on every wrapper call. Substitute your own persona name where this reference uses `<persona>`.

## GitHub API calls

Always use `~/sandboxes/lucos_agent/gh-as-agent --app <persona>` for all GitHub interactions — issues, pull requests, comments, reviews. Never use `gh` directly or fall back to another app's identity.

**Do not prefix the path with `api`.** The wrapper already runs `gh api …` internally, so the first positional argument should be the API path itself (e.g. `repos/lucas42/{repo}/issues`). Prepending `api` produces `gh api api repos/…`, which is treated as a literal path and returns a generic `404 Not Found` rather than a helpful error — easy to mistake for a permissions problem and chase the wrong cause.

```bash
# ✓ correct
~/sandboxes/lucos_agent/gh-as-agent --app <persona> repos/lucas42/{repo}/issues

# ✗ wrong — silent 404
~/sandboxes/lucos_agent/gh-as-agent --app <persona> api repos/lucas42/{repo}/issues
```

```bash
~/sandboxes/lucos_agent/gh-as-agent --app <persona> repos/lucas42/{repo}/issues/{number}/comments \
    --method POST \
    --field body="$(cat <<'ENDBODY'
Comment body with `code` and **markdown**.
ENDBODY
)"
```

**Always use a `<<'ENDBODY'` heredoc for the `body` field.** Using `-f body="..."` with inline content breaks newlines (they become literal `\n`) and backticks (the shell tries to execute them as commands). The heredoc pattern avoids both problems.

## The `gh api` template-substitution gotcha

`gh api` performs template substitution on `{owner}/{repo}` and `:owner/:repo` tokens **inside argument values**, including inside `--field body="..."`. This happens regardless of shell-quoting — the single-quoted heredoc only prevents shell expansion; the substitution happens downstream inside the `gh` CLI itself.

So documentation-style placeholders in a comment body (e.g. ``GET /repos/{owner}/{repo}/dependabot/secrets``) get silently rewritten to real repo names in the posted text — and the corruption is invisible until you read the posted comment or issue.

**A related but distinct gotcha — leading `@` is interpreted as a filename.** `gh api`'s `-f` / `--field` flag uses an `@`-prefix on the value to mean "read the value from this file". So a body that *starts with* a GitHub `@`-mention (e.g. `@lucas42 — please confirm…`) is interpreted as "open the file named `lucas42 — please confirm…`" and fails with `error parsing "body" value: open <text>: no such file or directory`. The body never gets posted, but the wrapper output may look successful if you don't check exit codes. This affects every coordinator comment that opens with an `@`-mention — i.e. most "@lucas42, please…" routing comments. The fix is the file-backed pattern below.

**The safe workaround — heredoc-captured variable (use this for all multi-line bodies):**

```bash
~/sandboxes/lucos_agent/gh-as-agent --app <persona> repos/lucas42/{repo}/issues/{N}/comments \
    --method POST \
    -f body="$(cat <<'ENDBODY'
Your body text, with {owner}/{repo} placeholders preserved verbatim.
ENDBODY
)"
```

`$(cat <<'ENDBODY' … ENDBODY)` captures the heredoc as a shell variable. The single-quoted delimiter prevents shell expansion of backticks and `$`. Newlines are preserved. **Do not use `--field "body=@$BODY_FILE"` (passes the literal path string, not file contents)** and **do not use `--field body-file=$FILE`** (silently creates an ignored field). Both patterns fail silently — the body ends up as a path string or null with no error from the wrapper.

**If the body contains curly-brace placeholders** (e.g. `{owner}/{repo}` in prose): `gh api` performs template substitution on these tokens inside field values regardless of shell quoting. To prevent this, reword the prose to avoid the `{owner}/{repo}` syntax — use the docs title instead.

The same gotcha applies to `PATCH` calls that update an existing issue/PR body and to comments. See [`references/issue-creation.md`](issue-creation.md) for the canonical issue-creation patterns.

**Always verify the comment/body rendered after posting.** Every failure mode above (`@path` literal, ignored `body-file` field, `{owner}/{repo}` substitution) fails *silently* — the wrapper returns an `html_url` and a success exit code while the body on the record is a path string, null, or corrupted text. The only reliable detection is to re-fetch and check: `gh-as-agent --app <persona> repos/lucas42/{repo}/issues/comments/{id} --jq '.body[0:80]'` and confirm it's your intended content (not starting with `@`, no leftover `{owner}` tokens). Treat this as the same non-optional step as confirming a deploy shipped the right commit — a silent `@path` glitch otherwise strands the entire write (e.g. a design write-up left unposted while only the superseded version stays visible).

## What never to do

- **Never** use `gh api` directly (without the wrapper) — it would post under the wrong identity.
- **Never** use `gh pr create` — same reason; use the API endpoint via `gh-as-agent` instead.
- **Never** fall back to `lucos-agent` or another persona's app when acting as your persona.

## Credential isolation: never use another agent's credentials

Each persona authenticates with its own GitHub App credentials. **Never run `gh-as-agent --app <other-persona>` to work around a missing permission on your own credentials**, regardless of how convenient the workaround looks. This is a hard rule, not a guideline:

- If your `--app <yourself>` call returns 403, the correct response is to **escalate the missing permission** (raise an issue, ask lucas42 to grant it) — not to grab a teammate's credentials that happen to have the scope you need.
- If you genuinely need a teammate to perform an action on your behalf (e.g. closing a PR you authored as a different agent, posting from their identity), **delegate via SendMessage** to that teammate. They can do it under their own identity. You do not borrow their credentials.
- Credentials reflect identity and audit trail. An action performed under another agent's app appears in audit logs and review history as if that agent did it — which is both factually misleading and a security violation. lucas42 must be able to trust that every `lucos-X[bot]` action was actually taken by `lucos-X`.

**Only exception:** `lucos-system-administrator` and `lucos-site-reliability` may briefly run `--app <other-persona>` calls when **setting up or debugging another persona's credentials** — i.e. verifying that a newly-issued key or rotated secret actually works for the target persona's expected use case. This is a credential-test, narrowly scoped:

- The call must be a minimal smoke-test (e.g. `GET /user` or `GET /repos/...`), not real work that would otherwise be the target persona's responsibility.
- After confirming the credential works, the sysadmin/SRE hands the credential off and stops using `--app <other-persona>` immediately.
- The credential-test must be disclosed (in the related GitHub issue, the commit message, or directly to lucas42) — not hidden inside other work.

Any other use of another persona's `--app` flag is a violation. If you find yourself reaching for `--app lucos-developer` to read a PR because the issue-manager bot gave 403, stop — escalate the permission gap instead.

## Cross-repo issue references

In GitHub comments and issue/PR bodies, references to issues in **other repositories** must use `owner/repo#N` format (e.g. `lucas42/lucos_arachne#326`). A bare `#326` always links to the **current** repository's issue #326, even when you mean a different repo. Same-repo references can stay as `#N`.

**Write the qualified reference as plain text — not inside backticks.** A code span (backticks) renders the reference literally and suppresses autolinking exactly as a bare `repo#N` does: it looks fine in the source but is a dead, unclickable string in the rendered view. So in the *actual comment* type `lucas42/lucos_arachne#326` with no surrounding backticks. (Backticks are fine in instruction/doc files like this one, which only describe the format — the rule is about live GitHub comments and bodies.) If you deliberately want no link, drop the `#` (e.g. "issue 326 in lucos_arachne") rather than relying on a code span to kill it.

The `Refs #N` / `Closes #N` keywords in commits and PR descriptions also need the prefix when the target is in another repo (e.g. `Refs lucas42/lucos_arachne#326`).

**Beware closing keywords in *prose*.** GitHub's auto-close parser fires on `close`/`closes`/`closed`/`fix`/`fixes`/`fixed`/`resolve`/`resolves`/`resolved` immediately followed by an issue reference *anywhere* in a PR body **or commit message** — not just on a dedicated `Closes:` line, and including ordinary descriptive sentences. A closing keyword written directly before a qualified ref (`owner/repo#N`) **auto-closes** that issue on merge (cross-repo closes work with the qualified form), even when you only meant to mention it. When you want to *reference* an issue without closing it, keep the keyword away from the number — phrase it as "the release that ships `owner/repo#N`", "the work for `owner/repo#N`", etc. **This applies to the example in this very note, and to commit messages that quote it:** never put the literal keyword-plus-`owner/repo#N` adjacency into a PR body or commit message, or you trigger the close you are documenting. (Real incident 2026-06-22: aithne PR #186's body placed a closing keyword directly before a fully-qualified navbar ref and silently auto-closed an unimplemented, dependency-blocked navbar issue on merge — and the close *recurred* when a commit message documenting the gotcha quoted the offending phrase verbatim, so this defanged form uses an `owner/repo#N` placeholder instead of a live ref.)

## Git commit identity

Use the `git-as-agent` wrapper for all commit-writing git operations — **never** run `git config user.name` or `git config user.email`, as that would affect all future commits in the environment.

```bash
~/sandboxes/lucos_agent/git-as-agent --app <persona> commit -m "..."
~/sandboxes/lucos_agent/git-as-agent --app <persona> commit --amend
~/sandboxes/lucos_agent/git-as-agent --app <persona> cherry-pick abc123
~/sandboxes/lucos_agent/git-as-agent --app <persona> pull --rebase origin main
~/sandboxes/lucos_agent/git-as-agent --app <persona> rebase main
```

`git-as-agent` looks up the persona's `bot_name` and `bot_user_id` from `~/sandboxes/lucos_agent/personas.json` and prepends the correct `-c user.name=... -c user.email=...` flags automatically. All remaining arguments are passed through to `git`.

**Critical:** The `-c` flags set both the author and the committer. When git amends a commit, it preserves the original author but sets a **new committer** using the current identity — which without the wrapper will be the global git config (`lucos-agent[bot]`). This produces a commit where author and committer differ, which is incorrect.

**Always use `git-as-agent` for every git command that writes a commit**, including:

- `git commit -m "..."`
- `git commit --amend`
- `git cherry-pick`
- `git pull --rebase`
- `git rebase`
- Any other operation that creates or rewrites a commit

There is no safe "do this once" shortcut — every commit-writing operation needs the wrapper.

## Committing `~/.claude` changes

`~/.claude` is a version-controlled git repository (`lucas42/lucos_claude_config`). When you edit any file under `~/.claude` — your own persona file, memory files, or any other config — you **must commit and push** the changes.

**Before committing, verify you are on `main`.** The `~/.claude` checkout is shared — other work can leave it on a feature branch. Run `git -C ~/.claude status` first; if not on main, run `git -C ~/.claude checkout main && git -C ~/.claude pull --ff-only` before proceeding.

```bash
cd ~/.claude && git add {changed files} && \
  ~/sandboxes/lucos_agent/git-as-agent --app <persona> commit -m "Brief description of the change" && \
  git push origin main
```

If you skip this step, your changes will be lost when the environment is reproduced, and other agents in future sessions won't see your updates.

### Keep instruction-file text lean — lesson narrative goes in the commit message

When you add a rule, CHECKPOINT, or convention to a persona/reference/skill file, the body of the rule should state **what** to do and **why** in the abstract. The triggering incident — what mistake was made, what date, who pushed back, who was affected — belongs in the **commit message**, not the rule body.

Bad (inline lesson narrative pollutes the rule):

> **Never instruct lucos-security to dismiss alerts.** (Lesson from 2026-05-20 on `lucos_media_seinn#460`: told `lucos-security` "dismiss the alert directly" rather than asking them to decide; lucas42 pushed back: "If they're choosing to dismiss an alert, it should be their decision to do so, not yours or another teammate.")

Good (rule body, commit message carries the lesson):

> **Never instruct lucos-security to dismiss alerts.** Send the alert + context and ask for their assessment; the action decision is theirs.

…with the incident narrative in the commit message:

> ```
> specialist-routing: never instruct security to dismiss alerts
>
> Today on lucos_media_seinn#460, the coordinator told lucos-security
> "dismiss the alert directly" rather than asking them to decide.
> lucas42 pushed back that the dismissal decision belongs to the
> security persona, not the coordinator. Encoding the rule.
> ```

Why this matters: instruction files are loaded into every conversation that uses them. Every kilobyte of "Lesson from {date}" narrative costs attention budget on every load, even for readers who don't need the historical context. The commit log is the right home for "what triggered this change" — `git log` and `git blame` surface it on demand, but it doesn't tax the rule's primary readers.

## Persona-specific extensions

Personas may extend this reference with:

- Persona-specific GitHub App permissions (e.g. lucos-system-administrator may have repo-admin scopes that other personas don't).
- Specific endpoints the persona uses frequently (workflow APIs, project board APIs, etc.).

Persona-specific guidance must not contradict the rules above.
