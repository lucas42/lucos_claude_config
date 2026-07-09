---
name: github-actions-reusable-workflow-perms
description: Required permissions for GitHub Actions callers of cross-repo reusable workflows, and the 2026-03-21 incident
metadata:
  type: feedback
---

**`permissions: {}` causes `startup_failure`** on cross-repo reusable workflow callers. Need at least `contents: read` to fetch the workflow definition. For dependabot-auto-merge callers also need `pull-requests: write` and `contents: write`; use `pull_request` trigger (not `pull_request_target`); no `secrets: inherit` or `if:` guard.

**Why:** a caller with insufficient permissions fails at workflow-fetch time, before any of its own logic runs — the failure mode looks unrelated to permissions.

**How to apply:** smoke test via `.github-test` before any estate-wide rollout of a reusable workflow caller — skipping this caused the 2026-03-21 incident (45 repos broken).
