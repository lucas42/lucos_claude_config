---
name: pr-merged-stale-commit-despite-later-push
description: A PR merged on an older commit even though a later push had already landed on the branch — merged:true and a successful push are not proof the push's content shipped
metadata:
  type: feedback
---

On lucos_claude_config#130 (2026-08-18): pushed a fix commit (`a6ea5b1`) on top of an already-reviewed commit (`c12b213`), confirmed the push succeeded (git reported the branch ref moving on origin), and asked `lucos-code-reviewer` to re-review the new head. The PR nonetheless merged at `c12b213` — every submitted review's `commit_id`, and `merge_commit_sha`, all point to the pre-fix commit. The branch was left on origin at `a6ea5b1`, orphaned (1 ahead / N behind main) — never diagnosed the exact race, but the shape matches "push landed on the branch after the reviewer had already acted on / merged the prior state" on an unsupervised repo's fast (~2.5 min open-to-merge) auto-merge path.

**Why this matters:** a successful `git push` and a `merged: true` API response are each individually true and together still don't prove your latest content is what shipped. `pr-review-loop.md`'s existing guidance ("re-fetch pulls/{n} before reporting back") catches `merged`/`state`, but the thing that actually caught this was checking each review's `commit_id` against the PR's `head`/`merge_commit_sha` — `merged: true` alone would have looked like success.

**How to apply:** after any push to a PR that's followed immediately by a review request on an unsupervised (fast-merge) repo, once a review or merge notification comes back, verify the review's `commit_id` (or the merge commit's parent) matches the SHA you actually pushed — not just that the PR shows `merged: true`. If it doesn't match, the recovery is the standard orphaned-branch path in `pr-review-loop.md`: cut a fresh branch from current `main`, carry just the diff, open a new PR, delete the orphaned branch.

See also [[settings-json-restart-verification-129]].
