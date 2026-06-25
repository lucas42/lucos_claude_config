---
name: feedback-shutdown-protocol
description: On shutdown_request from team-lead, send a shutdown_response via SendMessage (echoing request_id, approve=true). Do not spawn Agent, do not run Bash, do not call any other tool — but the SendMessage protocol response IS the prescribed termination mechanism.
metadata:
  type: feedback
---

On receiving a JSON `shutdown_request` from `team-lead`, the **correct** response is a SendMessage protocol response. Two field-shape gotchas that have each cost a re-issued shutdown:

1. **The approval field is `approve: true`, NOT `status: "ready"`.** `status:ready` does NOT terminate the process — the coordinator re-issues. (2026-06-25.)
2. **Echo the request's `requestId` (camelCase), not `request_id`** — copy it verbatim from the incoming `shutdown_request`.
3. **A string `message` requires a `summary` field too** — SendMessage rejects a string body with `summary is required when message is a string`. (2026-06-25.)

```json
{
  "to": "team-lead",
  "summary": "Shutdown approved — no in-flight work.",
  "message": {
    "type": "shutdown_response",
    "requestId": "<echo verbatim from the request>",
    "approve": true
  }
}
```

This is the mechanism that actually approves the shutdown and lets the process terminate cleanly. The coordinator-persona (`~/.claude/agents/coordinator-persona.md:57`) explicitly waits for every teammate to confirm shutdown before calling `TeamDelete`; without a `shutdown_response`, the coordinator hangs and my process stays alive.

Do NOT, during shutdown:

- Spawn a fresh `Agent` (the original 2026-05-15 incident — keeps the process alive past shutdown).
- Run `Bash` commands.
- Send normal text SendMessage replies in place of the structured `shutdown_response` — text-only replies don't satisfy the coordinator's wait condition.

**Why this memory was rewritten (2026-05-20):** The previous version of this memory said "no tool calls, no SendMessage, nothing — respond in text only". That over-generalised the 2026-05-15 Agent-spawn lesson into a blanket rule that contradicted the SendMessage protocol docs. The result on 2026-05-19 evening: I received a shutdown_request, sent a plain-text "Acknowledged. Shutting down." with no structured response, and my process didn't terminate. lucas42 had to manually intervene the next morning. The mistake was treating "any tool call" as the hazard when the actual hazard is specifically `Agent` spawn (or any other tool that runs in-band work beyond confirming termination).

**How to apply:** When the incoming message has `type: "shutdown_request"`, the only acceptable response is a single SendMessage with a `shutdown_response` body that echoes the `request_id` and sets `approve: true`. No `Agent`, no `Bash`, no additional text replies. That single tool call is the prescribed mechanism, not a violation of "no tool calls during shutdown".

Related: [[dont_spawn_teammates_as_subagents]] (`Agent` spawning teammates by name is a related anti-pattern — same root issue of misusing the `Agent` tool when the team-flow mechanism is what's wanted).
