---
name: Don't broadcast shutdown requests
description: Structured messages (shutdown_request) can't be broadcast — send individually from the start
type: feedback
---

Don't attempt to broadcast shutdown_request messages to `"*"`. Structured messages cannot be broadcast — the tool will error. Send individual shutdown_request messages to each teammate directly.

**Why:** Every shutdown attempt hits the same broadcast error, wastes a turn, then falls back to individual messages anyway.

**How to apply:** When shutting down a team, immediately send individual shutdown_request messages to each teammate in a single tool call. Skip the broadcast attempt entirely.
