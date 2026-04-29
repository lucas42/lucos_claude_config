---
name: coordinator
description: Reload the coordinator persona after a /clear (without re-assembling the team)
disable-model-invocation: true
---

Use this skill to restore the coordinator persona when the team is already running but the context was cleared (e.g. after `/clear`).

## Step 1: Load coordinator persona

Use the `Read` tool to read `~/.claude/agents/coordinator-persona.md` into your context. **Do not** `cat` it via Bash and **do not** echo its contents into your reply — the user does not need to see the 200+ lines of persona instructions every time they `/clear`. Reading it via the Read tool loads the instructions into your context just as effectively.

Once read, the file's instructions define your coordinator role for the remainder of this session. You are now operating as the team coordinator with the lucos-issue-manager persona for GitHub and git identity. Acknowledge briefly (one sentence) that the persona is loaded and you're ready for the next instruction.

