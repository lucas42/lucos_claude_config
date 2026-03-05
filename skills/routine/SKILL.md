---
name: routine
description: All agents review their issues and run ops checks
disable-model-invocation: true
---

Dispatch agents in four sequential phases using the Task tool. Do not ask for clarification — immediately begin Phase 1. You must wait for each phase to fully complete before starting the next.

## Phase 1: Triage (sequential — run immediately)

Launch one agent:

1. `lucos-issue-manager` — "triage your issues"

**Wait for it to complete before proceeding.**

Rationale: the issue manager runs first to assign `owner:` labels to unowned issues so that Phase 2 agents pick up fresh work.

## Phase 2: Issue Review (parallel — after Phase 1 completes)

Once Phase 1 is done, launch these six agents concurrently in the same response:

2. `lucos-architect` — "review your issues"
3. `lucos-system-administrator` — "review your issues"
4. `lucos-security` — "review your issues"
5. `lucos-site-reliability` — "review your issues"
6. `lucos-issue-manager` — "review your issues"
7. `lucos-developer` — "review your issues"

**Wait for all six to complete before proceeding.**

Rationale: these agents often add comments or partial work rather than immediately closing issues, which may leave issues needing reassignment or label transitions. The issue manager reviews workflow/process issues assigned to it (distinct from its Phase 1/4 triage role). The developer reviews issues where implementation input is needed during the design phase.

## Phase 3: Ops Checks (parallel — after Phase 2 completes)

Once Phase 2 is done, launch agents that have ops checks concurrently in the same response:

8. `lucos-code-reviewer` — "review your issues"
9. `lucos-security` — "run your ops checks"
10. `lucos-system-administrator` — "run your ops checks"
11. `lucos-site-reliability` — "run your ops checks"

**Wait for all to complete before proceeding.**

Rationale: ops checks are standing operational tasks that aren't tied to GitHub issues. Code review runs here because it's independent of the issue pipeline — PRs exist whether or not there are issues to review. Security reviews dependabot alerts. The system administrator checks container status, resource usage, backups, and other infrastructure health. Site reliability checks monitoring status, service health, and observability. They run after issue review so that any issues raised during ops checks can be triaged in Phase 4.

## Phase 4: Final Triage (sequential — after Phase 3 completes)

Once Phase 3 is done, launch one final agent:

12. `lucos-issue-manager` — "triage your issues"

Rationale: the issue manager triages any issues that Phase 2 and Phase 3 agents touched or raised, reassigns or transitions labels as appropriate, and tidies up anything left in an intermediate state.

Each agent knows how to discover its own backlog via its assigned labels.
