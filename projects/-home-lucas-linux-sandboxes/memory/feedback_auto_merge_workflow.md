---
name: Auto-merge on approval
description: PRs auto-merge when approved — don't ask the user to manually merge, even on supervised repos
type: feedback
---

PRs auto-merge when approved. "Supervised repo" means the user needs to review and approve the PR, not that they need to manually click merge. Once approved, auto-merge handles the rest.

**Why:** The user corrected this multiple times in one session. Repeatedly asking them to merge approved PRs is noise.

**How to apply:** After reporting that a PR is approved, say it will auto-merge. Don't say "needs your merge" or "awaiting your merge". For supervised repos, the user action is reviewing/approving — once that's done, there's nothing more for them to do.
