---
name: schedule
description: Create, update, list, or run scheduled remote agents (routines) that execute on a cron schedule. - When the user wants to schedule a recurring remote agent, set up automated tasks, create a cron job for Claude Code, or manage their scheduled agents/routines. Also use when the user wants a one-time scheduled run ("run this once at 3pm", "remind me to check X tomorrow").
---

# Schedule — Manage Remote Agent Routines

Use `RemoteTrigger` to create, update, list, and run scheduled remote agents on claude.ai.

**Important:** Routines run as remote agents in Anthropic's cloud — they have no access to local files, local services, local environment variables, or SSH to production hosts. For lucos ops work specifically (requires SSH to avalon/xwing/salvare and `gh-as-agent`), confirm with the user before creating a routine that the remote environment has those credentials wired in. If it doesn't, the routine will fail silently on any step that requires production access.

**FEASIBILITY GATE — applies at OFFER time, not just create time.** Before you even *offer* to `/schedule` something, check the task against what a remote cloud agent can do. If it needs **production SSH** (e.g. reading a host's `docker logs`, deploys, enforce flips), **`gh-as-agent`**, or **local files/repos**, it **cannot** run as a remote routine — so do not offer it. In the lucos estate most ops "future obligations" (log reviews, deploys, audit reruns, mode flips) need production access and are therefore NOT remotely schedulable; the right pattern for those is a dated reminder on the ticket + a project memory, run by the local team (which has production access) when a session is active on/after the date. Offering a `/schedule` you then have to walk back wastes the user's time — gate first. (Lesson: 2026-06-01, offered to schedule a firewall dry-run log review that needed host SSH; had to retract it.)

## Step 0: Discover environment_id (always do this first)

Every routine requires an `environment_id`. Discover it before doing anything else:

```
RemoteTrigger(action: "list")
```

If any triggers exist, extract `job_config.ccr.environment_id` from the first one — all triggers share the same environment.

If no triggers exist and the user hasn't provided an environment_id, ask them to find it at **https://claude.ai/code** → Environments section, then copy the environment ID. If they can't find one there, direct them to create an environment first.

## Step 1: Understand the goal

Ask what the remote agent should do, which repo(s) it needs access to, and what a successful run looks like. Remind them:
- The agent starts with zero context — the prompt must be fully self-contained.
- It cannot access local files or services.
- Minimum schedule interval is **1 hour**.

## Step 2: Craft the prompt

Help write an effective agent prompt. Good prompts are:
- Specific about the task and what success looks like
- Clear about which repos/files/areas to focus on
- Explicit about what actions to take (open PRs, commit, just analyse, etc.)

## Step 3: Set the schedule (cron or one-time)

Ask when and how often. **All cron expressions and `run_once_at` timestamps are UTC.** When the user says a local time, convert to UTC and confirm: `"9am BST = 8am UTC, so the cron would be 0 8 * * *"`.

For one-time runs: before computing `run_once_at`, re-fetch the current UTC time via Bash:
```bash
date -u +%Y-%m-%dT%H:%M:%SZ
```
Resolve relative requests ("tomorrow at 9am", "in 3 hours") against this fresh value, then confirm the absolute timestamp with the user.

Cron examples (UTC):
- `0 8 * * 1-5` — Every weekday at 8am UTC
- `0 */2 * * *` — Every 2 hours
- `0 0 * * *` — Daily at midnight UTC
- `0 8 1 * *` — First of every month at 8am UTC

Minimum interval is 1 hour — `*/30 * * * *` will be rejected.

## Step 4: Choose the model

Default to `claude-sonnet-4-6`. Tell the user the default and ask if they want a different one.

## Step 5: Review and confirm

Show the full configuration before creating. Let them adjust.

## Step 6: Create the routine

### v2 API body — recurring:
```json
{
  "name": "descriptive-routine-name",
  "prompt": "Full self-contained prompt for the remote agent",
  "cron_expression": "0 8 * * 1-5",
  "job_config": {
    "ccr": {
      "environment_id": "ENV_ID_FROM_STEP_0",
      "session_context": {
        "model": "claude-sonnet-4-6"
      }
    }
  }
}
```

### v2 API body — one-time run:
```json
{
  "name": "descriptive-routine-name",
  "prompt": "Full self-contained prompt for the remote agent",
  "run_once_at": "2026-05-30T10:00:00Z",
  "job_config": {
    "ccr": {
      "environment_id": "ENV_ID_FROM_STEP_0",
      "session_context": {
        "model": "claude-sonnet-4-6"
      }
    }
  }
}
```

**IMPORTANT — v1 format is broken.** Never put the prompt inside `job_config.ccr.session_context.events[...]`. That is a v1 format that the API now rejects with: `translate job_config v1→v2: job_config is not a valid CreateSessionRequest: unknown field "events"`. Always use `prompt` at the top level.

Call `RemoteTrigger(action: "create", body: {...})`. After success, output the management link:
`https://claude.ai/code/routines/{ROUTINE_ID}`

## Updating a routine

1. List routines so the user can pick one
2. Ask what to change
3. Show current vs proposed value
4. Call `RemoteTrigger(action: "update", trigger_id: "...", body: {...})`

Updatable fields: `name`, `cron_expression`, `run_once_at`, `enabled`, `job_config`, `mcp_connections`, `clear_mcp_connections` (boolean).

## Listing routines

`RemoteTrigger(action: "list")` — display name, schedule (human-readable), enabled/disabled, next run. Note: `ended_reason: "run_once_fired"` means a one-shot has already run. Re-arm it by updating with a new `run_once_at`.

## Running a routine immediately

`RemoteTrigger(action: "run", trigger_id: "...")` — confirm which routine first.

## Deleting a routine

No API delete via RemoteTrigger. Direct the user to https://claude.ai/code/routines to delete manually.
