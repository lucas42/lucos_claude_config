---
name: routine
description: All agents review their issues and run ops checks
disable-model-invocation: true
---

Dispatch agents in sequential phases using the Task tool. Do not ask for clarification — immediately begin Phase 1. You must wait for each phase to fully complete before starting the next.

## Phase 1: Triage (sequential — run immediately)

Launch one agent:

1. `lucos-issue-manager` — "triage your issues"

**Wait for it to complete before proceeding.**

Rationale: the issue manager runs first to assign `owner:` labels to unowned issues so that later phases pick up fresh work.

## Phase 1.5: Propagation delay (after Phase 1, before Phase 2)

After Phase 1 completes, **wait 15 seconds** before starting Phase 2. Run `sleep 15` in a Bash tool call.

Rationale: Phase 1 applies `owner:` labels that later agents use to discover their work via the GitHub Issues API `?labels=` filter. GitHub's label-based API filtering can lag a few seconds behind label changes, so queries issued immediately after labelling may miss newly-labelled issues. This delay was added after lucos_agent#11 was missed by the architect in Phase 2 because the `owner:lucos-architect` label had not yet propagated.

## Phase 2: Ops Checks (parallel — after propagation delay)

Once the 15-second delay has elapsed, launch agents that have ops checks concurrently in the same response:

2. `lucos-code-reviewer` — "review any open PRs"
3. `lucos-security` — "run your ops checks"
4. `lucos-system-administrator` — "run your ops checks"
5. `lucos-site-reliability` — "run your ops checks"

**Wait for all to complete before proceeding.**

Rationale: ops checks run early so that any issues they raise can be triaged and reviewed in the same routine run, rather than waiting until the next run. PR review runs here because it's independent of the issue pipeline — PRs exist whether or not there are issues to review. Security reviews dependabot alerts. The system administrator checks container status, resource usage, backups, and other infrastructure health. Site reliability checks monitoring status, service health, and observability.

## Phase 3: Mid-routine Triage (sequential — after Phase 2 completes)

Once Phase 2 is done, launch one agent:

6. `lucos-issue-manager` — "triage your issues"

**Wait for it to complete before proceeding.**

Rationale: the issue manager triages any issues raised during ops checks, assigns `owner:` labels, and ensures they are ready for the issue review phase that follows.

## Phase 3.5: Propagation delay (after Phase 3, before Phase 4)

After Phase 3 completes, **wait 15 seconds** before starting Phase 4. Run `sleep 15` in a Bash tool call.

Rationale: same as Phase 1.5 — newly applied `owner:` labels need time to propagate in GitHub's API before Phase 4 agents query for their assigned issues.

## Phase 4: Issue Review (parallel — after propagation delay)

Once the 15-second delay has elapsed, launch these seven agents concurrently in the same response:

7. `lucos-architect` — "review your issues"
8. `lucos-system-administrator` — "review your issues"
9. `lucos-security` — "review your issues"
10. `lucos-site-reliability` — "review your issues"
11. `lucos-issue-manager` — "review your issues"
12. `lucos-developer` — "review your issues"
13. `lucos-code-reviewer` — "review your issues"

**Wait for all to complete before proceeding.**

Rationale: these agents often add comments or partial work rather than immediately closing issues, which may leave issues needing reassignment or label transitions. The issue manager reviews workflow/process issues assigned to it (distinct from its triage role). The developer reviews issues where implementation input is needed during the design phase. The code reviewer reviews closed issues it raised and any needs-refining issues assigned to it.

## Phase 5: Final Triage (sequential — after Phase 4 completes)

Once Phase 4 is done, launch one final agent:

14. `lucos-issue-manager` — "triage your issues"

Rationale: the issue manager triages any issues that Phase 4 agents touched or raised, reassigns or transitions labels as appropriate, and tidies up anything left in an intermediate state.

Each agent knows how to discover its own backlog via its assigned labels.

## Phase 6: Summary for the user (after Phase 5 completes)

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
