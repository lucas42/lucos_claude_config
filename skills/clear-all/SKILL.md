---
name: clear-all
description: Clear conversation context for all teammates, then the dispatcher
disable-model-invocation: true
---

Clear conversation context across the entire team. Do not ask for clarification — immediately begin.

## Step 1: Send /clear to all teammates

Send a message to all teammates (broadcast) asking them to run `/clear`:

```
SendMessage to "*": "/clear"
```

**Wait for all teammates to confirm** they have cleared their context before proceeding.

## Step 2: Clear the dispatcher

Once all teammates have responded, run `/clear` yourself (the dispatcher) last.
