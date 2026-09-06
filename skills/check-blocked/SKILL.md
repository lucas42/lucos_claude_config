---
name: check-blocked
description: Check all blocked issues for resolved dependencies and re-triage any that are now unblocked
disable-model-invocation: true
---

Perform the blocked-issue check directly. You are the coordinator — this is your responsibility. Do not ask for clarification — immediately begin.

---

Check all issues with Status = Blocked for resolved dependencies.

1. Read `~/.claude/references/triage-reference-data.md` for the Blocked status option ID and API patterns.

2. Fetch every issue in the Blocked column of the project board (Status = Blocked, option ID `d79b6b67`). **You must paginate** — blocked issues may appear on any page, not just the first. Loop using `pageInfo.hasNextPage` and `endCursor` until `hasNextPage` is false. A single query is not sufficient.

3. For each blocked issue:
   a. Read the full issue body and all comments to identify every issue referenced as a dependency or prerequisite (e.g. "blocked by #X", "depends on lucas42/other_repo#Y", or any issue linked as a blocker in a previous triage comment).
   b. Check whether **all** referenced dependencies are closed. If any dependency is still open, skip the issue silently — do not comment or change anything.

      Use `~/.claude/skills/dispatch/check-dependent` for the reference matching rather than hand-rolling a regex — it already strips backtick code spans and handles the same-repo bare-`#N` and fully-qualified cross-repo forms, which an ad-hoc pattern gets wrong in both directions.

      **A dependency whose state you could not fetch is UNKNOWN, never closed.** Any hand-rolled check must fail *closed*: if the state lookup errors, times out, or returns empty, leave the issue Blocked and report the unresolved reference. This direction of error is silent and catastrophic — treating a failed lookup as "closed" unblocks the entire column at once and dispatches work whose prerequisites do not exist, while producing output that looks like a clean pass. Sanity-check the result before acting on it: every blocked item reporting zero open dependencies is far more likely to be a broken probe than a genuinely clear board.
   c. If all dependencies are closed, re-triage the issue: set Status away from Blocked on the project board and apply whatever transition is appropriate (e.g. if it's an audit-finding whose convention checker was fixed, close it as completed; otherwise set Status = Ready to make it available for pickup).

4. Report back with a summary: how many blocked issues were checked, how many were unblocked, and a brief note on each unblocked issue.
