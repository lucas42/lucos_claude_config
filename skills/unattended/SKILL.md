---
name: unattended
description: Sweep the Ready column and dispatch every issue that can be taken end-to-end without lucas42's input
disable-model-invocation: true
---

Follow this process. Do not ask for clarification — begin at Step 0.

Invoking this skill **is** lucas42's explicit dispatch request, for every issue that clears the gates below. It is the batch equivalent of `/next`, and it is the only sanctioned way to dispatch more than one ticket in a pass.

**What it does not do.** It does not triage, re-triage, re-position the board, change Status/Owner/Priority to make an item eligible, approve, or merge. It dispatches what is *already* Ready and already correctly owned, and reports everything it held. An item that looks mis-triaged gets **reported**, never fixed-then-dispatched in the same breath — silently promoting an item into eligibility is how a sweep launders a coordinator decision into an authorisation lucas42 never gave.

**Do not post comments on tickets you hold.** A hold is not a triage outcome and does not need a paper trail on the ticket; the run report is the record. Ticket comments are for triage passes.

---

## Step 0: Preconditions

Confirm the implementation teammates are live — `tmux list-panes -a -F '#{pane_id} | #{pane_title}'`. `ListAgents` is blind after a `/clear` and its "no reachable agents" is never evidence of absence. An owner whose pane is absent is a **hold**, not a dispatch (re-add with `/team add {persona}` if lucas42 wants it running).

## Step 1: Enumerate the Ready column

```bash
~/.claude/skills/unattended/list-ready-issues --json
```

Board position order is authoritative — the same order `/next` walks. Work the list top-down. **Never reorder it, and never skip an item for any reason other than a gate below that you have actually evaluated.**

## Step 2: Gate every candidate

Evaluate the gates in tier order — Tier 1 is free, Tier 2 is one call per distinct repo (cache the result), Tier 3 costs a body-and-comments fetch, so let the cheap tiers shrink the set first. **A single failed gate is a hold**; record which one, and move to the next candidate.

**Tier 4 is applied before Tier 3, as a slot assignment.** After Tier 1–2, walk the survivors in board order and provisionally claim one slot per teammate and one per repo (Tier 4); only the slot-holders get a Tier 3 fetch. When a slot-holder fails Tier 3, it releases its slot and the next survivor in board order claims it — re-run Tier 3 on the new claimant. This avoids paying three API calls each for items that cannot be dispatched this wave regardless. **The consequence must be reported honestly: an item held at Tier 4 has *not* been content-checked, so its status next wave is unknown, not "eligible".** Never carry a Tier-4 hold forward as a verdict.

### Tier 1 — from the board scan (no extra calls)

| # | Gate | Hold when |
|---|---|---|
| 1 | **Status = Ready** | Anything else. Awaiting Decision is lucas42's queue by definition; Ideation, Needs Analysis and Blocked are not dispatchable at all. |
| 2 | **Owner is set** | Owner empty — the item is untriaged. Report the gap. |
| 3 | **Owner is a dispatchable teammate** | Owner = `lucas42` (the work *is* his manual action) or `lucos-issue-manager` (that is the coordinator — its work is done directly, not dispatched). Neither is a SendMessage target, and neither is a missing teammate: do **not** reach for `/team add` for `lucos-issue-manager`. Report coordinator-owned items so lucas42 can ask for them directly. |
| 4 | **Owner ≠ lucos-code-reviewer** | `lucos-code-reviewer` has no `implement issue` trigger and is never an implementation owner. Report the mis-triage. |
| 5 | **Owner's teammate is live and free** | Pane absent, or the teammate already holds an in-flight issue from this run (see Tier 4). |

### Tier 2 — repo supervision (one call per distinct repo)

| # | Gate | Hold when |
|---|---|---|
| 6 | `~/sandboxes/lucos_agent/check-unsupervised {repo}` — **exit 0 required** | Exit 1 (supervised: lucas42's approval is what merges the PR) or exit 2 (repo not in configy — **fail closed**, a repo the registry doesn't know cannot be shown to be unsupervised). Quote the result; never infer supervision from the repo name, memory, or an adjacent fact. |

Supervision is per-repo and varies within a single sweep. Roughly two-thirds of the estate is supervised, so this gate will hold the majority of the column — that is the control working, not a fault.

