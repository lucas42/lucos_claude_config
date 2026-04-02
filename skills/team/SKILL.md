---
name: team
description: Assemble the full lucos agent team as teammates
disable-model-invocation: true
---

Follow this process. Do not ask for clarification — immediately begin.

## Step 1: Check for existing team

Before creating a new team, check whether `lucos-all-hands` already exists with healthy members:

```bash
cat ~/.claude/teams/lucos-all-hands/config.json 2>/dev/null || echo "NO_TEAM"
```

If the team exists and has members listed, send a test message to one teammate (e.g. the first member) and **wait for an actual reply in the conversation**. Do NOT proceed until you have received a response message from the teammate — a successful `SendMessage` delivery confirmation is not enough. If no reply arrives within 15 seconds, the team is stale.

If the teammate replies, the team is healthy — **skip Steps 2–5 and go straight to Step 6** (load coordinator persona). Reuse the existing team.

If the team file doesn't exist, or exists but no teammate replies (stale from a previous session), clean up and proceed:

```bash
rm -rf ~/.claude/teams/lucos-all-hands ~/.claude/tasks/lucos-all-hands
```

## Step 2: Discover personas

Run this command to list all persona files, excluding non-persona files and the coordinator persona (which is loaded by the lead, not spawned as a teammate):

```bash
ls ~/.claude/agents/lucos-*.md | grep -v -e 'common-sections' -e 'ops-checks' -e 'circleci-api' -e 'issue-manager'
```

For each file returned, derive the **teammate name** from the filename without the `.md` suffix (e.g. `lucos-developer`).

## Step 3: Create the team

Use the TeamCreate tool to create a team named `lucos-all-hands`.

## Step 4: Spawn all teammates

**Never spawn a teammate if one with the same name already exists in the team config.** If TeamCreate appends a numeric suffix (e.g. `lucos-developer-2`), something has gone wrong — the cleanup step should have prevented this. Stop and investigate rather than continuing with suffixed names.

For **each** persona discovered in Step 2, spawn a teammate using TeamCreate with these parameters:
- `team_name`: `lucos-all-hands`
- `name`: the teammate name (e.g. `lucos-developer`, `lucos-architect`)
- `prompt`: `"You have joined the lucos-all-hands team. Wait for instructions."`

Spawn **all** teammates in parallel — make all TeamCreate calls in the same response.

Do **not** hardcode the list of personas. Use whatever files the glob returned in Step 2. If a new persona file is added to `~/.claude/agents/` in future, it will automatically be included.

## Step 5: Update the canonical team config

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

## Step 6: Load coordinator persona

Read the coordinator persona file and output its contents:

```bash
cat ~/.claude/agents/coordinator-persona.md
```

Output the contents verbatim. These instructions define your coordinator role for the remainder of this session. You are now operating as the team coordinator with the lucos-issue-manager persona for GitHub and git identity.

## Step 7: Report the roster

After loading the coordinator persona, report the team roster to the user. List each teammate by name and confirm the team is ready.

## Shutting down the team

When the user asks to shut down the team:

1. Send a `shutdown_request` to every teammate.
2. **Wait for every teammate to confirm shutdown** before proceeding. Do not call TeamDelete while any shutdown requests are still pending — that orphans processes.
3. Only after all confirmations are received, call TeamDelete to clean up.
