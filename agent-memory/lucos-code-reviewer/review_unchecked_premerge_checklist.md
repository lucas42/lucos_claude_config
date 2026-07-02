---
name: review-unchecked-premerge-checklist
description: unchecked [ ] pre-merge gate items in a PR body mean do not APPROVE yet on unsupervised repos
metadata:
  type: feedback
---

If a PR body contains an unchecked `[ ]` item framed as a pre-merge gate (e.g. "live triplestore confirms X count"), posting APPROVE on an unsupervised repo triggers auto-merge immediately once CI is already green — bypassing the gate entirely, since approval and merge happen in the same instant.

**Why:** `code-reviewer-auto-merge.yml` merges synchronously on bot approval on unsupervised repos. There is no human in the loop to notice the unchecked box.

**How to apply:** before approving, scan the PR body's task list for any unchecked `[ ]` item that reads as a verification/gate step (not just a nice-to-have). Either hold the approval until the gate is cleared (ask the author to confirm and check it off), or explicitly warn the developer in the review body that the box is unchecked before approving. Confirmed failure: lucos_arachne #476 merged with the triplestore count unverified.
