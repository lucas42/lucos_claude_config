---
name: review-github-actions-outage-pattern
description: Zero check-runs estate-wide + an open GitHub Actions incident = a GitHub-side outage, not a branch-protection/required-check design gap
metadata:
  type: feedback
---

When a required check-run (e.g. CodeQL `Analyze (python)`) shows `total_count: 0` on a PR head and `mergeable_state: blocked`, check githubstatus.com for an open Actions incident and check whether every repo in the estate shows the same "nothing since timestamp X" pattern **before** concluding the required check has a structural gap (e.g. "can't fire on docs-only diffs").

**Why:** On `lucos_worlds#67` (2026-08-06) I asserted the CodeQL check "structurally never fires on a markdown-only diff" — plausible-sounding, and wrong: `lucos-site-reliability` found direct proof the same check *had* fired before on a zero-Python diff (a 2026-08-04 Dependabot PR touching only the workflow YAML itself), so the diff-content theory doesn't hold. My proposed fix (drop the required check) would have been a permanent security regression on `main` traded away to work around what looked like a transient platform issue — exactly the "classic manual fix I'd have to undo later" pattern SRE called out. (Note: SRE's specific attribution to a live GitHub Actions `major_outage` was itself later contested by `lucos-architect`, who found the same PR was created as a *draft* — a bare `pull_request:` trigger defaults to `[opened, synchronize, reopened]`, no `ready_for_review`, so a PR opened as draft can show zero runs independent of any outage, and un-drafting doesn't backfill the missing run. I could not cleanly adjudicate between "outage" and "draft-suppressed" from available evidence — no non-draft PR or push existed anywhere in the estate during the relevant window to use as a control. Either way, the general discipline below held: don't propose loosening a required check on a plausible-sounding but unverified theory.)

**How to apply:** before diagnosing a missing/never-fired required check as a branch-protection design flaw:
1. Check githubstatus.com for Actions/Pages incidents.
2. Check whether *other* repos in the estate also have a dead Actions timeline at the same point — a single stalled timestamp shared across every repo is the outage signature, not a per-repo defect.
3. Never propose removing or loosening a required check as the fix without first ruling out a transient platform outage.

Related: [[feedback-estate-dns-ci-pattern]] — same underlying discipline (verify an estate-wide/upstream outage before blaming the PR or the repo config), different failure surface (GitHub Actions platform outage vs. authoritative DNS).
