# Agent GitHub & git identity

How agents on the lucos team interact with GitHub and write commits. Applies to **every** persona.

Each persona has a corresponding GitHub App (`lucos-architect`, `lucos-developer`, `lucos-security`, etc.). All GitHub API calls and all commit-writing git operations must be attributed to the persona's own app — never the default `lucos-agent`, never personal credentials.

The persona's own bot identity is set by the `--app <persona>` flag on every wrapper call. Substitute your own persona name where this reference uses `<persona>`.

## GitHub API calls

Always use `~/sandboxes/lucos_agent/gh-as-agent --app <persona>` for all GitHub interactions — issues, pull requests, comments, reviews. Never use `gh` directly or fall back to another app's identity.

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

**Two safe workarounds:**

1. **File-backed body (preferred for any body that might contain API path templates or curly-brace placeholders):**

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

2. **Avoid the placeholder syntax in prose entirely** — name the endpoint by its docs title (e.g. "the List repository Dependabot secrets endpoint") rather than the path template.

The same gotcha applies to `PATCH` calls that update an existing issue/PR body and to comments. See [`references/issue-creation.md`](issue-creation.md) for the canonical issue-creation patterns.

## What never to do

- **Never** use `gh api` directly (without the wrapper) — it would post under the wrong identity.
- **Never** use `gh pr create` — same reason; use the API endpoint via `gh-as-agent` instead.
- **Never** fall back to `lucos-agent` or another persona's app when acting as your persona.

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

`~/.claude` is a version-controlled git repository (`lucas42/lucos_claude_config`). When you edit any file under `~/.claude` — your own persona file, memory files, or any other config — you **must commit and push** the changes:

```bash
cd ~/.claude && git add {changed files} && \
  ~/sandboxes/lucos_agent/git-as-agent --app <persona> commit -m "Brief description of the change" && \
  git push origin main
```

If you skip this step, your changes will be lost when the environment is reproduced, and other agents in future sessions won't see your updates.

## Persona-specific extensions

Personas may extend this reference with:

- Persona-specific GitHub App permissions (e.g. lucos-system-administrator may have repo-admin scopes that other personas don't).
- Specific endpoints the persona uses frequently (workflow APIs, project board APIs, etc.).

Persona-specific guidance must not contradict the rules above.
