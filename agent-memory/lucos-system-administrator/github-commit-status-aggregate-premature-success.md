---
name: github-commit-status-aggregate-premature-success
description: The aggregate "state" field on GET /commits/{sha}/status can read "success" before a specific downstream CI job (e.g. deploy-avalon queued behind a shared serial-group) has posted any status at all — always poll the named context, not the aggregate, when waiting for one specific job.
metadata:
  type: reference
---

`GET /repos/{owner}/{repo}/commits/{sha}/status`'s top-level `state` field aggregates only the contexts that have **already reported** for that commit — a job that hasn't started yet (e.g. `lucos/deploy-avalon`, queued behind another repo's deploy via the shared `serial-group: deploy-avalon`) is simply absent from `.statuses[]`, and the aggregate reads `"success"` as soon as every context that HAS reported is green, even though the actual job you care about hasn't run at all yet.

**Symptom:** polling `.state == "success"` as an exit condition for "is the deploy done" returns true while `.statuses[]` doesn't even contain a `lucos/deploy-avalon` entry — a premature positive. Hit this live on 2026-07-08 watching lucos_aithne#300's deploy: aggregate read `success` after `build-deploy/serial-start-2` posted, but `lucos/deploy-avalon` itself was still two serial-phases away from even starting.

**Fix:** when waiting on a specific downstream job (deploy, a required check, etc.), extract that named context from `.statuses[]` explicitly and poll for ITS state, not the top-level aggregate:

```bash
gh api repos/{owner}/{repo}/commits/{sha}/status --jq \
  '.statuses[] | select(.context == "ci/circleci: lucos/deploy-avalon") | .state'
```

Treat a missing/absent context as "not yet started," not "n/a" or "passing by default." This is the same family of pitfall as [[feedback_treat_empty_tool_output_as_unknown]] — an absent signal is unknown, never a positive result.
