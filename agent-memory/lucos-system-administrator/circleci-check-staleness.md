---
name: CircleCI required check staleness diagnosis
description: How to correctly interpret "no CircleCI runs" when diagnosing potentially stale required status checks
type: feedback
---

## CircleCI orb job names → GitHub status context names

CircleCI strips the orb prefix from job names when constructing GitHub status contexts:
- Config job name: `lucos/build-multiplatform`
- GitHub status context: `ci/circleci: build-multiplatform`

So `ci/circleci: build-multiplatform` is the correct check name for a job defined as `lucos/build-multiplatform`. Don't confuse this for a mismatch.

## "No PR-head-SHA runs" ≠ stale check

If a repo has no open PRs, looking for CircleCI check runs on "recent PR head SHAs" will always return zero results — because there are no PR branches. This looks like the check is absent but it isn't.

**Correct diagnosis**: Check the commit SHA statuses on recent main branch commits instead. If the check appears there consistently, it's working.

**Why:** CircleCI fires on branch pushes (including PR branches). When there are no open PRs, there are no PR-branch pushes, so no PR-head-SHA runs. But push-to-main runs will show the check.

The `required-status-checks-coherent` convention tool checks against commit SHAs, which is why it correctly reports pass even when there are no recent PRs. Trust the convention tool over manual "no PR runs" observations.

Confirmed false-positive case: lucos_static_media#33 (2026-04-10) — closed as no-action after discovering CI was connected and running correctly.
