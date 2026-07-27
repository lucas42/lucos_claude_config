---
name: review-circleci-missing-required-checks
description: Required CircleCI checks never trigger on a branch — two distinct root causes, distinguish before escalating or diagnosing
metadata:
  type: reference
---

When a PR's `mergeable_state` is `blocked` because required CircleCI status checks (e.g. `ci/circleci: test`, `ci/circleci: build`) never appear at all (zero pipelines for the branch via `GET /project/github/{owner}/{repo}/pipeline?branch=...` on the CircleCI v2 API — see `references/circleci-conventions.md` for the token/auth pattern), there are **two distinct root causes** that look identical from the CircleCI side but require different fixes:

1. **CircleCI rejects the push webhook with a 400** — documented runbook: [[lucos_repos#466]]. GitHub does not retry 4xx deliveries. Fix: redeliver the failed webhook.
2. **GitHub never delivers (or never generates) the `push` event at all** — no delivery to redeliver, 400 or otherwise. Confirmed instance: `lucos_media_metadata_manager#380` (2026-07-27), a Dependabot branch. The repo's push webhook was otherwise healthy (active, `push`-subscribed, `last_response: 200`) and fired correctly for other events (`create`, six `pull_request` deliveries, and the post-merge push to `main` 3s after merge) — only this one branch's `push` delivery was absent. A sibling repo (`lucos_notes`) hit by the same Dependabot burst that morning got a normal logged `push` delivery, confirming Dependabot branch-creation pushes *do* normally fire a webhook — this was a one-off gap, not a systemic Dependabot pattern.

**The 400-vs-absent distinction does NOT gate recovery — the fix is identical either way.** (Corrected by lucos-site-reliability 2026-07-27 after I initially wrote this up as a blocking sequence — it isn't.) Distinguishing which variant occurred only answers two *post-hoc* questions: whether webhook redelivery was an available alternative, and whether `[[lucos_repos#466]]`'s stated cause ("CircleCI 400s the push") applies to this instance. Neither is needed to unblock the PR.

**Recovery flow — fully self-service, no SRE handoff needed.** `CIRCLECI_API_TOKEN` in `~/sandboxes/lucos_agent/.env` is lucas42's user-scoped PAT with read/write across the org — it is the *identical* credential `lucos-site-reliability` uses. Confirmed 2026-07-27: same token prefix (`CCIPAT_FB3MXv...`), and SRE independently verified it can trigger pipelines (used it to fire pipelines 967/968, unsticking `lucos_media_metadata_manager#380`). Do not hand this to SRE by default — run it yourself:
1. Confirm zero pipelines for the branch (`GET /project/github/{owner}/{repo}/pipeline?branch=...`) and no `ci/circleci:` statuses on the head SHA.
2. `POST /project/gh/lucas42/{repo}/pipeline` with `{"branch": "<branch>"}` to re-trigger.
3. **Before trusting the result:** verify the triggered pipeline's `vcs.revision` equals the PR's head SHA exactly.
4. **Before assuming it's safe:** confirm the repo's deploy job is branch-filtered to `main` only (`lucos/deploy-avalon` etc.) so a branch-triggered pipeline can't reach production. This is repo-config-dependent — check it per-repo, don't assume it holds everywhere.
5. Once `test`/`build` report green on the branch pipeline, the PR's queued auto-merge (if any) releases on its own.

If step 2 ever returns `401`/`403` (token rotated, scope changed, etc.), that's the signal something changed — hand it to `lucos-site-reliability` then, not preemptively.

**Diagnosis (separate, unhurried, optional) — needs `repos/{repo}/hooks` access, which the code-reviewer App does not have (403 confirmed on `lucos_media_metadata_manager` 2026-07-27):** fetch the webhook delivery log. A logged `push` delivery with a 400 response = case 1 (redeliver was an alternative, matches `[[lucos_repos#466]]`). No `push` delivery logged at all for that branch/ref = case 2 (nothing to redeliver, doesn't match #466's stated cause). This part does need `lucos-site-reliability` (hook-list access), but it's a post-mortem question of *why*, sent as a follow-up — it never blocks the fix.

**Don't file a duplicate issue for this.** `lucos_repos#466` is deliberately closed-by-design as the runbook record, with an explicit revisit trigger (lucas42: "~3+ Dependabot batches" before building auto-remediation is worth reopening). If you hit this again, check whether #466 is still the active record before filing anything new, and note new evidence as a comment there rather than a fresh issue — even if the root cause turns out to be the other variant (case 2 vs case 1), since the issue exists to catalogue this whole failure class, not just one cause.
