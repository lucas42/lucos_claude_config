---
name: github-actions-outage-diagnostic-signature
description: How to recognise a GitHub-platform Actions outage vs a real repo/CI problem, and how CircleCI vs Actions required-checks show up differently in the branch protection API
metadata:
  type: reference
---

**Symptom signature of a GitHub-wide Actions platform incident** (confirmed 2026-08-06, incident qcvjkzcs7j74, lucas42/lucos_creds#472/#484): a workflow run stays `status: queued` for ~15 minutes with no runner ever assigned, then the job resolves to `conclusion: cancelled` with an **empty `steps` array** (no step ever started). Fetching the raw log for that job returns `BlobNotFound` from GitHub's log storage (404) — itself part of the same incident, not a separate problem. Always cross-check `https://www.githubstatus.com/api/v2/incidents/unresolved.json` before treating this as a repo-specific CI break — a `critical`/`investigating` Actions incident there is conclusive.

**Useful cross-check to confirm it's Actions-specific, not estate-wide**: if CircleCI-driven required checks (`ci/circleci: test`, `ci/circleci: build`) complete normally in the same time window that GitHub Actions jobs (CodeQL, custom workflows) are stalling/getting cancelled, that's a clean signature isolating the outage to Actions specifically — CircleCI is a separate platform unaffected by a GitHub Actions incident.

**A cancelled run does not self-heal.** Once `status: completed` / `conclusion: cancelled`, it stays that way forever — the only fix is a fresh re-run (`POST .../actions/runs/{id}/rerun-failed-jobs`) once the platform incident clears. Don't watch the stuck run itself expecting it to resolve; watch the incident status instead, then manually re-trigger.

**Branch protection quirk — CircleCI checks don't appear in check-runs, only commit-statuses.** `GET /branches/{branch}/protection/required_status_checks` lists the required context *names* (e.g. `ci/circleci: test`), but to see whether they're actually green, query `GET /commits/{sha}/status` (combined status API) for CircleCI-sourced contexts — they report via the legacy commit-statuses mechanism, not the newer check-runs API used by GitHub Actions / CodeQL. Querying only check-runs will make it look like CircleCI's required checks are simply absent, when they're just reporting through a different endpoint. Don't infer "not required" or "missing" from an empty check-runs list alone — read `required_status_checks.contexts` directly (available to any App with `administration:read`/`write`, no need to infer merge-blocking status from `mergeable_state: unstable` vs `blocked`).
