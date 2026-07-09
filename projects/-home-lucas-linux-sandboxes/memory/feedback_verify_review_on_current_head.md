---
name: feedback_verify_review_on_current_head
description: "Before treating a PR as merge-ready, verify the code-reviewer's APPROVE is on the CURRENT head, not a stale pre-fix commit"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c2a277ac-c41c-46d8-a202-07f86f739f5e
---

Before surfacing a PR to lucas42 as "approved / ready to approve", or tracking it as merge-ready, verify the code-reviewer's APPROVE `commit_id` matches the PR's **current head**. Post-approval commits (especially from a *separate* reviewer's CHANGES_REQUESTED cycle — e.g. lucas42 tests, hits a bug, dev pushes a fix) leave the code-reviewer's earlier approval stale and uncovering the new code.

**Why:** on a **supervised** repo lucas42's approval merges instantly, so a stale code-review means substantial (often security-relevant) changes can merge with zero code-review coverage. On lucos_locations#97 the code-reviewer + security approved the original commit, then two substantial oauth2-proxy config commits (ES256 acceptance, scope request) landed via lucas42's change-requests and were never code-reviewed; lucas42 caught it by asking — I hadn't.

**How to apply:** when a PR I'm tracking gets new commits after a review APPROVE, don't call it merge-ready — get a fresh code-review of the new head first (SendMessage the code-reviewer), and only then let it go to lucas42. Root-cause fix for the dev side is in [`pr-review-loop.md`](../../../pr-review-loop.md) (fix → code-reviewer → approve → lucas42, regardless of who requested the change). Related: [[feedback_track_out_of_band_specialist_reviews]], [[feedback_refetch_before_accusing]].
