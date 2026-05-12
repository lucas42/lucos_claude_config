---
name: feedback-template-substitution
description: "gh-as-agent silently substitutes {repo}/{owner}/{name} placeholders inside --field body=… and treats leading @ as a filename — switch to the file-backed pattern when either applies"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5a23deee-8f2e-4987-b020-3843897bb01c
---

When using `gh-as-agent ... --field body=...` (or `--method PATCH ... --field body=...`), if the body contains `{owner}`, `{repo}`, `{name}`, or any other curly-brace placeholder, **switch to the file-backed pattern** (`--field "body=@$BODY_FILE"`) documented in `~/.claude/references/agent-github-identity.md`. Same for any body that starts with an `@`-mention. The substitution happens inside `gh api` itself, regardless of shell quoting — even single-quoted heredocs don't protect against it. The corruption is invisible until you read the posted content, so the first sign you've been bitten is finding the wrong repo name baked into a previously-posted comment or issue body.

**Why:** Hit this on 2026-05-12 — the body of [lucas42/lucos_claude_config#75](https://github.com/lucas42/lucos_claude_config/issues/75) had `DELETE /repos/lucas42/{repo}/labels/{name}` silently rewritten to `DELETE /repos/lucas42/lucos_agent/labels/{name}`. Required re-PATCHing the body via the file-backed pattern.

**How to apply:** Anytime you draft a comment, issue body, or PR body that documents a GitHub API path, contains code examples with placeholders, or opens with `@lucas42 …` — default to the file-backed pattern. Two-line price for a class of silent corruption that's hard to catch after the fact.
