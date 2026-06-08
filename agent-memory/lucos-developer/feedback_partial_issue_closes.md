---
name: feedback-partial-issue-closes
description: Use non-closing references when a PR only partially resolves a multi-cause issue
metadata:
  type: feedback
---

When a PR only addresses *part* of a multi-cause issue (e.g. the issue tracks two root causes and the PR fixes one of them), use a non-closing reference in the PR body:

- **Good**: "Part of #309" / "Addresses #309" / "Refs #309"
- **Bad**: "Closes #309" / "Fixes #309"

Reserve `Closes`/`Fixes` for PRs that fully resolve the issue.

**Why:** GitHub auto-closes the issue on merge. If the issue is a multi-cause tracker and only one cause is fixed, auto-close is wrong — it falsely signals "done" and the tracker has to be manually reopened.

**How to apply:** After a PR is narrowed in scope (e.g. a combined fix split into two PRs), check whether the closing keyword is still appropriate. If the narrowed PR only fixes part of the original issue, downgrade to a non-closing reference.

Caught in lucos_backups#311 (rsync-only) which kept `Closes #309` after the tolerate_live_file half was stripped out — #309 was auto-closed and had to be reopened.
