---
name: feedback-serialize-same-repo-dispatch
description: "Don't dispatch two issues on the same repo to different agents concurrently — serialize them to avoid conflicting PRs"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1a322f6a-b1ba-45ab-8435-5406ebc4888e
  modified: 2026-09-29T17:28:35.166Z
---

When two Ready issues live on the **same repo** but are owned by **different agents**, do **not** dispatch them concurrently — even though the per-agent one-issue rule would allow it (different agents). Two open PRs on the same repo, especially touching nearby files, risk merge conflicts and competing branches. **Serialize:** dispatch one, wait for its PR to **merge**, then dispatch the next (so the second branches from a main that already contains the first).

**Why:** 2026-06-25 — I planned to dispatch lucos_media_seinn#525 (ux) and #524 (developer) "at the same time since they're different agents." lucas42 corrected: "don't dispatch both at the same time, given it's the same repo but different agents... go ahead with the UX one now, then do the developer one after." Both touch the seinn service-worker/player area, so concurrent PRs would have collided.

**How to apply:** The one-issue-**per-agent** rule (dispatchable once a PR is open) is necessary but not sufficient. Add a one-active-implementation-**per-repo** gate: before dispatching a second Ready issue on a repo that already has an in-flight implementation PR, wait for the first to merge. Only parallelise across **different** repos. "In flight" means the *ticket*, not just an open PR: an issue whose PR merged but whose production step (e.g. lucas42's hand-run migration) is still pending can spawn fix PRs at any moment, and on repos where every merge redeploys, another ticket's merge can break that step. Hold other same-repo dispatches until the ticket closes (lucos_campaigns#17's PR #35 collided with #3's migration run, 2026-09-29).
