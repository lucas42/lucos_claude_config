---
name: team
description: Assemble the lucos agent team as teammates, optionally spawning only a subset
disable-model-invocation: false
---

Follow this process. Do not ask for clarification — immediately begin.

## Step 0: Parse arguments

Examine the text provided as arguments to `/team` (everything after the `/team` command, stripped of leading/trailing whitespace):

- **No arguments** → **spawn-all mode**: spawn every persona discovered in Step 2.
- **Arguments that start with `add ` (e.g. `/team add architect`)** → **add-teammate mode**: jump directly to the [Add-Teammate Mode](#add-teammate-mode) section and follow those steps. Do not continue with Steps 1–4.
- **Any other arguments** (e.g. `/team developer` or `/team developer,code-reviewer`) → **selective mode**: parse the argument as a comma-separated list of teammate names. Strip whitespace around each name. Prepend `lucos-` to any name that doesn't already start with it (e.g. `developer` → `lucos-developer`). If the resulting list includes `lucos-developer` but not `lucos-code-reviewer`, automatically add `lucos-code-reviewer` — the PR review loop requires it. Record this auto-addition and mention it when the skill completes.

Continue with Step 1.

## Step 1: Check for existing team

Before creating a new team, check whether `lucos-all-hands` already exists:

```bash
cat ~/.claude/teams/lucos-all-hands/config.json 2>/dev/null || echo "NO_TEAM"
```

**If NO_TEAM:** Proceed to Step 2 (create a new team).

**If the config exists:**

In **selective mode**: read the existing roster (the `name` fields in the `members` array) and compare it against your requested teammate list. If they differ in any way (different members, different count), stop immediately with this error:

> A team already exists with a different roster (`{existing members}`). To add a new teammate to the running team, use `/team add {name}`. To replace the team with a different roster, shut down the current team first.

In **spawn-all mode**: run the persona discovery command from Step 2 now (the `ls | grep -v` command) to get the expected full roster. Compare the existing team config roster against this full list. If they differ (existing team is a subset, a superset, or any mismatch), stop immediately with this error:

> A team already exists with a different roster (`{existing members}`). To add missing teammates, use `/team add {name}` for each one. To rebuild the full team, shut down the current team first.

In **selective or spawn-all mode with a matching roster**: proceed to [Step 1b](#step-1b-health-check-existing-team) to verify the team is still healthy.

## Step 1b: Health-check existing team

Send a test message to one teammate (e.g. the first member), then wait briefly for a response. The Bash tool blocks standalone `sleep N` commands where N ≥ 2 — you **must** run the sleep as a background command:

```bash
sleep 8 && echo done
```

Run this with `run_in_background: true`. You will be notified automatically when the background task completes — do not poll, re-check, or read the output file.

After the background sleep completes, check whether a teammate reply has appeared in the conversation (it will show as a `<teammate-message>` turn). If a reply arrived, the team is healthy — **stop here** and reuse the existing team.

If no teammate reply appeared by the time the background sleep completes, the team is stale. Clean up and proceed:

```bash
rm -rf ~/.claude/teams/lucos-all-hands ~/.claude/tasks/lucos-all-hands
```

## Step 2: Discover and filter personas

**Spawn-all mode:** Run this command to list all persona files, excluding non-persona files and the coordinator persona:

```bash
ls ~/.claude/agents/lucos-*.md | grep -v -e 'common-sections' -e 'ops-checks' -e 'circleci-api' -e 'issue-manager'
```

**Selective mode:** For each name in your requested roster, verify that the persona file exists:

```bash
ls ~/.claude/agents/{teammate-name}.md
```

If any persona file is missing, stop with an error: "No persona file found for `{teammate-name}`. Check the name and try again."

In both modes, derive the **teammate name** from each filename without the `.md` suffix (e.g. `lucos-developer`).

## Step 3: Create the team

Use the TeamCreate tool to create a team named `lucos-all-hands`.

## Step 4: Spawn teammates

**Never spawn a teammate if one with the same name already exists in the team config.** If TeamCreate appends a numeric suffix (e.g. `lucos-developer-2`), something has gone wrong — the cleanup step should have prevented this. Stop and investigate rather than continuing with suffixed names.

For **each** persona in your list (all discovered in spawn-all, or only the selective list), spawn a teammate using TeamCreate with these parameters:
- `team_name`: `lucos-all-hands`
- `name`: the teammate name (e.g. `lucos-developer`, `lucos-architect`)
- `prompt`: `"You have joined the lucos-all-hands team. Wait for instructions."`

### Spawn order (colour workaround)

Claude Code assigns teammate colours from a fixed palette in spawn order (blue, green, yellow, purple, orange, pink, cyan, red, ...) and ignores the `color` frontmatter field. To ensure each teammate gets the colour defined in its agent file, **spawn teammates in palette order**:

1. Read each agent file's `color` frontmatter value.
2. Sort the agents by their intended colour's position in the palette: blue=1, green=2, yellow=3, purple=4, orange=5, pink=6, cyan=7, red=8.
3. Spawn them one at a time in that order. Each spawn must complete before the next begins.

If a new persona is added whose colour already appears in the list, or whose colour is unknown, spawn it last (after all known-colour agents).

Do **not** hardcode the list of personas. Use whatever files the glob (or selective filter) produced.

**Colour accuracy in selective mode:** Colours will only match the frontmatter values if the spawned set occupies the same palette positions as it would in a full spawn (i.e. spawning from the low end of the palette). For example, spawning `lucos-developer` alone gives it slot 1 (blue) — which happens to match. But spawning only `lucos-security` and `lucos-architect` gives them slots 1 and 2 (blue and green), not orange and yellow as defined in their frontmatter. This is a Claude Code limitation with no workaround for partial spawns.

---

## Add-Teammate Mode

Use this path when `/team add {name}` is called. The coordinator persona is assumed to already be loaded — do **not** re-run Steps 1–4 or reload it at the end.

### A1: Normalise and validate the teammate name

Strip the leading `add ` from the argument to get the raw name. Prepend `lucos-` if it doesn't already start with it (e.g. `architect` → `lucos-architect`).

Verify the persona file exists:

```bash
ls ~/.claude/agents/{teammate-name}.md
```

If not found, stop: "No persona file found for `{teammate-name}`. Check the name and try again."

### A2: Check the existing team

```bash
cat ~/.claude/teams/lucos-all-hands/config.json 2>/dev/null || echo "NO_TEAM"
```

If NO_TEAM, stop: "No running team found. Use `/team` to start a team first."

Check whether the requested teammate is in the `members` array:

- **Not in the array** → proceed to A3.
- **In the array** → check if their process is still alive by looking up their `tmuxPaneId` and testing it:

```bash
tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -qF "{tmuxPaneId}" && echo "ALIVE" || echo "DEAD"
```

If **ALIVE**, stop: "`{teammate-name}` is already a member of this team."

If **DEAD** (crashed), the config entry is stale. Remove it before respawning:

```bash
python3 -c "
import json
with open('/home/lucas.linux/.claude/teams/lucos-all-hands/config.json') as f:
    config = json.load(f)
config['members'] = [m for m in config['members'] if m['name'] != '{teammate-name}']
with open('/home/lucas.linux/.claude/teams/lucos-all-hands/config.json', 'w') as f:
    json.dump(config, f, indent=2)
print('Removed stale entry for {teammate-name}')
"
```

Then proceed to A3.

### A3: Spawn the new teammate

Spawn using the Agent tool with:
- `team_name`: `lucos-all-hands`
- `name`: `{teammate-name}`
- `prompt`: `"You have joined the lucos-all-hands team. Wait for instructions."`

### A4: Report

Tell the user: "`{teammate-name}` has been added to the team."

---

## Shutting down the team

When the user asks to shut down the team:

1. Send a `shutdown_request` to every teammate **individually** (one SendMessage per teammate). Do not broadcast to `"*"` — structured messages cannot be broadcast and will error.
2. **Wait for every teammate to confirm shutdown** before proceeding. Do not call TeamDelete while any shutdown requests are still pending — that orphans processes.
3. Only after all confirmations are received, call TeamDelete to clean up.
