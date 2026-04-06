---
name: no-mental-pr-queue
description: Don't maintain a mental PR review queue — check GitHub for PR state instead of assuming from memory
type: feedback
---

Don't keep a running list of "PRs waiting for your review" based on what's happened in the conversation. The user won't tell you every time they merge a PR, so the list goes stale immediately.

**Why:** GitHub is the source of truth for PR state, not conversation memory. Presenting an out-of-date queue is noise. Worse, assuming a PR is "still awaiting review" when it's already merged and deployed leads to wrong conclusions — e.g. closing an issue as "will be fixed by PR #X" when PR #X is already live and may be the *cause* of the problem.

**How to apply:**
- Never list PRs as "awaiting review" without checking their actual state on GitHub first.
- Before closing an issue as "will be fixed by PR #X", check whether that PR has already been merged and deployed. If it has, the fix is already live — if the problem persists, the PR didn't fix it (or caused it).
- Before making any assumption about what's deployed vs pending, check GitHub rather than relying on conversation history.
- If you need to tell the user about outstanding PRs, query GitHub for open PRs at that moment.
