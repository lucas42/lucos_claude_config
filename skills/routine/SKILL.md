---
name: routine
description: All agents run ops checks, then the issue manager triages with inline agent consultation
disable-model-invocation: true
---

Dispatch teammates in sequential phases using SendMessage. Do not ask for clarification — immediately begin Phase 1. You must wait for each phase to fully complete before starting the next.

## Phase 1: Ops Checks (parallel — run immediately)

Send messages to these teammates concurrently in the same response:

1. `lucos-code-reviewer` — "review any open PRs" (this also includes a stuck PR audit — the code reviewer checks for PRs stuck due to CI failures, blocked merge state, stale branches, auto-merge not triggering, workflow failures, unaddressed review feedback, or archived repos, and escalates each to the appropriate teammate)
2. `lucos-security` — "run your ops checks"
3. `lucos-system-administrator` — "run your ops checks"
4. `lucos-site-reliability` — "run your ops checks"

**Wait for all teammates to respond before proceeding.**

Rationale: ops checks run first so that any issues they raise are available for triage in Phase 2. PR review runs here because it's independent of the issue pipeline. Security reviews dependabot alerts. The system administrator checks container status, resource usage, backups, and other infrastructure health. Site reliability checks monitoring status, service health, and observability.

## Phase 2: Triage (sequential — after Phase 1 completes)

Once Phase 1 is done, send a message to one teammate:

5. `lucos-issue-manager` — "triage your issues"

**Wait for the issue manager to confirm triage is fully complete before proceeding.** The issue manager may send multiple messages during triage — interim updates about individual issues, responses to other agents' consultations, etc. Triage is only complete when the issue manager sends a final summary that includes a **total count of issues processed** and states there are **no pending consultations**. If the issue manager's message does not include both of these, it is an interim update — do not proceed to Phase 3 yet.

If you are unsure whether triage is complete (e.g. the issue manager sent a substantive update but didn't explicitly confirm completion), ask: "Is triage fully complete, or are there more issues to process?"

Rationale: the issue manager now handles the full triage lifecycle in a single pass. When an issue needs input from another agent (e.g. architect, SRE, security), the issue manager messages that agent directly during triage, waits for their response, then re-assesses the issue. This continues until the issue is either `agent-approved` or needs input from lucas42. This replaces the previous multi-phase triage-review-triage cycle. Because inline consultation can involve multiple back-and-forth messages, the dispatcher must wait for explicit confirmation rather than treating the first substantive reply as the final one.

## Phase 3: Summary for the user (after Phase 2 completes)

Once all phases are done, compile a prioritised list of issues that need the user's attention. This means any open issue with `owner:lucas42` — these are issues where only the repo owner can unblock progress (e.g. product direction, priority calls, decisions between options).

To find them:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager \
  "search/issues?q=label:owner:lucas42+org:lucas42+is:issue+is:open+sort:created-asc&per_page=50"
```

Present the list grouped and ordered by priority, consulting `~/sandboxes/lucos/docs/priorities.md` for the priority framework:

1. **Priority: high** — issues first, oldest first within the group
2. **Priority: medium** — next
3. **Priority: low** — last
4. **Unprioritised** — at the end (no `priority:*` label)

For each issue, show:
- The full clickable GitHub URL (e.g. `https://github.com/lucas42/lucos_photos/issues/5`)
- The issue title
- A one-line summary of what decision or input is needed (based on the status label and recent comments)

If there are no `owner:lucas42` issues, say so — that means there is nothing blocking on the user right now.
