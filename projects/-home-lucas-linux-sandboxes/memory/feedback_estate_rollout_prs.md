---
name: Estate rollouts should use PRs
description: Prefer PRs over direct pushes for estate rollouts, with exceptions for trivial changes
type: feedback
---

Estate rollouts should use PRs, not direct pushes to main — even for templated changes across many repos.

**Why:** PRs provide per-repo code review and a visible audit trail. The estate-rollout skill's verification gates (smoke test, dry-run, user confirmation) assume PRs exist.

**How to apply:** Default to creating PRs for estate rollouts. Direct pushes are acceptable only for truly trivial changes (e.g. bumping a version number in a `uses:` reference) where the templated nature of the change means per-repo review adds no value. When in doubt, use PRs.
