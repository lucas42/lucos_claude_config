---
name: feedback-finalize-pr-before-dispatch-automerge
description: On auto-merging (unsupervised) repos, a PR is final the moment you dispatch it to the code-reviewer — make ALL edits first, verify the pushed branch HEAD, then dispatch and don't touch the branch
metadata:
  type: feedback
---

On unsupervised repos (e.g. `lucos`), code-reviewer approval triggers **auto-merge at the reviewed SHA**. So any commit you push *after* dispatching the PR to review races the merge — it either lands inconsistently or is orphaned on a now-merged branch, and `main` ends up with stale content.

**Why:** during the 2026-06-12 aithne incident this bit me **three times**. (1) I marked the incident-report PR #241 "ready" while still folding in team responses; it auto-merged mid-amendment, so the #242-decision rewording never reached `main`. (2) Correction PR #243 auto-merged at the reviewed SHA (`7e2fce0`) before my closed-framing amendment (`15bb62e`) landed — `main` got the wrong wording again. (3) Only PR #244, where I made both edits, **verified the pushed branch HEAD content, then dispatched and didn't touch it**, landed cleanly. team-lead's note: "an argument for not marking ready until last-mile tweaks are in."

**How to apply:**
- Make *every* edit to the branch before dispatching to code-reviewer. Treat "dispatch to review" as "freeze."
- Before dispatching, run `git show HEAD:<path> | grep` to **verify the pushed branch HEAD actually contains the final content** — don't assume your last push landed (it may have raced something).
- For incident reports specifically: honour the draft lifecycle — keep the PR a **draft** and fold in all verification results + team responses on the draft branch; only mark ready when *truly* final. "Ready" on an auto-merging repo means "final," not "nearly done." (See `references/incident-reporting.md` draft-stays-open lifecycle — the failure was marking ready too early.)
- If an amendment is genuinely needed after merge, it's a fresh follow-up PR off main — but finalize that one fully before dispatching too. Ties to [[feedback_verify_body_file_before_pr]] (verify-before-publish family).
