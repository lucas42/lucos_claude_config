---
name: triage
description: The coordinator triages all open issues with inline agent consultation
disable-model-invocation: true
---

Perform triage directly and summarise the results. Do not ask for clarification — immediately begin.

## Step 1: Triage (do this yourself)

You are the coordinator — triage is your responsibility.

1. Read `~/.claude/references/triage-reference-data.md` for project board IDs, field mappings, and API patterns.
2. Follow the triage workflow from your coordinator persona: run `get-issues-for-triage`, process each issue, consult agents inline via SendMessage when needed, and update labels and the project board.
3. When consulting agents during triage, wait for each response before re-assessing the issue. Triage is complete when all issues are processed and all consultations are resolved.

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
