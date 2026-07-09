---
name: feedback_blocked_items_fresh_comments
description: "get-issues-for-triage doesn't surface Blocked items with fresh non-me comments; check them in the Step 5 sweep"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 74d5a9aa-068b-4031-a2b4-ddfa5ddb9662
---

`get-issues-for-triage` surfaces Ideation/Awaiting-Decision items whose last comment isn't from `lucos-issue-manager[bot]`, but it does **not** do the same for **Blocked** items. So a fresh lucas42 comment on a Blocked ticket — including a *requirement change*, not just chatter — goes unsurfaced by the discovery script.

**Why:** caught on 2026-07-09 — lucos_worlds#6 (monitoring/_info gap, Blocked on #2) had a same-day lucas42 comment adding a new requirement (surface lucos_worlds on the lucos_root homepage, which needs `/_info`). It only came to light because I ran the Step 5 Blocked sweep and happened to read #6's comments; the deployment blocker had also just closed.

**How to apply:** during the Step 5 unblocking check, don't only test whether dependencies resolved — also scan each Blocked item's recent comments for a fresh lucas42 comment that changes scope/requirements or signals it should move. The systemic fix would be to extend `get-issues-for-triage` (in `~/sandboxes/lucos_agent`) to surface Blocked items with a last-comment-not-from-me, same as Ideation/Awaiting Decision — worth filing as a Low enhancement if the manual sweep keeps catching these. Related: [[feedback_refetch_issue_comments_before_following_up]].
