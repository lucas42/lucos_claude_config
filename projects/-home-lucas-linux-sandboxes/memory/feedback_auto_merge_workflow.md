---
name: Auto-merge on approval
description: PRs auto-merge when approved — don't ask the user to manually merge, even on supervised repos
type: feedback
originSessionId: 41a45cff-a9a6-4d3c-9106-e0f7aebd2912
---
PRs auto-merge when approved. The `code-reviewer-auto-merge.yml` workflow is deployed across nearly the entire lucos estate (verified 2026-04-29 — both `lucos_eolas` and `lucos_monitoring` auto-merged after lucas42 approved). Lucas42's approval triggers `lucos-ci[bot]` to merge the PR.

**Why:** The user has corrected this multiple times. Repeatedly asking them to merge approved PRs is noise. The PR's `auto_merge: null` field is misleading — it doesn't reflect whether the workflow will fire.

**How to apply:** After reporting that a PR is approved, say it will auto-merge. Don't say "needs your merge" or "awaiting your merge". For supervised repos, the user action is reviewing/approving — once that's done, there's nothing more for them to do. **Do not infer "no auto-merge" from `auto_merge: null` on the PR object** — the workflow runs on `pull_request_review`, separate from the PR-level auto-merge field.

**Specific case to verify before doubting:** if you think a particular repo doesn't have the workflow, check `.github/workflows/code-reviewer-auto-merge.yml` exists in that repo before telling lucas42 he needs to merge.
