---
name: gh api substitutes {owner}/{repo} and :owner/:repo placeholders in body text
description: gh api (and therefore gh-as-agent) does template substitution on {owner}/{repo} and :owner/:repo tokens even inside --field body="..." strings. Documentation placeholders in comment bodies get silently replaced with real repo names. Use heredoc-to-file + --field body=@file to avoid this.
type: reference
---

`gh api` performs template substitution on path-like tokens in **argument values**, including inside `--field body="..."`. Both styles are substituted:

- `{owner}/{repo}` → replaced with the current repo (or whatever the CLI resolves as context)
- `:owner/:repo` → same

This means if you write a comment or issue body that *discusses* a GitHub API endpoint using its documentation-style placeholders, the placeholders will be silently rewritten to real repo names in the posted text. Example from lucas42/.github#59 (2026-04-22): body text `GET /repos/{owner}/{repo}/dependabot/secrets` was posted as `GET /repos/lucas42/lucos_agent/dependabot/secrets`.

The substitution happens regardless of whether the heredoc is single-quoted (`<<'ENDBODY'`) — the single quotes prevent *shell* expansion but the token is already a literal string by the time it reaches `gh api`, which does its own substitution.

**How to work around it:**

1. **Write the body to a temp file, then use `--field body=@file`.** File-backed values skip the template substitution entirely:
   ```bash
   BODY_FILE=$(mktemp)
   cat > "$BODY_FILE" <<'ENDBODY'
   Comment body with {owner}/{repo} placeholders preserved verbatim.
   ENDBODY
   ~/sandboxes/lucos_agent/gh-as-agent --app <persona> <endpoint> --field "body=@$BODY_FILE"
   rm "$BODY_FILE"
   ```
2. Or avoid the placeholder syntax entirely in prose — describe the endpoint by its official name ("the List repository Dependabot secrets endpoint") rather than the path template.

**Propose an instruction update:** the `gh-as-agent` example in `agents/lucos-architect.md` (and probably other persona files) shows the inline-heredoc pattern for `body`. That pattern silently corrupts any body text that includes `{owner}/{repo}` or `:owner/:repo`. The persona instructions should be updated to (a) warn about this substitution, and (b) recommend the file-backed `--field body=@file` pattern for any body that might include GitHub API path templates.
