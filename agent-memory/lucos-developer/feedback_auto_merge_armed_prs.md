---
name: Auto-merge armed PRs — new commits merge without fresh review
description: Once lucas42 approves a PR with auto-merge enabled, any new commits pushed to the branch will auto-merge when CI passes — without a fresh review cycle.
type: feedback
---

Once `gh pr merge --auto` is armed (triggered by lucas42 approving a PR), any new commits pushed to that branch will merge automatically once their CI passes — **without waiting for a fresh review**.

This is fine for trivial/obvious commits (one-liners, doc tweaks). For substantive changes, request a review pause before pushing — otherwise changes land in main without a human having read them.

**Why:** The code reviewer flagged this after the `select_related()` commit on lucos_eolas#215 merged automatically before a fresh review cycle completed.

**How to apply:** Before pushing additional commits to an already-approved PR, assess whether the change warrants a review. If yes, note in the PR that the change needs fresh eyes before merge; if no (pure cleanup, one-liner), push freely.
