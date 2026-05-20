---
name: verify-body-file-before-pr
description: When using --body-file with create-pr or gh-as-agent, verify the file content is what you expect right before the command — Write may fail silently when batched alongside the Bash call, leaving stale content from a prior session.
metadata:
  type: feedback
---

When using `--body-file /tmp/{name}.md` with `create-pr` (or `gh-as-agent` PATCH/POST for issue/PR bodies), **verify the file content right before the command**. Two failure modes have bitten me:

1. **Stale tempfile from a prior session.** `/tmp/pr_body.md` persists across Claude sessions. If a previous session wrote it for a different PR and didn't clean up, my new Write to the same path can fail with `"File has not been read yet. Read it first before writing to it."` — and `create-pr` then proceeds with the stale content.

2. **Parallel-tool-call ordering.** Batching the `Write` for the body file and the `Bash` call that consumes it in the same tool-call message lets them run in parallel. If the Write fails (for the reason above or any other), `create-pr` may already have read the old file content. The PR opens with the wrong body and I don't notice because `create-pr` printed the PR URL successfully.

**Why:** Bit me 2026-05-20 on `lucas42/lucos#167` — the seinn cache-thrash incident report shipped with the body from a prior arachne `IGNORE_TYPES` hotfix PR. The code-reviewer caught it. The actual incident report markdown in the diff was fine; the GitHub PR description was telling a different story entirely.

**How to apply:**

- Prefer **unique tempfile names per task** — e.g. `/tmp/pr_body_seinn_thrash.md` rather than the generic `/tmp/pr_body.md`. Even better: `mktemp` and use the returned path.
- If you must reuse a fixed path, do the sequence **sequentially**, not in parallel: `Read` → `Write` → verify (e.g. `head` the file) → only then `Bash create-pr`. Never batch the Write and the create-pr in one parallel message.
- After any `create-pr` (or `PATCH` on a PR body), `gh-as-agent repos/lucas42/{repo}/pulls/{N} --jq '.body | .[0:200]'` and confirm the first 200 chars are what you intended before considering the PR opened.

Applies equally to issue bodies (`-F body=@/tmp/issue_body.md`) — same Write-then-consume pattern, same failure modes.
