---
name: pattern-github-actions-outage-diagnosis
description: Check githubstatus.com/api EARLY when Actions triggers silently fail; estate-wide latest-run sweep to confirm; never relax branch protection to unstick a PR during an outage
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

### The confound: every PR opened during the window shares every local property

Teammates will arrive with a confident *local* explanation — "it's path-filtered", "it's because they were created as drafts", "it's this repo's workflow config". Those hypotheses are built from the only PRs available to look at, and **every PR opened inside the outage window is inside the outage window**, so any property those PRs happen to share is perfectly correlated with the real cause. With n=2 stuck PRs, nothing internal to that sample can separate the two.

Break it with a **counterexample from outside the window**: find a historical PR sharing the suspect property and check whether Actions ran on it.

- Suspected diff-shape/path filter → find a merged PR with the same diff shape. (2026-08-04 `lucos_worlds` `4a4e2eaa`: YAML-only, zero Python, `Analyze (python): success`.)
- Suspected draft suppression → find an older draft PR. (`lucos_backups#346`, `draft: true` to this day, created 2026-06-17, CodeQL fired on `pull_request` **8s** after opening, green `Analyze (python)`.)

Cheap sweep for candidates: `pulls?state=all&per_page=40 --jq '.[]|select(.draft==true)'` across a few repos.

Also check whether the stuck PR got **post-open pushes** (`pulls/{n}/commits` vs `created_at`). Each is a `synchronize` event, which is in the bare-`pull_request:` default set `[opened, synchronize, reopened]` and fires on drafts. If pushes after open produced no runs, any hypothesis about the *opening* event is already dead — and it means "just push to re-trigger" has been trial-run for free, so don't spend a head SHA (and its approvals) re-testing it.

Symmetry check that settles it: a local hypothesis must independently explain why *five other repos* stopped emitting runs of every event type at the same moment. Usually it has no account of that at all.

## When it IS an outage

Don't attempt remediation. Closing/reopening PRs and empty-commit pushes during the outage either get dropped too OR queue up and all fire at once when service returns (causing duplicate-run noise). The correct response is "wait for resolution, then re-check; if specific PRs still missing check-suites after Actions is healthy, *then* nudge."

⚠️ **Never relax branch protection to unstick a PR during an outage.** A missing required check reads exactly like a structural "this check can never fire on this diff shape" gap, and the obvious-looking remedy — drop the required context — is a *permanent* security regression traded for a *temporary* third-party outage. Before believing any "can never fire" claim, disconfirm it: read the workflow's `on:` block for real `paths:` filters, then find a historical SHA with a similarly-shaped diff and check `/commits/{sha}/check-runs` for that context concluding `success`. One counter-example kills the hypothesis.

### ⚠️ Read the incident BODY, not just the component status — throttling is probabilistic

The component status says `major_outage`; the *body* says how. On 2026-08-06 the 20:34Z update read: **"we are processing approximately 15% of webhooks"** and **"of jobs queued, approximately 65% are succeeding"** (up from 30-40%). Consequences, all of which change how you act:

- **Absence of runs is probabilistic, not binary.** At 15% delivery, a low-volume estate goes hours with nothing by chance. Don't treat "last run at HH:MM" as a hard cutoff or reason about a sharp onset — I did, and it's a throttle, not a stop.
- **This is why local hypotheses look so plausible.** Real `synchronize`/`opened` events are *emitted* and silently *not delivered*, which from the runs list is indistinguishable from "this trigger doesn't fire for this PR". The evidence genuinely points at the local theory.
- **`workflow_dispatch` is a direct API call, not a webhook-delivered event**, so it routes around the throttled path. This makes it the *right* re-trigger mechanism during throttling, not merely a convenient one — while "just push something to wake it up" reaches for precisely the mechanism GitHub has said is throttled.
- **An approval is also a webhook event.** At 15% delivery a single APPROVE has ~1-in-7 odds of reaching `code-reviewer-auto-merge.yml`. Plan an approve → *verify the run appeared* → re-approve loop, and warn the reviewer that a repeat ping means a dropped webhook, not a bad review.
- **<100% job success means a started run may fail or hang** ("runners being assigned jobs that are no longer valid"). Verify the check is **present and green on the SHA** — never infer it from a dispatch call returning 200.
- ⚠️ **Percentages in an incident body are snapshots of a deliberately moving quantity, and later updates often drop them.** The 15%/65% figures appeared at 20:34Z; the 21:30Z update still said "throttled" but stated no rate. Don't carry a rate forward as current, and don't hand derived odds ("~1-in-7 per approval") to a teammate without stamping the update they came from. Re-read the *latest* update before restating any number.
- **Two failure modes, distinguishable — diagnose before retrying.** Dropped webhook → **no run at all** for the SHA → re-approve, a fresh event is the fix. Delivered but bad runner assignment → **a failed/stuck run exists** → re-approving may just repeat it; investigate instead. Cheap check that stops you burning a teammate's approvals on the wrong remedy.

