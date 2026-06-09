---
name: feedback_multi_pr_review_loop
description: Drive the review loop for every PR an issue produces, not just the primary one
metadata:
  type: feedback
---

When an issue spans multiple PRs (e.g. a scaffold PR + a configy registration PR), drive the `lucos-code-reviewer` review loop for **all of them** before reporting done to the coordinator.

**Why:** "I drove the main PR's loop" doesn't complete the issue while a sibling PR sits unreviewed — the coordinator has to catch it and chase separately. A configy registration or any other cross-repo PR required by the issue is co-primary, not a "drive-by extra".

**How to apply:** As soon as you open a second (or third) PR for an issue, immediately send it to `lucos-code-reviewer` — don't wait for the first loop to finish. Run them concurrently. Only report back once all loops are complete (all PRs either approved or at the stage they're waiting for lucas42).

Discovered on `lucos_aithne#3` (2026-06-09): drove the loop for PR #13 but forgot to send configy PR #225 for review. Team-lead caught it and tightened `agents/workflows/implement-issue.md` Step 9 to make this explicit for all implementers.
