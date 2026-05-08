# Label workflow

How agents on the lucos team handle GitHub issue labels. Applies to **every** persona except the coordinator (team-lead).

## The rule

**Do not touch labels.** When you finish work on an issue — whether that means writing code, raising a follow-up issue, posting an architectural assessment, providing a reliability assessment, or any other contribution — post a summary comment explaining what you did and what you believe the next step is, then stop.

Label management is the **sole responsibility of the coordinator (team-lead)**, which will update labels on its next triage pass. This includes:

- Adding or removing `status:*` labels (e.g. `status:needs-design`, `status:awaiting-decision`, `status:blocked`, `status:ready`).
- Adding or removing `owner:*` labels.
- Adding or removing `priority:*` labels.
- Adding or removing `agent-approved`, `needs-refining`, or any other workflow label.
- Creating new labels.

## Why

Labels drive triage, dispatch, and prioritisation. If multiple personas could touch labels, they would race against the coordinator and against each other — producing inconsistent state on the project board. Centralising label management in the coordinator keeps the board coherent.

## What to do instead

- **Post a summary comment** as your last action on the issue. Be specific about what was done and what should happen next ("posted ADR for review", "raised follow-up issue #N", "investigation complete, root cause documented in incident report").
- **The coordinator reads your comment** and updates labels accordingly on its next triage pass.

## Reference documentation

See `docs/labels.md` and `docs/issue-workflow.md` in the `lucos` repo for the canonical label definitions and the issue lifecycle.

## Persona-specific extensions

This rule is universal — there are no persona-specific exceptions. The coordinator owns labels.
