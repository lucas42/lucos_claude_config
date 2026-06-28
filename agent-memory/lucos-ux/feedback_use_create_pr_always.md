---
name: feedback_use_create_pr_always
description: Always use create-pr (not gh-as-agent pulls directly) when opening any PR, including ad-hoc proactive fixes — it handles the supervised-repo lucas42 reviewer request automatically
metadata:
  type: feedback
---

Always use `~/sandboxes/lucos_agent/create-pr` when opening any PR — dispatched issues AND ad-hoc fixes from proactive UX reviews.

**Why:** `create-pr` checks whether the repo is supervised and automatically requests lucas42 as a reviewer if so. Calling `gh-as-agent ... repos/.../pulls --method POST` directly bypasses that check. On a supervised repo, lucas42 never appears in `requested_reviewers` and the PR never enters his review queue — he has to hunt for it, which he's flagged as wrong. (Happened on lucas42/lucos_backups#357, 2026-06-28.)

**How to apply:** Whenever opening a PR — whether from `implement-issue.md` Step 6 or from a proactive fix under "Proactive UX Reviews" — always reach for `create-pr`, never raw `gh-as-agent ... pulls`. If in doubt afterwards, verify with:
```bash
gh-as-agent --app lucos-ux repos/lucas42/{repo}/pulls/{n}/requested_reviewers --jq '.users[].login'
```
Must print `lucas42` on supervised repos before reporting the PR open.
