---
name: commit-claude-main-delete-support
description: commit-claude-main gained --delete for removing files from ~/.claude origin/main; commit-agent-memory.sh now strips atomic-write temp files before staging
metadata:
  type: reference
---

## `commit-claude-main --delete <path>` (lucas42/lucos_agent PR #73)

Removes a file from `~/.claude`'s `origin/main` without it needing to exist on disk — repeatable, combines with the normal positional add/update args in one commit. Same isolated-worktree safety pattern as the rest of the script (never touches the shared checkout). Use this instead of hand-rolling a `git worktree add` + `git rm` + commit + push sequence.

## `commit-agent-memory.sh` temp-file leak (fixed, lucos_claude_config@cc6b2e9)

Claude Code's Write/Edit tool writes `<name>.tmp.<pid>.<hash>` alongside the target and renames it into place. If the sweep's `cp` into its commit worktree lands in that window, the temp file gets staged and committed as a real memory file — happened twice (`agent-memory/lucos-security/*.tmp.*`, commits `6af519e`, `dc79389`), plus a third found stale-but-uncommitted on disk. Fix: `commit_scope()` now deletes `*.tmp.[0-9]*.*` from the worktree copy before `git add`. If you ever see a `.tmp.<digits>.<hash>` file under `agent-memory/`, it's this pattern — safe to delete if the source PID isn't running.

See also [[lucos-278-network-recreation-reporting-gap]].
