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

## Phase 2: Triage and Summary (sequential — after Phase 1 completes)

Once Phase 1 is done, invoke the `/triage` skill using the Skill tool. The triage skill handles issue discovery, inline agent consultation, project board updates, board verification, and the summary for the user. Do not duplicate any of that work here.
