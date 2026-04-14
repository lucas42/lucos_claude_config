---
name: coordinator
description: Reload the coordinator persona after a /clear (without re-assembling the team)
disable-model-invocation: true
---

Use this skill to restore the coordinator persona when the team is already running but the context was cleared (e.g. after `/clear`).

## Step 1: Load coordinator persona

Read the coordinator persona file and output its contents verbatim:

```bash
cat ~/.claude/agents/coordinator-persona.md
```

These instructions define your coordinator role for the remainder of this session. You are now operating as the team coordinator with the lucos-issue-manager persona for GitHub and git identity.

