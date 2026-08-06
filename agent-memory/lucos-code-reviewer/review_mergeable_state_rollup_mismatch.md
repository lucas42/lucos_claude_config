---
name: review-mergeable-state-rollup-mismatch
description: mergeable_state/mergeStateStatus can stay "blocked" with everything green on REST check-runs — verify via GraphQL rollup before calling it stale
metadata:
  type: feedback
---

REST `/commits/{sha}/check-runs` shows what ran on a SHA. It is **not** the surface branch protection gates on — that's the PR's check-suite rollup (`statusCheckRollup.contexts` via GraphQL). A required check can show `conclusion: success` on the REST endpoint and still be **absent from the rollup**, keeping `mergeable_state: blocked` indefinitely. Documented as Criterion 8 in `code-reviewer-stuck-pr-guide.md`: typically happens after a dropped `pull_request` webhook where the check gets re-triggered via `workflow_dispatch` — that creates a check-run on the SHA but never associates it with the PR's check-suite. Fix is close+reopen (fires a fresh `pull_request:reopened` event), not another `workflow_dispatch`.

**Why:** On `lucos_worlds#72` (2026-08-06) both I and `lucos-site-reliability` independently read REST check-runs as green, agreed `mergeable_state: blocked` was "probably a stale recompute," and stood down. `team-lead` pushed back and was right — the GraphQL rollup showed `Analyze (python)` genuinely absent from the PR's 8-context rollup, not just slow to recompute. Two agents agreeing from the same (wrong) endpoint is not verification, it's the same claim twice.

**How to apply:** Before characterising a persistent `mergeable_state: blocked` as stale/probably-fine when REST check-runs and statuses all look green, run the GraphQL `statusCheckRollup` query (see `code-reviewer-stuck-pr-guide.md` Criterion 8) to confirm the required check is actually present in the rollup GitHub evaluates — not just present on the SHA. Instruction fix landed in `agents/workflows/review-pr.md` Step 6 (2026-08-06) so this is now the documented default, not something to re-derive per session.

Distinguish from the simpler case (Criterion 4 / plain outage): if the check is genuinely absent from *both* REST check-runs and the GraphQL rollup (not present anywhere), that's a check that never ran at all — e.g. lucos_worlds#73 same night, verified via both REST and GraphQL, genuinely zero `Analyze (python)` entries either place. That's the ordinary "GitHub Actions outage, nothing fired" case ([[review-github-actions-outage-pattern]]), not the rollup-mismatch case — no close+reopen needed, just wait for the outage to clear.

**Extra trap confirmed on #73 the same night, via `lucos-site-reliability`:** the rollup's own aggregate `statusCheckRollup.state` field can itself read `SUCCESS` while a required context is missing from `contexts` entirely — 7 green CircleCI contexts, aggregate `SUCCESS`, zero CodeQL contexts. Don't stop at the aggregate `state`; always confirm the specific required-check *name* is present in the `contexts` list.

**#72 vs #73 as a natural experiment (per `lucos-site-reliability`, 2026-08-06):** #72 had a `workflow_dispatch` re-trigger; #73 never got dispatched. Comparing rollups: #72's dispatch *did* add the CodeQL Advanced-Security context to the rollup — just not the required `Analyze (python)` GitHub-Actions context, which stayed absent in both. So "a dispatched run never joins the rollup" is not the right mental model — some suites from a dispatch join fine, others don't. Root cause is narrower/still open; don't over-generalize from one dispatched PR.

Related: [[review-headsha-checkruns]] (a different REST check-runs pitfall — `head_sha` aliasing), [[review-github-actions-outage-pattern]] (the plain-outage case this pattern is easy to conflate with).
