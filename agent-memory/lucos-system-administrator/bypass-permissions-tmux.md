---
name: bypassPermissions and tmux teammate backend
description: Why teammates prompt for permissions despite bypassPermissions being set, and the fix applied 2026-04-02
type: project
---

## Problem (discovered 2026-04-02, Claude Code 2.1.90)

In-process teammates hardcode `permissionMode: "default"` — they do NOT inherit `bypassPermissions` from the parent session. This causes per-action permission prompts despite `settings.json` having `permissions.defaultMode: "bypassPermissions"`.

The tmux backend DOES inherit the parent's permission mode (it reads `H.toolPermissionContext.mode` when spawning the subprocess).

## Fix applied

Two changes committed:

1. **`~/.claude/settings.json`** — added `"teammateMode": "tmux"` to force tmux backend for all teammates. Had to write via Python (`python3 -c "import json..."`) because the Edit tool's schema validator rejects `teammateMode` even though the JSON schema has `"additionalProperties": {}"`. Committed to `lucos_claude_config` (commit `cdec776`).

2. **`~/.bashrc`** — added auto-attach to tmux on login:
   ```bash
   if [ -z "$TMUX" ] && command -v tmux &>/dev/null; then
     tmux attach-session -t main 2>/dev/null || tmux new-session -s main
   fi
   ```
   Also added to `lucos_agent_coding_sandbox/lima.yaml` for fresh VMs (branch `fix/ssh-known-hosts-persistence`, commit `90bffea`).

## Why tmux is required

`teammateMode: "tmux"` only works if Claude is actually running inside a tmux session. If not, it falls back to in-process (`Yo1` fallback in `BackendRegistry`). The `.bashrc` auto-attach ensures this is always the case.

## Verification

After relogging into the VM, check:
- `echo $TMUX` — should be non-empty (confirms inside tmux)
- Start Claude and have a teammate run a bash command — should proceed without prompting

## If it still doesn't work

Possible causes:
- tmux session didn't start (check `echo $TMUX` is non-empty)
- Claude Code auto-updated past 2.1.90 and the tmux backend behaviour changed again
- The `teammateMode` key is being ignored (schema validator rejected it at write time but the runtime may also reject it — verify by checking Claude Code logs with `--debug`)
- A project-level `settings.local.json` exists at `/home/lucas.linux/sandboxes/.claude/settings.local.json` with a `permissions` block that interferes — check and delete if present
