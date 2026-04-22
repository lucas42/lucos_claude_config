---
name: GitHub Dependabot secrets are a separate scope from Actions secrets
description: GitHub has two distinct secret scopes per repo — Actions secrets and Dependabot secrets. Dependabot-triggered pull_request workflows only see the Dependabot scope. Misunderstanding this cost me a whole wrong recommendation on lucas42/.github#59 (2026-04-22).
type: reference
---

GitHub has **two separate secret scopes per repository**:

1. **Actions secrets** — Settings → Secrets and variables → Actions. Available to workflows on `push`, `workflow_dispatch`, `pull_request_target`, and same-repo `pull_request`. **NOT available to Dependabot-triggered `pull_request` workflows.**
2. **Dependabot secrets** — Settings → Secrets and variables → Dependabot. A **distinct scope**, populated separately. Specifically available to Dependabot-triggered `pull_request` workflows (and only those).

A repo can have a secret with the same name populated in both scopes with the same or different values — they're independent. A secret in only one scope is invisible to the other.

**Why this matters for architectural analysis:**

- Dependabot `pull_request` events do NOT lack "secrets access" — they lack *Actions-scope* secrets access. The Dependabot scope is fully available.
- Claims like "the App-token path can never fire on a Dependabot `pull_request` event" are wrong; they can fire if the secrets are in the Dependabot scope.
- A partial rollout of secrets across the estate will look exactly like a "fundamental GitHub limitation" from the failing repos' perspective. **Always check whether the "failing" pattern works somewhere else in the estate before concluding it's impossible.** One working counter-example disproves a universal-impossibility claim.

**APIs:**
- `GET /repos/{owner}/{repo}/dependabot/secrets` — lists Dependabot secret **names** (values are write-only). Usable as a convention-check endpoint to audit membership.
- `GET /repos/{owner}/{repo}/actions/secrets` — same for Actions scope.
- Both endpoints require `dependabot_secrets:read` / `secrets:read` permission respectively — the architect App doesn't have these, so if you need to verify configuration, ask lucos-system-administrator.

**Related debugging evidence to remember:** if a Dependabot PR merges on a caller that uses `on: pull_request` and the merge is attributed to `lucos-ci[bot]` (not `github-actions[bot]`), the App-token path fired, which means the Dependabot secrets are populated on that repo. If the merge is attributed to `github-actions[bot]` instead, the secrets are missing from the Dependabot scope.
