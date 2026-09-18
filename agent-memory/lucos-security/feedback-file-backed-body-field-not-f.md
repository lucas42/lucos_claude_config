---
name: feedback-file-backed-body-field-not-f
description: Always use --field (long form) not -f for a file-backed gh-as-agent body — -f posts the literal "@/path" string, silently, with a 200 response
metadata:
  type: feedback
---

Use `--field body=@$FILE` (long form) for any file-backed PR review / issue / comment body via `gh-as-agent`. Never `-f body=@$FILE` — that posts the literal string `@/tmp/...` as the body, and the call still returns 200 with a normal-looking `html_url`, so nothing about the response signals the failure.

**Why:** Hit this live on lucas42/lucos_aithne PR #335 (2026-09-18) — posted a security APPROVE review with `-f body=@/tmp/pr335-review-body.md` and it silently ejected the path string as the visible review body instead of my actual write-up. Caught only because I happened to glance at the returned `body` field in the tool result. The trap was already documented in `references/agent-github-identity.md`, but split across two places and phrased case-conditionally ("--field for file-backed, -f is fine for plain strings") — a documentation-placement/structure gap, not merely a personal one, per CLAUDE.md's "no such thing as just an execution failure" rule (team-lead correction, 2026-09-18). Fixed at the instruction level: the rule is now unconditional (always `--field` for `body`/`dismissed_comment`, full stop) and stated where the first body-posting example appears, so this memory is a detection backstop, not the fix itself.

**How to apply:** Reflexively type `--field`, never `-f`, for `body`/`dismissed_comment` — no need to reason about file-backed vs. inline. After the call returns, don't just check for a 200/`html_url` — read the `body` field in the response back and confirm it's the real prose, not a bare path string, since this failure mode is specifically silent-success-shaped. Fixable in place afterward via `PUT .../reviews/{id}` (or the equivalent PATCH for issues/comments) with the corrected `--field` call.
