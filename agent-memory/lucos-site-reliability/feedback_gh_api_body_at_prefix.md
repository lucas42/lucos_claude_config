---
name: feedback-gh-api-body-at-prefix
description: For gh api POST/PATCH bodies, DEFAULT to the heredoc-captured var or `--input JSON`; avoid `body=@FILE` (the -f/-F footgun) and never `body-file=FILE` (silent empty body)
metadata:
  type: feedback
---

**DEFAULT to the heredoc-captured variable or `--input file.json` for every `gh api` POST/PATCH body. Do NOT reach for `body=@FILE`.** [[reference-agent-github-identity]] (`references/agent-github-identity.md` ~line 53) explicitly says *don't* use `--field "body=@FILE"` and steers to the heredoc pattern — align with it. Reason: the `@file` short-flag form has a live footgun (below) that keeps biting me even though I "know" it.

**The footgun — `-f` posts the literal `@path`.** `--field`/`-F` interprets `@file` as "read file contents"; `--raw-field`/`-f` sends the value **literally**. So `-f body=@/tmp/x.md` posts the literal string `@/tmp/x.md` as the body (not empty — literally the path). This is *diagnostic knowledge* (to recognise a bad post), NOT an endorsement of the pattern:
- Bit me 2026-07-09 lucos_worlds#6 AND again 2026-07-10 lucos_repos#433 — same `-f` slip both times, despite this memory existing. Knowing the rule didn't stop me using the short flag; **not using `@file` at all** does.
- Recovery: a PATCH with `--input file.json` (`{"body":"..."}`) or the heredoc pattern. (`-F body=@file` empirically DOES read the file — that's how I fixed #433 — but don't rely on it; use heredoc/JSON so the -f/-F distinction never matters.)

**Don't confuse with `gh issue create` / `gh pr create` syntax.** Those CLI subcommands use `--body-file PATH` directly. `gh api --field body-file=PATH` looks similar but treats `body-file` as a field name with the literal string `PATH` as value — the actual `body` field stays empty, so the issue/PR/comment gets posted with `body: null`.

**Why:** Bit me on 2026-05-24 ops checks when filing `lucas42/lucos_monitoring#252`. The POST returned 201 with `body: null` because `--field body-file=/tmp/sre_missed_recovery_event.md` was interpreted as a field named `body-file` rather than as a way to specify the body. Had to PATCH the issue afterwards via `--input file.json` where the file was `{"body": "..."}`. The `gh-as-agent` wrapper output looked successful — only became obvious when I read the posted issue back.

**How to apply:** Whenever using `gh-as-agent ... -X POST` or `-X PATCH` with a body, use one of these two patterns — NOT `body=@FILE`:

1. **Inline heredoc-captured var:** `--field body="$(cat <<'ENDBODY' ... ENDBODY)"` — the default per `agent-github-identity.md`. Single-quoted delimiter prevents shell expansion; newlines preserved. Caveat: `gh api` still template-substitutes `{owner}/{repo}` inside the value, so reword prose that contains that literal syntax.
2. **JSON input:** `--input file.json` where the file is `{"body": "..."}` — most robust: no template substitution, no `@`-prefix ambiguity, no -f/-F trap. Best for fix-up PATCHes.

Never use `--field body-file=FILE` (creates an ignored field → `body: null`). Avoid `body=@FILE` (the -f/-F footgun above).

If a POST/PATCH response shows `"body": null` OR a body starting with `@/`, the body did not post correctly — immediately follow up with a PATCH using pattern 2 (`--input`).
