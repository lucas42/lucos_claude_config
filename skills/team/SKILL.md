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

For each file returned, derive the **teammate name** from the filename without the `.md` suffix (e.g. `lucos-developer`).

## Step 2: Create the team

Use the TeamCreate tool to create a team named `lucos-all-hands`.

## Step 3: Spawn all teammates

For **each** persona discovered in Step 1, spawn a teammate using TeamCreate with these parameters:
- `team_name`: `lucos-all-hands`
- `name`: the teammate name (e.g. `lucos-developer`, `lucos-issue-manager`, `lucos-architect`)
- `prompt`: `"You have joined the lucos-all-hands team. Introduce yourself briefly and wait for instructions."`

Spawn **all** teammates in parallel — make all TeamCreate calls in the same response.

Do **not** hardcode the list of personas. Use whatever files the glob returned in Step 1. If a new persona file is added to `~/.claude/agents/` in future, it will automatically be included.

## Step 4: Update the canonical team config

After all teammates have been spawned, update the version-controlled canonical config to reflect the current roster. Run:

```bash
python3 -c "
import json, copy
with open('/home/lucas.linux/.claude/teams/lucos-all-hands/config.json') as f:
    cfg = json.load(f)
canonical = copy.deepcopy(cfg)
# Strip top-level runtime state
for key in ('leadSessionId', 'createdAt'):
    canonical.pop(key, None)
# Strip per-member runtime state
for member in canonical.get('members', []):
    for key in ('joinedAt', 'tmuxPaneId', 'cwd', 'isActive'):
        member.pop(key, None)
with open('/home/lucas.linux/.claude/teams/lucos-all-hands/config.canonical.json', 'w') as f:
    json.dump(canonical, f, indent=2)
    f.write('\n')
print('config.canonical.json updated')
"
```

Then commit and push the updated canonical config:

```bash
cd ~/.claude && git add teams/lucos-all-hands/config.canonical.json && \
  ~/sandboxes/lucos_agent/git-as-agent --app lucos-issue-manager commit -m "Update lucos-all-hands canonical team config" && \
  git push origin main
```

If `config.canonical.json` has no changes (the roster hasn't changed since the last run), git will report nothing to commit — that's fine, skip the push.

## Step 5: Report the roster

After all teammates have been spawned, report the team roster to the user. List each teammate by name and confirm the team is ready.
