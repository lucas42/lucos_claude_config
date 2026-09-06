---
name: dependabot-automerge-carveout
description: Why estate-wide required PR reviews are off by design, and the arming/disarming mechanics of native auto-merge on Dependabot PRs
metadata:
  type: reference
---

# The Dependabot auto-merge carve-out — and why "just require reviews" is always the wrong answer

**Required approvals are OFF estate-wide deliberately, not by neglect.** The `lucos_repos` convention `branch-protection-enabled` *fails* a repo when `RequiredPullRequestReviews != nil`, with the stated rationale that required approvals block Dependabot auto-merge and let security updates pile up. So any proposal to add `required_pull_request_reviews` as "defence in depth" is a **reversal of a standing decision**, not a bigger version of a fix: it would make ~47 repos start failing an enforced convention (auto-raising 47 audit findings) and break the ~1,644-merged-Dependabot-PRs-per-quarter path.

**Whenever someone proposes estate-wide required reviews, the answer is: that needs the convention rewritten first, as its own ticket.**

## What the carve-out is actually justified by

Zero approvers on a Dependabot PR is an accepted exemption. Its justification is **content provenance** — a machine-generated, bounded manifest/lockfile bump, with CI as the gate. It is *not* justified by who opened the PR. The guard in `reusable-dependabot-auto-merge.yml` uses `pull_request.user.login` as a proxy for that, and the proxy is falsifiable: a foreign commit pushed to the branch leaves `user.login` unchanged (lucas42/.github#74, 2026-09-06).

Frame such a bug as a defect in the **classifier**, not the gate. That picks the fix layer and rules out rebuilding the gate.

## Auto-merge mechanics (the counter-intuitive half)

- `gh pr merge --auto` **arms** native auto-merge, and it stays armed until explicitly turned off or the PR closes. A later guard that merely *skips* re-arming is a complete no-op.
- The off-switch is `gh pr merge --disable-auto` (real primitive, gh 2.87.3).
- **`synchronize` is not the bug — it's the only event that gives you a chance to disarm.** Dropping it from the caller workflow makes things strictly worse. This is the intuitive-but-wrong fix; expect people to reach for it.
- Disarming needs no GitHub App token. The App token exists because a `GITHUB_TOKEN`-attributed *merge* suppresses downstream workflows (CodeQL); a disarm pushes nothing, so plain `GITHUB_TOKEN` + `pull-requests: write` is correct and faster.
- **Disarm-after-the-fact is a race, not a lock.** Measured window between foreign push and merge: 87s and ~95s (lucas42/lucos_notes#515, lucas42/lucos_media_seinn#617). The airtight alternative — provenance as a *required status check* — costs branch-protection changes estate-wide and carries the "skipped required check blocks every PR forever" foot-gun.
- `reusable-code-reviewer-auto-merge.yml` has **no** Dependabot exclusion, so a disarmed Dependabot PR falls back cleanly onto the ordinary review path.

## jq trap worth reusing

`all` over an **empty** array returns `true`. A failed API call yielding `[]` therefore evaluates as "every commit is Dependabot's" and *arms* auto-merge. Any all-must-match check over an API list needs an explicit empty/error branch. Connects to [[feedback_parse_reference_data_never_handbuild]].
