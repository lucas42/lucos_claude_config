---
name: team
description: Assemble the full lucos agent team as teammates
disable-model-invocation: true
---

Follow this process. Do not ask for clarification — immediately begin.

## Step 1: Discover personas

Run this command to list all persona files, excluding non-persona files:

```bash
ls ~/.claude/agents/lucos-*.md | grep -v -e 'common-sections' -e 'ops-checks' -e 'circleci-api'
```

For each file returned, derive the **teammate name** from the filename without the `.md` suffix (e.g. `lucos-developer`). This is also the `subagent_type`.

## Step 2: Create the team

Use the TeamCreate tool to create a team named `lucos-all-hands`.

## Step 3: Spawn all teammates

For **each** persona discovered in Step 1, spawn a teammate using the Task tool with these parameters:
- `team_name`: `lucos-all-hands`
- `name`: the teammate name (e.g. `lucos-developer`, `lucos-issue-manager`, `lucos-architect`)
- `subagent_type`: same as the teammate name (e.g. `lucos-developer`, `lucos-issue-manager`, `lucos-architect`)
- `prompt`: `"You have joined the lucos-all-hands team. Introduce yourself briefly and wait for instructions."`

Spawn **all** teammates in parallel — make all Task tool calls in the same response.

Do **not** hardcode the list of personas. Use whatever files the glob returned in Step 1. If a new persona file is added to `~/.claude/agents/` in future, it will automatically be included.

## Step 4: Report the roster

After all teammates have been spawned, report the team roster to the user. List each teammate by name and confirm the team is ready.
