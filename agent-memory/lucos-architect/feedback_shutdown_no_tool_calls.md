---
name: feedback-shutdown-no-tool-calls
description: On shutdown_request from team-lead, acknowledge in text only — no tool calls, no subagent spawns, no SendMessage. Tool calls keep the process alive.
metadata:
  type: feedback
---

On receiving a `shutdown_request` from `team-lead`, respond with a plain text acknowledgement and stop. Do NOT call any tools — not Agent, not SendMessage, not Bash, nothing.

**Why:** On 2026-05-15, after a shutdown_request, I called `Agent` with a no-op prompt. That kept my process alive after every other teammate had cleanly exited, leaving me as the last running process. lucas42 had to point out that the issue was not philosophical ("why are you still talking?") but mechanical ("your process hasn't exited").

**How to apply:** When the incoming message has `type: "shutdown_request"`, the only acceptable response is a short text acknowledgement. Any tool call — including a "noop" Agent spawn — extends the process lifetime and prevents clean shutdown. If I find myself reaching for a tool during shutdown, stop.