### Tier 3 — per-issue content (fetch body + **all** comments + reactions on both)

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues/{n}
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues/{n}/comments
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues/{n}/reactions
```

| # | Gate | Hold when |
|---|---|---|
| 7 | **No unanswered lucas42 activity** | A `lucas42` comment (or reaction) newer than the last `lucos-issue-manager[bot]` comment. That is the re-triage trigger — his input may change scope or direction, and dispatching over the top of it acts on stale direction. Report it for the next `/triage`. |
| 8 | **No lucas42-only manual step** | The body carries a `⚠️ Requires a manual step from lucas42` note, or body/comments describe a step outside agent access: writing a **non-`development`** credential in lucos_creds, a GitHub App permission change or installation approval, minting/rotating a production machine key, a registrar / DNS / third-party-console action. Check the *actual* environment before holding — a private key stored in `development` is a development value the team writes itself, and sensitive-sounding is not the test. |
| 8b | **Merging is what ships it** | The repo has no automated path from `main` to where the change must take effect, so a merge leaves the deliverable inert. The tell is in the acceptance criteria: **host-state assertions** ("`unattended-upgrade --dry-run` on xwing shows…") rather than repo-state ones. `lucos_agent_coding_sandbox` is the known instance — its provisioning scripts must be run as root on each host, and per `references/ssh-production.md` root-level host changes are structurally lucas42-only (`lucos-agent`'s entire sudo grant is `apt list --upgradable` on xwing/salvare, and nothing at all on avalon). Such a ticket also **auto-closes on merge via its closing keyword while its acceptance criteria are unmet**, so nothing downstream will notice. Gate 8 does not catch this: the manual step is a property of the deploy path, not a note in the body. |
| 9 | **No production dependency** | Shipping needs a prod credential, config value, sidecar or linked credential set in production *before or alongside* the deploy — i.e. the change would carry the `⚠️ Production dependencies ⚠️` marker on its PR. On an unsupervised repo the merge auto-deploys, so a change that lands ahead of its lucas42-only creds crash-loops production. |
| 10 | **Deliverable is not a design contract** | The deliverable is an ADR, or a spec / schema / auth or integration contract that other systems build against. Those ship as **draft** PRs pending lucas42's sign-off, so they cannot complete end-to-end. **Carve-out:** low-stakes *reversible* internal doc/config updates (`docs/priorities.md`, notes, non-contract config) are **not** design contracts — dispatch those normally. |
| 11 | **Not a production one-way door** | The work irreversibly changes production state: data deletion, volume/container teardown, a decommission or repo archival, a production credential rotation. Ready is the correct status for these and this is *not* a second sign-off gate — but the implementer's confirm-before-executing step lands on lucas42, so the ticket cannot finish unattended. Hold it for an explicit `/next` or `/dispatch`. |
| 12 | **No open dependency** | Any issue referenced as a blocker/prerequisite (including cross-repo `lucas42/other_repo#N`) is still open. `/dispatch` re-checks this; pre-screening just saves the cycle. |
| 13 | **No existing PR** | An open **non-draft** PR already closes the issue — the work is done and nothing needs dispatching. An open **draft** PR: read what it is parked on; if it waits on lucas42, hold. If the thing it waited on is now resolved, it *is* dispatchable — the implementer already has the branch. The `/timeline` endpoint is eventually-consistent: re-run an empty read once before trusting it. |
| 14 | **Not an estate rollout** | The fix is a `lucos_repos` convention change, or the same change applied across many repos. Those belong to `/estate-rollout` — staged batches, a `.github-test` smoke-test gate, and a dry-run diff — none of which an unattended sweep should drive. |

### Tier 4 — concurrency across the run

| # | Gate | Hold when |
|---|---|---|
| 15 | **One in-flight issue per teammate** | The owner already has an issue dispatched in this run. They become dispatchable again once the PR is open and they have reported back — not when it merges. |
| 16 | **One in-flight PR per repo** | Another issue on the same repo is already in flight this run. Concurrent PRs on one repo collide; parallelise across repos only. |

### Explicitly NOT exceptions — do not hold on these

- **Always-review repos.** A repo requiring `lucos-security` sign-off on every PR is not thereby supervised — `lucos_aithne` is always-review *and* unsupervised, and the bot approval merges it. Security review is a teammate's job, not lucas42's.
- **Priority and pick-up timing.** Coordinator-side calls. Never a reason to hold.
- **Irreversible work in general.** Only the *production* one-way doors in gate 11 are held. A fully-specified irreversible code change is Ready-eligible; `/next` and this skill are lucas42's sign-off.
- **CodeQL and other security-tool alerts.** `lucos-security` dispositions these and has `security_events: write`. Hold only if their assessment on the ticket names a step that genuinely requires lucas42.
- **`audit-finding` issues.** Triaged and dispatched like any other issue.
- **A ticket lucas42 filed himself.** Authorship is not a claim on the implementation.

## Step 3: Dispatch the survivors

In board order, for each eligible issue:

```
/dispatch {issue_url} owner:{owner}
```

Always `/dispatch` — never a hand-written `implement issue` SendMessage. It re-runs the dependency, existing-PR and estate-rollout guardrails as a second net, and owns post-completion (CI verification, unblocking dependents).

**Issue them one at a time and wait for each teammate's acknowledgement before starting the next.** Rapid consecutive sends are processed out of order. Different teammates then work in parallel; the wait is on the handoff, not on the work.

When a wave completes, **re-run Step 1 and re-evaluate the gates from scratch** before dispatching more. A merge can close a blocker and make a held item eligible, and lucas42 may have commented, reordered, or reassigned in the interim. Never carry a first-pass verdict into a later wave. Stop when a full pass produces no eligible items.

## Step 4: Report

Report only what this run produced:

- **Dispatched** — issue, owner, and (once they report back) PR URL and outcome.
- **Held** — issue and the single gate number that stopped it, in board order.
- **Mis-triaged** — items held on gates 2 or 4, plus any gate-7 re-triage triggers, so the next `/triage` picks them up.

The held list is a live product of this run's checks. Do not restate it in later turns, do not maintain it across the session, and do not turn it into a standing "waiting on you" queue — the board's own columns are that queue. If lucas42 asks later what is outstanding, query the board again at that moment.
