---
name: pattern-circleci-400-webhook-drops-pr
description: Dependabot/other PR stuck `blocked` with CircleCI checks that NEVER fired = CircleCI 400'd the push webhook; GitHub doesn't retry 4xx so no pipeline exists. Diagnose via repo webhook delivery log; fix = POST a pipeline.
metadata:
  type: reference
---

**Symptom:** an approved PR sits `mergeable_state: blocked` with **no `ci/circleci:` statuses at all** on the head SHA and **zero pipelines** for its branch (`GET /api/v2/project/gh/lucas42/<repo>/pipeline?branch=<branch>` returns empty). Not a red check — a *missing* one.

**⚠️ TWO DISTINCT MECHANISMS produce this identical symptom. Check which one before reciting a cause — they differ in evidence and in whether redelivery is even possible.**

**Mechanism A — CircleCI 400s the push (2026-07-13, 4 repos).** GitHub delivered the push webhook to CircleCI (`circleci.com/hooks/github`) but **CircleCI rejected it with HTTP `400 Invalid HTTP Response`**. GitHub treats 4xx as "delivered, don't retry" (only 5xx/timeouts retry), so the trigger is lost permanently. Intermittent CircleCI-side flakiness during Dependabot batch bursts — 2 of ~13 push deliveries per repo 400'd; 4 repos hit at once (arachne#729, configy#252, media_import#177, notes#468). NOT branch-name, NOT ecosystem, NOT [skip ci], NOT a CircleCI outage. **Delivery log shows a push delivery with status_code 400.** Redelivery is possible.

**Mechanism B — the push webhook is never delivered at all (2026-07-27, lucos_media_metadata_manager#380).** The delivery log contains `create` (200) and `pull_request` events (200) for the branch, and **no `push` delivery whatsoever** — not a 400, an absence. So there is nothing to redeliver; `POST pipeline` is the only fix. Hook itself was healthy (active, subscribed to `push`, `last_response` 200, created 2021). I could not distinguish "GitHub never generated the push event" from "generated but never logged/delivered" — from our side the observable is simply that no push delivery exists.

**The positive control that separates A from B** (run it — an absent delivery is meaningless without proof the log would have shown one): pick another repo hit by the *same* Dependabot burst and inspect its push delivery payloads. On 2026-07-27 `lucos_notes` had `ref=refs/heads/dependabot/…` with **`created=true`, `sender=dependabot[bot]`, 200** — proving a Dependabot branch creation normally *does* fire a logged `push` webhook. Without that control, "no push in the log" could just mean branch creations never fire push.

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
