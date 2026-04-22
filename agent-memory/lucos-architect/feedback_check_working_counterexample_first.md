---
name: Check for a working counter-example before concluding a mechanism is impossible
description: When analysing a failure, first ask whether the mechanism works anywhere in the estate. A single working example disproves a universal-impossibility claim in seconds; reasoning from first principles can produce a confidently-wrong answer that takes multiple rounds to walk back.
type: feedback
---

Before concluding "this mechanism fundamentally cannot work" (or more insidiously: "the fix must therefore be X, Y, or Z, where all obvious options have compromises"), **check whether the mechanism is already working in one or more places in the estate**.

**Why:** On lucas42/.github#59 (2026-04-22) I analysed a regression where Dependabot auto-merge wasn't getting a GitHub App token, and walked through a careful argument that `pull_request` events for Dependabot PRs have no secrets access at all, concluding that `pull_request_target` was the only credible fix. The entire argument collapsed when lucas42 pointed out that lucos_time#234 had merged fine on `pull_request` just that morning. The failing pattern wasn't a universal GitHub limitation — it was a partial-rollout of Dependabot-scope secrets across repos.

I arrived at the confidently-wrong recommendation because I reasoned from the failing repos outward without ever looking at a passing merge. One `grep` / API call to find a recent successful Dependabot merge would have disproved my entire premise in under a minute. Instead I spent a careful 10 minutes building an elaborate and incorrect answer.

**How to apply:**

1. When triaging or designing a fix for a failure that claims a mechanism is fundamentally broken, start with: "does this mechanism work anywhere right now?" Run a query — recent successful runs of the workflow, recent merges by the expected actor, other repos using the same pattern.
2. A single working counter-example disproves any claim of the form "this can never work." Treat one in the wild as load-bearing evidence, not an edge case.
3. When the evidence is "some repos pass, some fail," the fix is almost always operational (partial rollout, missing config, stale state) — not architectural. Resist the temptation to redesign when the design is already proven to work.
4. This is especially important for GitHub Actions quirks — the event model has many non-obvious corners (split secret scopes, `pull_request_target` checkout semantics, `workflow_run` chaining, bot-identity rules for downstream triggering) where a first-principles argument can sound right and still be wrong because you're missing a feature.
