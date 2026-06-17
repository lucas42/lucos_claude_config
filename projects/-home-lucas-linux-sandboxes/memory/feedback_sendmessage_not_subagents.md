---
name: feedback_sendmessage_not_subagents
description: "When the team is running, dispatch work via SendMessage to existing teammates — never spawn fresh subagents with the Agent tool"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 8a6bfd81-44b3-47e4-9c68-58e7b4379d50
---

When operating as coordinator with the team already running (e.g. after a `/coordinator` restore, which explicitly states "the team is already running"), dispatch all work to teammates via **SendMessage** to the existing named teammate (e.g. `lucos-system-administrator`, `lucos-architect`). Do NOT use the **Agent tool** to spawn fresh subagents for persona work.

**Why:** A fresh Agent-tool subagent (a) bypasses the running teammate, and (b) starts with zero accumulated session context, so it duplicates effort and loses continuity. lucas42 flagged this directly on 2026-06-17 when I spawned a fresh architect and then a fresh sysadmin via the Agent tool instead of messaging the running teammates.

**How to apply:** For any dispatch/consultation, call SendMessage with `to: "<teammate-name>"`. Only consider the Agent tool when there is genuinely no running team (rare for the coordinator). See [[feedback_developer_message_queue]] and the teammate-communication reference.
