---
name: reference-issue-manager-no-pr-write
description: lucos-issue-manager App can comment on issues but not PRs (403); route PR comments/closes to code-reviewer
metadata: 
  node_type: memory
  type: reference
  originSessionId: 94aa52c6-ab9a-4363-b96b-b947dcdadbad
---

The **lucos-issue-manager** GitHub App has Issues:write but **not** Pull-requests:write. Commenting on an issue works; POSTing to `repos/.../issues/{pr_number}/comments` for a **PR** returns `403 "Resource not accessible by integration"` (observed 2026-06-26 on lucas42/lucos_arachne#685).

**Consequence:** the coordinator cannot close a Dependabot PR or comment on any PR via the issue-manager App. Route any PR-level action to **lucos-code-reviewer**, which has Pull-requests:write (it posts reviews on these PRs).

**To regenerate a stuck Dependabot PR after a fix lands on main: CLOSE the PR, don't recreate.** `@dependabot recreate` does **not** work for GitHub Apps — Dependabot rejects it with "only users with push access can use that command" (observed 2026-06-26). Closing the PR directly is the equivalent, working method: Dependabot opens a fresh PR against the updated main. Only the code-reviewer can close it (issue-manager is 403). The code-reviewer's own `agents/code-reviewer-stuck-pr-guide.md` records this constraint.

Recurs whenever a fix-on-main needs the stuck Dependabot PR regenerated — the "close the Dependabot PR" follow-on belongs to the code-reviewer, not the coordinator. Relates to [[feedback_verify_permission_claims]] (here the 403 is direct evidence, not an unverified claim).
