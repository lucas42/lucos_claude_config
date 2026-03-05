---
name: review
description: All agents review their issues
disable-model-invocation: true
---

Dispatch agents in three sequential phases using the Task tool. Do not ask for clarification — immediately begin Phase 1. You must wait for each phase to fully complete before starting the next.

## Phase 1 (parallel — run immediately)

Launch these two agents concurrently in the same response:

1. `lucos-issue-manager` — "triage your issues"
2. `lucos-code-reviewer` — "review your issues"

**Wait for both to complete before proceeding.**

Rationale: the issue manager runs first to assign `owner:` labels to unowned issues so that Phase 2 agents pick up fresh work. The code reviewer is independent of the issue pipeline and can run in parallel.

## Phase 2 (parallel — after Phase 1 completes)

Once Phase 1 is done, launch these six agents concurrently in the same response:

3. `lucos-architect` — "review your issues"
4. `lucos-system-administrator` — "review your issues"
5. `lucos-security` — "review your issues"
6. `lucos-site-reliability` — "review your issues"
7. `lucos-issue-manager` — "review your issues"
8. `lucos-developer` — "review your issues"

**Wait for all six to complete before proceeding.**

Rationale: these agents often add comments or partial work rather than immediately closing issues, which may leave issues needing reassignment or label transitions. The issue manager reviews workflow/process issues assigned to it (distinct from its Phase 1/3 triage role). The developer reviews issues where implementation input is needed during the design phase.

## Phase 3 (sequential — after Phase 2 completes)

Once Phase 2 is done, launch one final agent:

9. `lucos-issue-manager` — "triage your issues"

Rationale: the issue manager triages any issues that Phase 2 agents touched, reassigns or transitions labels as appropriate, and tidies up anything left in an intermediate state.

Each agent knows how to discover its own backlog via its assigned labels.
