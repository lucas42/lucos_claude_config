---
name: review-dependabot-automerge-workflow
description: Dependabot auto-merge caller workflows must use `pull_request` + a permissions block, never `pull_request_target` + uses: — that combination causes startup_failure regardless of if: guards or secrets:inherit.
metadata:
  type: feedback
---

**`startup_failure` causes:** (1) repo has no Actions secrets at all → fails on all runs (confirmed lucos_navbar#46, lucos_backups#83 — escalate to lucos-site-reliability); (2) `pull_request_target` + `uses:` (reusable workflow) → GitHub resolves `uses:`/`secrets: inherit` before evaluating `if:`, so it fails to start regardless of guards (confirmed lucas42/.github #13/#14). A non-Dependabot actor correctly triggering the workflow which then concludes `skipped` via the reusable workflow's internal `if:` guard is expected, not an error.

**Correct caller pattern:**
```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
permissions:
  pull-requests: write
  contents: write
jobs:
  dependabot:
    uses: lucas42/.github/.github/workflows/dependabot-auto-merge.yml@main
```
No `secrets: inherit` (not needed, causes `startup_failure` on `pull_request_target`), no `if:` guard in the caller (lives in the reusable workflow's job, keyed on `github.event.pull_request.user.login == 'dependabot[bot]'` — checks PR author, stable against maintainer re-runs). Validated via smoke test in lucas42/.github #14.
