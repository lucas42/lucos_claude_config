---
name: pattern-dependabot-blocked-by-required-approval
description: Green Dependabot PR with auto-merge enabled but mergeable_state=blocked and 0 reviews = branch protection requires an approval no lucos automation posts
metadata:
  type: project
---

Dependabot (or any) PR: all checks green + GitHub auto-merge enabled + `mergeable_state: blocked` + **0 approving reviews** = branch protection has `required_approving_review_count >= 1`.

**Why this is fatal:** the lucos auto-merge tooling NEVER posts an approving review. The reusable workflow `lucas42/.github` `reusable-dependabot-auto-merge.yml` only runs `gh pr merge --auto` (enables auto-merge); nothing in the estate approves. So a required-review gate is one no automation can ever satisfy → the PR sits blocked forever. The `dependabot-auto-merge.yml` workflow can still conclude `success` (it enabled auto-merge fine) — success ≠ merged.

**How to apply:** check `branches/main/protection`. Estate convention = `required_approving_review_count: none` (verified across photos/contacts/media_metadata_api/monitoring/backups/arachne/dns 2026-06-10). Branch protection gates on STATUS CHECKS only, never on a required approval. If a repo requires an approval, that's the misconfiguration — fix = set count to 0 (keep required status checks). Repo-settings change → **sysadmin territory**.

Convention name in lucos_repos audit: `branch-protection-enabled` ("...without requiring approvals..."). The audit catches this automatically and raises an `audit-finding` issue. First hit: lucos_aithne#22 blocked, tracked by lucos_aithne#15 (2026-06-10). Do NOT chase missing `LUCOS_CI_*` Dependabot secrets first — verify the review gate before the secrets theory.
