---
name: fyi-not-dispatch
description: FYI messages from team-lead are informational only — never a trigger to start work
metadata:
  type: feedback
---

Do NOT pick up an issue when team-lead sends an FYI notification about it, even if Status = Ready and Owner = lucos-ux.

**Why:** Issue selection is the dispatcher's job. The dispatcher polls the Ready column by priority and sends an explicit "implement issue {url}" message. Self-selecting from an FYI can jump a low-priority item ahead of higher-priority work in other queues. (Incident: picked up #395 from an FYI marked "Not a dispatch — purely FYI".)

**How to apply:** The only valid trigger to start implementation is the literal message "implement issue {url}" from the dispatcher (team-lead). FYI messages, triage notifications, and coordinator commentary are all read-only — acknowledge them mentally and wait.
