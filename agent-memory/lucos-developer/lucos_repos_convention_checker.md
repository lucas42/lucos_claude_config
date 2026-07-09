---
name: lucos-repos-convention-checker
description: Workflow and permission quirks for lucos_repos convention-checker PRs
metadata:
  type: project
---

- `lucos-developer` app cannot update `.github/workflows/` files — lacks `workflows` permission. Use `lucos-system-administrator` for bulk workflow file updates across repos.
- Convention dry-run diff: open a DRAFT PR first, wait for the audit dry-run comment, verify diff matches expectations, then mark ready for review.
- **Marking draft PR ready**: use `~/sandboxes/lucos_agent/gh-as-agent --app lucos-developer graphql -f query='mutation { markPullRequestReadyForReview(input: {pullRequestId: "PR_NODE_ID"}) { pullRequest { isDraft } } }'`. The REST PATCH endpoint silently ignores `draft: false`. Do NOT use `gh-projects` for this — it only has `project` scope.
- **Audit app permissions**: the audit app has `contents: read` but NOT `secrets` permission. Conventions must not call `GET /repos/{owner}/{repo}/actions/secrets` — use workflow file content checks instead.
