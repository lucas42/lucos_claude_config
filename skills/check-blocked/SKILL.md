---
name: check-blocked
description: Check all blocked issues for resolved dependencies and re-triage any that are now unblocked
disable-model-invocation: true
---

Send a message to `lucos-issue-manager` with the following instructions, then wait for their response and relay the summary to the user.

---

Check all `status:blocked` issues for resolved dependencies.

1. Fetch every issue in the Blocked column of the project board (Status = Blocked, option ID `d79b6b67`). Paginate if needed.

2. For each blocked issue:
   a. Read the full issue body and all comments to identify every issue referenced as a dependency or prerequisite (e.g. "blocked by #X", "depends on lucas42/other_repo#Y", or any issue linked as a blocker in a previous triage comment).
   b. Check whether **all** referenced dependencies are closed. If any dependency is still open, skip the issue silently — do not comment or change anything.
   c. If all dependencies are closed, re-triage the issue: remove `status:blocked`, update the project board, and apply whatever label transition is appropriate (e.g. if it's an audit-finding whose convention checker was fixed, close it as completed; otherwise make it available for pickup).

3. Report back with a summary: how many blocked issues were checked, how many were unblocked, and a brief note on each unblocked issue.
