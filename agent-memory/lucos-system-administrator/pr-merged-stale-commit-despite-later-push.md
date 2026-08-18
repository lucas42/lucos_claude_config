---
name: pr-merged-stale-commit-despite-later-push
description: A PR merged on an older commit even though a later push had already landed on the branch — merged:true and a successful push are not proof the push's content shipped
metadata:
  type: feedback
---

On lucos_claude_config#130 (2026-08-18): pushed a fix commit (`a6ea5b1`) on top of an already-reviewed commit (`c12b213`), confirmed the push succeeded (git reported the branch ref moving on origin), and asked `lucos-code-reviewer` to re-review the new head. The PR nonetheless merged at `c12b213` — every submitted review's `commit_id`, and `merge_commit_sha`, all point to the pre-fix commit.

**Root cause, confirmed by team-lead (not my original "race" guess):** the merge on `c12b213` happened first — auto-deleting the branch, as GitHub does on merge. My already-in-flight push landed *after* that, which git allows: it silently recreates the branch ref at the new SHA (`a6ea5b1`), orphaned, pointing nowhere a merged PR's endpoints will ever look. **A commit pushed to a PR's branch after the PR merges is invisible to every endpoint hanging off that PR — `head.sha`, `/commits`, and the reviews list all freeze at merge time.** They show a confident, internally consistent picture that simply omits it; nothing errors, nothing looks wrong. On a second attempt at the same fix (carried into #132), the same shape recurred except the branch was *also* deleted by me when I (wrongly, on a since-reversed instruction) closed the PR — the commit was still recoverable via `refs/pull/<n>/head` on origin, but that's a narrower safety net than an orphaned branch.

**Why this matters:** a successful `git push` and a `merged: true` API response are each individually true and together still don't prove your latest content is what shipped. `pr-review-loop.md`'s existing guidance ("re-fetch pulls/{n} before reporting back") catches `merged`/`state`, but not this — the PR's own view is self-consistent and wrong.

**How to apply:** don't trust any endpoint scoped to the PR (`head`, `/commits`, `/reviews`, `merge_commit_sha`) to prove a late push landed. Resolve the **branch tip directly** (`git ls-remote origin <branch>`) and compare it to what you pushed, or probe file content at `?ref=main` / `git show origin/main:<path>` — i.e. check `main`, not the PR. If the push didn't make it: the standard orphaned-branch recovery in `pr-review-loop.md` still applies (fresh branch off current `main`, carry the diff, new PR) — but first fetch the dangling commit by SHA (`git fetch origin <sha>`, or `refs/pull/<n>/head` if the branch is already gone) before touching anything, in case it's about to become unreachable.

See also [[settings-json-restart-verification-129]].
