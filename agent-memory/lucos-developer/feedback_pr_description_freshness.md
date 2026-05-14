---
name: feedback-pr-description-freshness
description: Refresh PR description in the same step as any follow-up commit that changes the shape of the work
metadata:
  type: feedback
---

When a follow-up commit changes the *shape* of what you're doing — not a typo fix, but a substantive change like switching from a hardcoded value to a passthrough, adding a new dependency, or restructuring an approach — refresh the PR description **in the same commit push step**, before requesting re-review.

**Why:** Stale descriptions send the wrong signal to reviewers and future readers even when the code is correct. This came up twice in the schedule-tracker v2 migration sweep (lucos_creds#322, lucos_media_import#154, lucos_dns#90 all had SYSTEM passthrough in code but hardcoded SYSTEM in description).

**How to apply:** After staging and committing a follow-up change, immediately check whether the PR description matches the new approach before pushing. If the description refers to the old approach, update it via the GitHub API (`gh-as-agent ... PATCH -f "body=..."`) and mention it in the re-review request. Treat description freshness as part of "address the review feedback", not an afterthought.
