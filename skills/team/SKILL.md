---
name: team
description: Assemble the lucos agent team as teammates, optionally spawning only a subset
disable-model-invocation: false
---

Follow this process. Do not ask for clarification — immediately begin.

## How teams work in this Claude Code version

Teams are **session-keyed and auto-created**. There is no named-team concept and no
team-creation/deletion tool: the team forms implicitly the moment you spawn the first
teammate with the **Agent tool**, and its config lives at:

```
~/.claude/teams/session-${CLAUDE_CODE_SESSION_ID:0:8}/config.json
```

The `team_name` input on the Agent tool is accepted but ignored, so you cannot choose a
name — the team is identified by this session's id. Throughout this skill, derive the
config path from the session id rather than hardcoding a name:

```bash
TEAM_CONFIG="$HOME/.claude/teams/session-${CLAUDE_CODE_SESSION_ID:0:8}/config.json"
cat "$TEAM_CONFIG" 2>/dev/null || echo "NO_TEAM"
```

Because the team is keyed to the **current** session, a fresh session always starts with
no team — you will not pick up a stale team from a previous session. The only "existing
team" case is re-running `/team` within the same live session.

## Step 0: Parse arguments

Examine the text provided as arguments to `/team` (everything after the `/team` command, stripped of leading/trailing whitespace):

