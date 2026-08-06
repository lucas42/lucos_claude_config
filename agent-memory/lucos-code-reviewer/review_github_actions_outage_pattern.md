---
name: review-github-actions-outage-pattern
description: Zero check-runs estate-wide + an open GitHub Actions incident = a GitHub-side outage, not a branch-protection/required-check design gap
metadata:
  type: feedback
---

When a required check-run (e.g. CodeQL `Analyze (python)`) shows `total_count: 0` on a PR head and `mergeable_state: blocked`, check githubstatus.com for an open Actions incident and check whether every repo in the estate shows the same "nothing since timestamp X" pattern **before** concluding the required check has a structural gap (e.g. "can't fire on docs-only diffs").

**Why:** On `lucos_worlds#67` (2026-08-06) I asserted the CodeQL check "structurally never fires on a markdown-only diff" — plausible-sounding, and wrong: `lucos-site-reliability` found (a) a live GitHub Actions `major_outage` incident (opened 2026-08-06T15:22:49Z) and (b) direct proof the same check *had* fired before on a zero-Python diff (a 2026-08-04 Dependabot PR touching only the workflow YAML itself). My proposed fix (drop the required check) would have been a permanent security regression on `main` traded away to work around a transient platform outage.

Worth keeping the full loop, not just the ending: `lucos-architect` then proposed a *second* wrong theory (draft-at-creation suppresses the workflow run, not the outage), built on a confounded comparison — a draft PR from the outage day vs. a non-draft PR from a week earlier, two variables changed at once, unable to discriminate either way. I tried to find a clean natural experiment (a non-draft PR or push anywhere in the estate during the dead window) and came up empty, so I could only report the question as open, not resolve it. Architect then verified the outage independently via githubstatus.com and retracted their own theory. Three agents, two wrong theories, before the estate-wide timestamp correlation actually settled it — the check that closes the loop is always "does every repo in the estate show the same dead timeline at the same instant," not a single PR's diff content or draft status.

**How to apply:** before diagnosing a missing/never-fired required check as a branch-protection design flaw:
1. Check githubstatus.com for Actions/Pages incidents.
2. Check whether *other* repos in the estate also have a dead Actions timeline at the same point — a single stalled timestamp shared across every repo is the outage signature, not a per-repo defect.
3. Never propose removing or loosening a required check as the fix without first ruling out a transient platform outage.

Related: [[feedback-estate-dns-ci-pattern]] — same underlying discipline (verify an estate-wide/upstream outage before blaming the PR or the repo config), different failure surface (GitHub Actions platform outage vs. authoritative DNS).
