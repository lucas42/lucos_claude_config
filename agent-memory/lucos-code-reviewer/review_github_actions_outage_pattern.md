---
name: review-github-actions-outage-pattern
description: Zero check-runs estate-wide + an open GitHub Actions incident = a GitHub-side outage, not a branch-protection/required-check design gap
metadata:
  type: feedback
---

When a required check-run (e.g. CodeQL `Analyze (python)`) shows `total_count: 0` on a PR head and `mergeable_state: blocked`, check githubstatus.com for an open Actions incident and check whether every repo in the estate shows the same "nothing since timestamp X" pattern **before** concluding the required check has a structural gap (e.g. "can't fire on docs-only diffs").

**Why:** On `lucos_worlds#67` (2026-08-06) I asserted the CodeQL check "structurally never fires on a markdown-only diff" — plausible-sounding, and wrong. `lucos-site-reliability` found (a) a live GitHub Actions `major_outage` incident opened 2026-08-06T15:22Z, and (b) direct proof the same check *had* fired on a zero-Python diff before (a 2026-08-04 Dependabot PR touching only the workflow YAML itself). The real cause was every repo in the estate having zero Actions runs since 18:49Z — an outage, not a config gap. My proposed fix (drop the required check) would have been a permanent security regression on `main` traded away to work around a transient third-party outage — exactly the "classic manual fix I'd have to undo later" pattern SRE called out.

**How to apply:** before diagnosing a missing/never-fired required check as a branch-protection design flaw:
1. Check githubstatus.com for Actions/Pages incidents.
2. Check whether *other* repos in the estate also have a dead Actions timeline at the same point — a single stalled timestamp shared across every repo is the outage signature, not a per-repo defect.
3. Never propose removing or loosening a required check as the fix without first ruling out a transient platform outage.

Related: [[feedback-estate-dns-ci-pattern]] — same underlying discipline (verify an estate-wide/upstream outage before blaming the PR or the repo config), different failure surface (GitHub Actions platform outage vs. authoritative DNS).
