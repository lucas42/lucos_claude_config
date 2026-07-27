---
name: review-circleci-missing-required-checks
description: Required CircleCI checks never trigger on a branch — two distinct root causes, distinguish before escalating or diagnosing
metadata:
  type: reference
---

When a PR's `mergeable_state` is `blocked` because required CircleCI status checks (e.g. `ci/circleci: test`, `ci/circleci: build`) never appear at all (zero pipelines for the branch via `GET /project/github/{owner}/{repo}/pipeline?branch=...` on the CircleCI v2 API — see `references/circleci-conventions.md` for the token/auth pattern), there are **two distinct root causes** that look identical from the CircleCI side but require different fixes:

1. **CircleCI rejects the push webhook with a 400** — documented runbook: [[lucos_repos#466]]. GitHub does not retry 4xx deliveries. Fix: redeliver the failed webhook.
2. **GitHub never delivers (or never generates) the `push` event at all** — no delivery to redeliver, 400 or otherwise. Confirmed instance: `lucos_media_metadata_manager#380` (2026-07-27), a Dependabot branch. The repo's push webhook was otherwise healthy (active, `push`-subscribed, `last_response: 200`) and fired correctly for other events (`create`, six `pull_request` deliveries, and the post-merge push to `main` 3s after merge) — only this one branch's `push` delivery was absent. A sibling repo (`lucos_notes`) hit by the same Dependabot burst that morning got a normal logged `push` delivery, confirming Dependabot branch-creation pushes *do* normally fire a webhook — this was a one-off gap, not a systemic Dependabot pattern.

**How to distinguish (needs `repos/{repo}/hooks` access, which the code-reviewer App does not have — 403 confirmed on `lucos_media_metadata_manager` 2026-07-27):** fetch the webhook delivery log. A logged `push` delivery with a 400 response = case 1 (redeliver). No `push` delivery logged at all for that branch/ref = case 2 (nothing to redeliver — the only route is `POST /project/.../pipeline` with the branch, then verify `vcs.revision` matches the PR head SHA before trusting the result).

**Escalation:** case 2's fix (manually POSTing a pipeline) needs a CircleCI **write**-scoped token; `lucos-site-reliability` holds it. The *diagnosis* (confirm zero pipelines, distinguish 400-vs-absent) doesn't require SRE, but the delivery-log check does need hook-list access the code-reviewer App lacks — so in practice, hand off to SRE with the CircleCI-pipeline-absence evidence rather than trying to fully self-serve. Do not treat this as the `[[lucos_repos#466]]` pattern by default — check which variant it is (or hand the branch/PR details to SRE and let them check) rather than assuming the documented 400-rejection runbook applies.

**Don't file a duplicate issue for this.** `lucos_repos#466` is deliberately closed-by-design as the runbook record, with an explicit revisit trigger (lucas42: "~3+ Dependabot batches" before building auto-remediation is worth reopening). If you hit this again, check whether #466 is still the active record before filing anything new, and note new evidence as a comment there rather than a fresh issue — even if the root cause turns out to be the other variant (case 2 vs case 1), since the issue exists to catalogue this whole failure class, not just one cause.
