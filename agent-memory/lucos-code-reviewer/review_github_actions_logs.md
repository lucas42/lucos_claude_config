---
name: review-github-actions-logs
description: audit-dry-run in lucos_repos is advisory not a required check; and always fetch Actions job logs via gh-as-agent, never raw curl, which can silently serve a stale cached zip artifact.
metadata:
  type: feedback
---

**`audit-dry-run` is advisory.** Not a required status check — auto-merge doesn't wait for it, and a failure doesn't warrant REQUEST_CHANGES on its own (investigate, but it's not a hard gate). Confirmed: lucos_repos PRs #291/#292 merged correctly despite it failing (rate limit hit during the sweep).

**Never use raw `curl` for Actions logs — `get-app-token` doesn't exist in this environment**, and an unauthenticated request can follow redirects to a stale cached zip artifact with wrong content/timestamps (this happened diagnosing lucos_repos PR #291 — looked like `auto-merge-secrets` 403s from weeks earlier; real failure was a same-day rate limit). Use `gh-as-agent --app lucos-code-reviewer "repos/lucas42/{repo}/actions/jobs/{job_id}/logs"` (plain text, pipe through grep). Get the job ID via `"repos/.../actions/runs/{run_id}/jobs?per_page=10" --jq '.jobs[] | {id, name, conclusion}'`.
