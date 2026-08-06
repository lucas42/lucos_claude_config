---
name: circleci-project-diagnostics
description: Safe CircleCI v2 API calls for diagnosing "CI never runs for this project" — checkout keys, schedules, and what's actually API-writable vs dashboard-only
metadata:
  type: reference
---

Diagnostic sequence for "why has CircleCI never run a pipeline for repo X" (used on lucos_agent#72, 2026-08-06):

1. `GET /project/gh/lucas42/{repo}/pipeline` (with and without `?branch=`) — zero items ever, even after real pushes, is the first red flag.
2. `GET /project/gh/lucas42/{repo}/schedule` — read-only, safe. Confirms whether a Scheduled Pipeline object actually exists (config.yml's `when: equal: [scheduled_pipeline, ...]` conditional is necessary but not sufficient — the schedule itself is a separate object, created via dashboard or `POST .../schedule`). Don't assume "no schedule was set up" without checking this — it may well exist and be correctly configured.
3. `GET /project/gh/lucas42/{repo}/checkout-key` — read-only, safe. **This is usually the real answer.** An empty `items: []` means CircleCI has no SSH key to clone the repo — every pipeline (scheduled or manual) gets rejected before any trigger-type/branch logic runs. Compare against a known-working project (e.g. `lucos_repos`) which has one `deploy-key`-type entry.
4. To confirm #3 diagnostically: `POST /project/{slug}/pipeline {"branch":"main"}` — **safe to test** even on a project with a `when: scheduled_pipeline` gated destructive job, because an API-triggered pipeline gets `trigger.type: "api"`, not `"scheduled_pipeline"` — the gated job will not fire even if the trigger itself succeeds. A `403: "project has no SSH key"` response confirms #3 conclusively.
5. Fix: `POST /project/{slug}/checkout-key {"type":"deploy-key"}` → 201, creates a real deploy key and adds it to GitHub automatically (shows up as a read-only GitHub deploy key titled "CircleCI", `added_by` the account backing CircleCI's GitHub integration). **This is genuinely agent-doable — not a permissions wall.**
6. **Cleanup gotcha**: `DELETE /project/{slug}/checkout-key/{fingerprint}` removes it from CircleCI but does NOT remove the corresponding GitHub deploy key — that's orphaned and needs a separate `DELETE /repos/{owner}/{repo}/keys/{key_id}` via the GitHub API to fully revert.
7. `PATCH /project/{slug}` → genuinely `404 Not Found`. There is no API endpoint to update `vcs_info.default_branch` or other project metadata — if that field is stale (e.g. shows `master` when GitHub's actual default is `main`), it really is dashboard-only *if it matters*. But check whether it actually matters first — a schedule/pipeline with an explicit `branch` parameter doesn't care about the project's cached default branch at all. Don't let a stale-but-irrelevant field become the headline theory (did this on lucos_agent#72 before testing).

Token used: `CIRCLECI_API_TOKEN` from `~/sandboxes/lucos_agent/.env` (see `circleci-conventions.md`). It has far more write scope than "read-only ops check" assumptions would suggest — test before asserting a human-only fix. See [[feedback_test_api_capability_before_assuming_dashboard_only]].

**Judgment call that stays human-owned even though the API call itself isn't gated**: creating a checkout key on a project with an existing scheduled destructive job (e.g. `docker image prune -a -f`) *arms* that schedule to fire for real at its next scheduled time — that's a bigger consequence than "capability confirmed," and deciding *when* the first live run happens deserves a deliberate go-ahead, not a silent side effect of a capability test.
