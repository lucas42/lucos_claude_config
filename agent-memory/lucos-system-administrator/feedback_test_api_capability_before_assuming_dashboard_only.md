---
name: feedback-test-api-capability-before-assuming-dashboard-only
description: Before writing "needs lucas42 / dashboard access" in an issue, actually test the write call — CircleCI's v2 API covers far more than expected
metadata:
  type: feedback
---

When an investigation concludes with "this needs lucas42" or "this is dashboard-only," test the actual write call before asserting it — don't infer from a read-only symptom (a stale field, an empty list) that the fix must be manual.

**Why:** On lucos_agent#72 (2026-08-06) I filed an issue theorising CircleCI's stale `default_branch: master` (vs GitHub's `main`) was blocking a scheduled prune workflow, and routed the fix to "lucas42 / whoever has CircleCI admin access" without testing whether the API token could actually act. Team-lead pushed back and asked me to verify capability rather than assume it. Testing revealed: (1) the stale `default_branch` was a red herring — the schedule object already existed and specified `branch: main` explicitly, unaffected by that field; (2) `PATCH /project/{slug}` genuinely 404s (that specific field really is API-unwritable) but it didn't matter; (3) the real root cause — zero CircleCI checkout keys on the project, causing every pipeline (scheduled or manual) to be rejected with `403: project has no SSH key` — was fixable with one call: `POST /project/{slug}/checkout-key {"type":"deploy-key"}`, which the token was fully permitted to do (201, real key created, auto-added to GitHub). The entire "needs a human" framing in my first pass was wrong on every count.

**How to apply:** Before closing an investigation with "requires dashboard/admin access," always try the corresponding write call (or the closest safe proxy — e.g. a pipeline trigger to reveal *why* it fails, not just guess). If it's genuinely a permission wall, the API returns 401/403 and that's real evidence for the "human-only" framing. If it 404s (endpoint doesn't exist) or 201s (succeeded), the framing needs to change. Applies beyond CircleCI — GitHub App permissions, lucos_creds writes, any "I assume only X can do this" moment. See [[circleci-project-diagnostics]] for the specific API calls that are safe to test read/write on CircleCI without side effects.
