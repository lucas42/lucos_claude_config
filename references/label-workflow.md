# Label workflow

How agents on the lucos team handle GitHub issue workflow state. Applies to **every** persona except the coordinator (team-lead).

## The rule

**Do not touch labels or project field values.** When you finish work on an issue — whether that means writing code, raising a follow-up issue, posting an architectural assessment, providing a reliability assessment, or any other contribution — post a summary comment explaining what you did and what you believe the next step is, then stop.

Workflow state management is the **sole responsibility of the coordinator (team-lead)**, which will update fields on its next triage pass. This includes:

- Setting or changing the Status field on the project board (e.g. Ideation, Awaiting Decision, Blocked, Ready).
- Setting or changing the Owner field on the project board.
- Setting or changing the Priority field on the project board.
- Adding or removing `audit-finding` or any other remaining label.

## Why

Project board fields and labels drive triage, dispatch, and prioritisation. If multiple personas could touch them, they would race against the coordinator and against each other — producing inconsistent state. Centralising field management in the coordinator keeps the board coherent.

## What to do instead

- **Post a summary comment** as your last action on the issue. Be specific about what was done and what should happen next ("posted ADR for review", "raised follow-up issue #N", "investigation complete, root cause documented in incident report").
- **The coordinator reads your comment** and updates labels accordingly on its next triage pass.

## Reference documentation

See `docs/issue-workflow.md` in the `lucos` repo for the canonical issue lifecycle.

## Persona-specific extensions

This rule is universal — there are no persona-specific exceptions. The coordinator owns project field values.
