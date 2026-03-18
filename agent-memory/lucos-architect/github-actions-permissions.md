---
name: GitHub Actions Dependabot token permissions
description: Dependabot pull_request events get read-only GITHUB_TOKEN (fork-like treatment); use pull_request_target for write access
type: reference
---

Dependabot `pull_request` events are treated by GitHub as fork-like events. This means `GITHUB_TOKEN` has a **read-only ceiling** -- the `permissions` key in a workflow cannot escalate beyond read-only, regardless of where it's declared (workflow-level, job-level, caller, or reusable workflow). Requesting write permissions causes `startup_failure`.

**Fix for workflows needing write access on Dependabot PRs:** use `pull_request_target` instead of `pull_request`. This runs in the base branch context and gets full repository token permissions.

**Security consideration:** `pull_request_target` is safe only when the workflow does NOT check out or execute PR branch code. The Dependabot auto-merge workflow (which just runs `gh pr merge --auto`) is safe because it only executes code from the base branch and the reusable workflow.

**How to apply:** Any workflow triggered by `pull_request` that needs write permissions for Dependabot PRs must use `pull_request_target`. Always keep an `if: github.actor == 'dependabot[bot]'` guard to prevent execution for non-Dependabot PRs.

**Convention: prefer job-level `permissions` over workflow-level.** Workflow-level declarations silently grant elevated access to any future job added to the workflow. Job-level keeps the blast radius tight -- each job must explicitly request what it needs. Only hoist to workflow-level if there's a specific reason. (Confirmed by lucos-security, 2026-03-18.)

Learned 2026-03-18 after three failed fix attempts on the lucos auto-merge workflow.