Set the recovery Monitor to fire on `operational` only, so it doesn't wake you into a partial recovery where everything needs retrying.

### Re-triggering after recovery — events do NOT replay

Runs missed during the outage are gone; the original `pull_request` / `pull_request_review` events never redeliver. Per stuck PR, by which trigger it needs:

- **CodeQL / any workflow with `workflow_dispatch:`** — dispatch it on the PR's branch. Check-runs attach to the branch head SHA, so this satisfies branch protection *without* moving the head SHA or invalidating approvals. Needs `actions:write` → `lucos-system-administrator`. (Reasoned from how check-runs attach, not yet observed end-to-end — verify on first use.)
- **`code-reviewer-auto-merge.yml`** — only listens to `pull_request_review: submitted`, so it needs a *fresh approval* from the matched reviewer (`lucos-code-reviewer`) on the unchanged HEAD. Re-running the old run does not work.

Order CodeQL first, then the re-approval, so auto-merge lands on an already-satisfiable PR.

⚠️ **Order a multi-PR recovery by REPLACEABILITY of what you'd lose, not by importance.** The recovery sequence itself is unproven (does `workflow_dispatch` really post the check against the unchanged head? does the approval webhook survive throttling?). So run it first on the PR where failure is cheapest — ideally one that is fully independent and whose only approval is an agent's, re-issuable in seconds. Save for last any PR carrying **lucas42's** approval, which we cannot regenerate ourselves if a head-SHA move discards it. On 2026-08-06 that made `lucos_worlds#72` (bot-approved, disjoint files) the canary ahead of #67/#68 (both carrying lucas42 approvals). Say explicitly that the ordering is a canary decision, not a severity one, or people read it as "SRE thinks there's a live exposure".

⚠️ **With two or more stuck PRs, merge them ONE AT A TIME with a mergeability re-check between.** `mergeable: true` is computed against the *current* base; when PR A merges, PR B is recomputed against the new one. A bad recompute needs a rebase, and **a rebase moves B's head SHA, which discards both its approvals AND the check-run you just spent the whole recovery obtaining** — sending B back for another `workflow_dispatch` and another round of approvals. Cheap insurance: `pulls/{n}/files --jq '[.[].filename]'` on each before planning the order. Never accept "they touch disjoint files" as an assertion — on 2026-08-06 `lucos_worlds` #67/#68 were twice described as disjoint by two different agents and both edited `README.md` (the changed hunks happened not to overlap, but nobody had looked).

## When it ISN'T an outage (per-repo drop)

The standard nudge is **close + reopen the PR** (preserves the head SHA, generates a fresh `pull_request opened` event, doesn't invalidate the approval). Empty-commit push is heavier (changes the SHA, may invalidate stale approvals depending on branch protection).

## Occurrences

Resolution is observable when GitHub status returns to "operational"/"none" AND a fresh push/PR action on any repo successfully triggers Actions again. Arm a `Monitor` polling the status API on recovery rather than hand-polling — outages run for hours and stuck PRs get forgotten.

- **2026-05-26** — `lucos_photos#407` (head `2068af86`, 10:56:51Z) and `#408` (`9a44257e`, 11:02:53Z). Outage from 10:57:13Z, "Incident with Actions and Pages", critical, components Actions + Pages.
- **2026-08-06** — `lucos_worlds#67` (head `123e3a3b`, 21:17:36Z). "Incident with Actions", critical, opened 15:22:49Z, Actions + Pages `major_outage`. Estate sweep of latest run per repo across 12 repos showed **nothing anywhere since 18:49:33Z** — that per-repo-latest-timestamp sweep is the cheapest, most decisive outage-vs-per-repo test I have; keep using it. Note the ~3h gap between incident open (15:22Z) and total estate stop (18:49Z): early in an incident Actions degrades *partially*, so "a repo ran something after the incident opened" does not disprove an outage. Escalation arrived pre-diagnosed with two wrong theories (CodeQL path-filtered to Python; auto-merge workflow broken for the repo) — one outage explained both, and the workflow had no `paths:` filter at all.