- **No arguments** → **spawn-all mode**: spawn every persona discovered in Step 2.
- **Arguments that start with `add ` (e.g. `/team add architect`)** → **add-teammate mode**: jump directly to the [Add-Teammate Mode](#add-teammate-mode) section and follow those steps. Do not continue with Steps 1–4.
- **Any other arguments** (e.g. `/team developer` or `/team developer,code-reviewer`) → **selective mode**: parse the argument as a comma-separated list of teammate names. Strip whitespace around each name. Prepend `lucos-` to any name that doesn't already start with it (e.g. `developer` → `lucos-developer`). If the resulting list includes `lucos-developer` but not `lucos-code-reviewer`, automatically add `lucos-code-reviewer` — the PR review loop requires it. Record this auto-addition and mention it when the skill completes.

Continue with Step 1.

## Step 1: Check for existing team

Before spawning, check whether this session already has a team:

```bash
TEAM_CONFIG="$HOME/.claude/teams/session-${CLAUDE_CODE_SESSION_ID:0:8}/config.json"
cat "$TEAM_CONFIG" 2>/dev/null || echo "NO_TEAM"
```

**If NO_TEAM** (or the config has no members besides `team-lead`): Proceed to Step 2.

**If the config exists with teammate members:**

In **selective mode**: read the existing roster (the `name` fields in the `members` array, excluding `team-lead`) and compare it against your requested teammate list. If they differ in any way (different members, different count), stop immediately with this error:

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

If no teammate reply appeared by the time the background sleep completes, the team is stale. Do **not** delete the session team directory — the harness owns it and auto-removes it when the session ends. Instead, prune only the dead member entries (those whose tmux pane is no longer alive), then fall through to Step 2/Step 4, which will respawn the missing personas:

```bash
python3 - <<'PY'
import json, os, subprocess
cfg = os.path.expanduser(f"~/.claude/teams/session-{os.environ['CLAUDE_CODE_SESSION_ID'][:8]}/config.json")
config = json.load(open(cfg))
alive = set(subprocess.check_output(['tmux', 'list-panes', '-a', '-F', '#{pane_id}'], text=True).split())
before = len(config['members'])
config['members'] = [m for m in config['members']
                     if m.get('backendType') != 'tmux' or m.get('tmuxPaneId') in alive]
json.dump(config, open(cfg, 'w'), indent=2)
print(f"Pruned {before - len(config['members'])} dead member entr(ies)")
PY
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

## Step 3: Spawn teammates

There is no separate team-creation step — the team forms automatically when the first
teammate is spawned. Spawn each teammate with the **Agent tool**.

**Never spawn a teammate whose name already exists in the team config AND whose tmux pane is still alive.** Spawning a duplicate name is a sign something has gone wrong (a stale entry that should have been pruned in Step 1b, or a roster mismatch that should have stopped earlier) — stop and investigate rather than continuing. Dead/pruned entries are fine to respawn.

For **each** persona in your list (all discovered in spawn-all, or only the selective list), spawn a teammate using the **Agent tool** with these parameters:
- `subagent_type`: the persona name (e.g. `lucos-developer`) — this is what loads the persona; it is required
- `name`: the same persona name (gives the teammate its canonical SendMessage address, e.g. `lucos-developer@session-…`)
- `prompt`: `"You have joined the lucos agent team. Wait for instructions."`
- `run_in_background`: `true`

Do **not** pass `model` — the Agent tool resolves each persona's model from its agent-file frontmatter (e.g. `lucos-architect` runs on opus, others on sonnet). Do **not** rely on `team_name` — it is ignored in this version.

> **Expected UI note:** because the Agent tool is also the generic subagent tool, every teammate you spawn is shown twice — once in the team roster (titled by its `subagent_type`) and once in the lead's own frame's subagent list (labelled by its `name`). These are **two views of one process**, not duplicates: there is a single tmux pane / pid per teammate, and nothing is tracked in `~/.claude/tasks/`. This is inherent to spawning teammates via the Agent tool in this version and cannot be suppressed; it is not a leak. If you mention it to the user, say so plainly rather than implying two sets of agents exist.

### Spawn order (colour workaround)

Claude Code assigns teammate colours from a fixed palette in spawn order (blue, green, yellow, purple, orange, pink, cyan, red, ...) and ignores the `color` frontmatter field — it records whatever colour the spawn slot dictates. To ensure each teammate gets the colour defined in its agent file, **spawn teammates in palette order**:

1. Read each agent file's `color` frontmatter value.
2. Sort the agents by their intended colour's position in the palette: blue=1, green=2, yellow=3, purple=4, orange=5, pink=6, cyan=7, red=8.
3. Spawn them one at a time in that order. Each Agent-tool spawn must return before the next begins.

If a new persona is added whose colour already appears in the list, or whose colour is unknown, spawn it last (after all known-colour agents).

Do **not** hardcode the list of personas. Use whatever files the glob (or selective filter) produced.

**Colour accuracy in selective mode:** Colours will only match the frontmatter values if the spawned set occupies the same palette positions as it would in a full spawn (i.e. spawning from the low end of the palette). For example, spawning `lucos-developer` alone gives it slot 1 (blue) — which happens to match. But spawning only `lucos-security` and `lucos-architect` gives them slots 1 and 2 (blue and green), not orange and yellow as defined in their frontmatter. This is a Claude Code limitation with no workaround for partial spawns.

---

## Add-Teammate Mode

Use this path when `/team add {name}` is called. The coordinator persona is assumed to already be loaded — do **not** re-run Steps 1–3 or reload it at the end.

### A1: Normalise and validate the teammate name

Strip the leading `add ` from the argument to get the raw name. Prepend `lucos-` if it doesn't already start with it (e.g. `architect` → `lucos-architect`).

Verify the persona file exists:

```bash
ls ~/.claude/agents/{teammate-name}.md
```

If not found, stop: "No persona file found for `{teammate-name}`. Check the name and try again."

### A2: Check the existing team

```bash
TEAM_CONFIG="$HOME/.claude/teams/session-${CLAUDE_CODE_SESSION_ID:0:8}/config.json"
cat "$TEAM_CONFIG" 2>/dev/null || echo "NO_TEAM"
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
python3 - <<'PY'
import json, os
cfg = os.path.expanduser(f"~/.claude/teams/session-{os.environ['CLAUDE_CODE_SESSION_ID'][:8]}/config.json")
config = json.load(open(cfg))
config['members'] = [m for m in config['members'] if m['name'] != '{teammate-name}']
json.dump(config, open(cfg, 'w'), indent=2)
print('Removed stale entry for {teammate-name}')
PY
```

Then proceed to A3.

### A3: Spawn the new teammate

Spawn using the **Agent tool** with:
- `subagent_type`: `{teammate-name}` (required — loads the persona)
- `name`: `{teammate-name}`
- `prompt`: `"You have joined the lucos agent team. Wait for instructions."`
- `run_in_background`: `true`

### A4: Report

Tell the user: "`{teammate-name}` has been added to the team."

---

## Shutting down the team

There is no team-deletion tool in this version — shutdown is driven entirely through
`SendMessage`, and the harness removes the session team directory automatically once the
processes exit.

When the user asks to shut down the team:

1. Send a `shutdown_request` to every teammate **individually** (one SendMessage per teammate). Do not broadcast to `"*"` — structured messages cannot be broadcast and will error.
2. **Wait for every teammate to confirm shutdown** (each replies with a `shutdown_approved` / `teammate_terminated` message and releases its tmux pane) before reporting completion.
3. Once all teammates have confirmed, the team is down — no explicit delete call is needed or possible.
