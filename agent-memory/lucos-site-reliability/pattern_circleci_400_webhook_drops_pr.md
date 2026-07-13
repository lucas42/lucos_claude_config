---
name: pattern-circleci-400-webhook-drops-pr
description: Dependabot/other PR stuck `blocked` with CircleCI checks that NEVER fired = CircleCI 400'd the push webhook; GitHub doesn't retry 4xx so no pipeline exists. Diagnose via repo webhook delivery log; fix = POST a pipeline.
metadata:
  type: reference
---

**Symptom:** an approved PR sits `mergeable_state: blocked` with **no `ci/circleci:` statuses at all** on the head SHA and **zero pipelines** for its branch (`GET /api/v2/project/gh/lucas42/<repo>/pipeline?branch=<branch>` returns empty). Not a red check — a *missing* one.

**Root cause:** GitHub delivered the push webhook to CircleCI (`circleci.com/hooks/github`) but **CircleCI rejected it with HTTP `400 Invalid HTTP Response`**. GitHub treats 4xx as "delivered, don't retry" (only 5xx/timeouts retry), so the trigger is lost permanently. It's **intermittent CircleCI-side flakiness during Dependabot batch bursts** — in one 2026-07-13 burst, 2 of ~13 push deliveries per repo 400'd; 4 repos hit it at once (arachne#729, configy#252, media_import#177, notes#468). NOT branch-name, NOT ecosystem, NOT [skip ci], NOT a CircleCI outage — other PRs (even identical branch names, e.g. loganne) got 200 in the same window.

**Diagnose (the smoking gun is the webhook delivery log):**
```
# find the CircleCI hook id, then list failed push deliveries:
gh-as-agent ... repos/lucas42/<repo>/hooks --jq '.[]|select(.config.url|test("circleci.com/hooks/github"))|.id'
gh-as-agent ... "repos/lucas42/<repo>/hooks/<hid>/deliveries?per_page=100" --jq '.[]|select(.event=="push" and .status_code!=200)|"\(.delivered_at) \(.status_code) \(.id)"'
# confirm ref+after on a specific delivery (jq mangles the big int id — refetch id as string):
gh-as-agent ... "repos/lucas42/<repo>/hooks/<hid>/deliveries/<did>" --jq '{ref:.request.payload.ref, after:.request.payload.after}'
```

**Fix (SRE domain, ~2 min):** re-trigger a pipeline — `POST /api/v2/project/gh/lucas42/<repo>/pipeline` body `{"branch":"<branch>"}` (CIRCLECI_API_TOKEN). It runs against the PR head SHA, reports the required `ci/circleci:` statuses, and releases any queued auto-merge → PR merges itself. (Alt: redeliver the failed GitHub webhook delivery — replays the exact push.) Verify pipeline `vcs.revision` == PR head before trusting it.

**Tracking:** lucas42/lucos_repos#466 (P3) — diagnosis + runbook + durable-fix options (recommended disposition: accept + rely on existing `stale-dependabot-prs` audit detection; build auto-retrigger only if it recurs frequently). Existing `stale-dependabot-prs` check flags these after 48h. Related class: silent-drop where a green `/_info` / green other-checks hides a *missing* check.
