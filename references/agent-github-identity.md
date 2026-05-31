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

**Two safe workarounds:**

1. **File-backed body (preferred for any body that might contain API path templates, curly-brace placeholders, or start with a `@`-mention):**

   ```bash
   BODY_FILE=$(mktemp)
   cat > "$BODY_FILE" <<'ENDBODY'
   Your body text, with {owner}/{repo} placeholders preserved verbatim.
   ENDBODY
   ~/sandboxes/lucos_agent/gh-as-agent --app <persona> repos/lucas42/{repo}/issues/{N}/comments \
       --method POST \
       --field "body=@$BODY_FILE"
   rm "$BODY_FILE"
   ```

   The `@`-prefix tells `gh api` to read the field's value from the file. **Do not use `--field body-file=$FILE` or `--field body=$FILE`** — those send the literal path string (or with `body-file=`, silently create a `body-file` field the GitHub API ignores), so the issue/PR/comment gets created with `body: null`. The wrapper does not error; the failure is silent until you re-fetch the body and find it empty.

2. **Avoid the placeholder syntax in prose entirely** — name the endpoint by its docs title (e.g. "the List repository Dependabot secrets endpoint") rather than the path template.

The same gotcha applies to `PATCH` calls that update an existing issue/PR body and to comments. See [`references/issue-creation.md`](issue-creation.md) for the canonical issue-creation patterns.

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

The `Refs #N` / `Closes #N` keywords in commits and PR descriptions also need the prefix when the target is in another repo (e.g. `Refs lucas42/lucos_arachne#326`).

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
