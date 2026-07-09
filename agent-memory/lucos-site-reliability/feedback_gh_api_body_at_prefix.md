---
name: feedback-gh-api-body-at-prefix
description: For gh api POST/PATCH, file-backed body is `--field "body=@FILE"` with the @ prefix — `--field body-file=FILE` silently posts an empty body
metadata:
  type: feedback
---

When creating or updating GitHub issues/PRs/comments via `gh-as-agent ... -X POST/PATCH` (i.e. the underlying `gh api`), the file-backed body syntax is:

```bash
--field "body=@$BODY_FILE"
```

The `@` prefix tells `gh api` to read the value from a file. This is the documented pattern in [[reference-agent-github-identity]] (`references/agent-github-identity.md` line 53).

**Short-flag trap — `-F` not `-f`.** `--field`/`-F` interprets `@file` (reads file contents); `--raw-field`/`-f` sends the value **literally**. So `-f body=@/tmp/x.md` posts the literal string `@/tmp/x.md` as the comment body (not empty — literally the path). Bit me 2026-07-09 on lucos_worlds#6; the post-write body-read caught it and a PATCH with `-F body=@file` fixed it. If you use the short flag, it MUST be capital `-F` for file-backed bodies.

**Don't confuse with `gh issue create` / `gh pr create` syntax.** Those CLI subcommands use `--body-file PATH` directly. `gh api --field body-file=PATH` looks similar but treats `body-file` as a field name with the literal string `PATH` as value — the actual `body` field stays empty, so the issue/PR/comment gets posted with `body: null`.

**Why:** Bit me on 2026-05-24 ops checks when filing `lucas42/lucos_monitoring#252`. The POST returned 201 with `body: null` because `--field body-file=/tmp/sre_missed_recovery_event.md` was interpreted as a field named `body-file` rather than as a way to specify the body. Had to PATCH the issue afterwards via `--input file.json` where the file was `{"body": "..."}`. The `gh-as-agent` wrapper output looked successful — only became obvious when I read the posted issue back.

**How to apply:** Whenever using `gh-as-agent ... -X POST` or `-X PATCH` with a body, use one of three patterns:

1. Inline heredoc: `--field body="$(cat <<'ENDBODY' ... ENDBODY)"` — for short bodies without `{owner}/{repo}` placeholders or leading `@`-mentions.
2. File-backed with `@`: `--field "body=@$BODY_FILE"` — for long bodies, bodies with API path placeholders, or bodies starting with `@`-mentions. **This is the file-backed pattern documented in `agent-github-identity.md`.**
3. JSON input: `--input file.json` where the file is `{"body": "..."}` — usable for both POST and PATCH, useful for fix-up calls.

If a POST/PATCH response shows `"body": null`, the body did not post — immediately follow up with a PATCH using one of the working patterns.
