---
name: triage
description: The issue manager triages all open issues with inline agent consultation
disable-model-invocation: true
---

Dispatch the triage teammate and summarise the results. Do not ask for clarification — immediately begin.

## Step 1: Triage (send immediately)

Send a message to one teammate:

1. `lucos-issue-manager` — "triage your issues"

**Wait for the teammate to respond before proceeding.**

Rationale: the issue manager handles the full triage lifecycle in a single pass. When an issue needs input from another agent (e.g. architect, SRE, security), the issue manager messages that agent directly during triage, waits for their response, then re-assesses the issue. This continues until the issue is either `agent-approved` or needs input from lucas42.

## Step 2: Summary for the user (after Step 1 completes)

Once triage is done, compile a prioritised list of issues that need the user's attention. This means any open issue with `owner:lucas42` — these are issues where only the repo owner can unblock progress (e.g. product direction, priority calls, decisions between options).

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
