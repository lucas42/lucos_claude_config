---
name: routine
description: All agents run ops checks, then the coordinator triages with inline agent consultation
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

Once Phase 1 is done, perform triage directly. You are the coordinator — triage is your responsibility, not a teammate's.

1. Read `~/.claude/references/triage-reference-data.md` for project board IDs, field mappings, and API patterns.
2. Follow the triage workflow from your coordinator persona: run `get-issues-for-triage`, process each issue, consult agents inline via SendMessage when needed, and update labels and the project board.
3. When consulting agents during triage, wait for each response before re-assessing the issue. Do not proceed to Phase 3 until all issues are processed and all consultations are complete.

## Phase 3: Summary for the user (after Phase 2 completes)

Once all phases are done, compile a prioritised list of issues that need the user's attention. This means any open issue with `owner:lucas42` — these are issues where only the repo owner can unblock progress (e.g. product direction, priority calls, decisions between options).

To find them:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager \
  'search/issues?q=label:"owner:lucas42"+org:lucas42+is:issue+is:open+sort:created-asc&per_page=50'
```

Note: the label name must be quoted in the query string (`label:"owner:lucas42"` not `label:owner:lucas42`) — GitHub's search parser treats `owner:` as a search qualifier otherwise, silently returning zero results.

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
