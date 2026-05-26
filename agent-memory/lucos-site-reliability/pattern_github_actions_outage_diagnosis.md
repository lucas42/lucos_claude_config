---
name: pattern-github-actions-outage-diagnosis
description: Check githubstatus.com/api EARLY when GitHub Actions triggers seem to be silently failing on a repo
metadata:
  type: pattern
---

# GitHub Actions outage diagnosis — check status page first

When the symptom is "GitHub Actions workflows not triggering on new PRs / commits", the **first** diagnostic step is to check the GitHub status page, BEFORE chasing per-repo theories like changed workflow files, paths-ignore filters, branch protection, runner quotas, etc.

```bash
curl -sS -m 8 'https://www.githubstatus.com/api/v2/status.json' | jq '.status'
curl -sS -m 8 'https://www.githubstatus.com/api/v2/components.json' | jq '.components[] | select(.name | test("Actions"; "i"))'
curl -sS -m 8 'https://www.githubstatus.com/api/v2/incidents/unresolved.json' | jq '.incidents[]'
```

## Diagnostic signature of a GitHub Actions outage (vs a per-repo issue)

The smoking-gun pattern on an affected PR head SHA:

- Combined-status API (`/commits/{sha}/status`) shows CircleCI statuses fine (CircleCI is webhook-based — independent).
- `claude` check-suite (or any other GitHub App integration) is **present** with `status: queued`.
- **NO** `github-actions` check-suites at all on the SHA.
- `/actions/runs?branch={branch}` returns empty for ALL workflows (not just one).
- The repo's `/actions/permissions` returns `enabled: true, allowed_actions: all` (so it's not a repo-level disable).

If the github-actions check-suite is **entirely absent** (not just queued, not just failed), Actions never ingested the trigger event. Either it's a per-repo trigger-event drop OR it's a wider outage.

## Distinguishing wider outage from per-repo drop

- A wider outage means MANY repos stop firing Actions at roughly the same moment.
- A per-repo drop means lucos_photos goes silent while other repos still fire fine.

Don't trust "other repos still fire" too quickly at the start of an outage — recent successful runs from the minute *before* the outage hit can mislead you. Cross-check by looking at most-recent run timestamps across several repos and checking the GitHub status page directly. Status page is authoritative.

## When it IS an outage

Don't attempt remediation. Closing/reopening PRs and empty-commit pushes during the outage either get dropped too OR queue up and all fire at once when service returns (causing duplicate-run noise). The correct response is "wait for resolution, then re-check; if specific PRs still missing check-suites after Actions is healthy, *then* nudge."

## When it ISN'T an outage (per-repo drop)

The standard nudge is **close + reopen the PR** (preserves the head SHA, generates a fresh `pull_request opened` event, doesn't invalidate the approval). Empty-commit push is heavier (changes the SHA, may invalidate stale approvals depending on branch protection).

## 2026-05-26 occurrence

PRs `lucas42/lucos_photos#407` (head `2068af86`, created 10:56:51 UTC) and `#408` (head `9a44257e`, created 11:02:53 UTC) hit this. Outage started 10:57:13 UTC ("Incident with Actions and Pages", critical impact, components: Actions + Pages). Resolution observable when GitHub status returns to "operational" or "none" and a fresh push/PR action on any repo successfully triggers Actions again.
