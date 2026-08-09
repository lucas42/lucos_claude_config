---
name: commit-agent-memory-sweep-attribution-fix
description: The auto-commit sweep (post-turn-hook.sh / 15-min cron) used to commit all personas' dirty memory files as one commit under sysadmin's identity — fixed to per-persona commits, 2026-08-09
metadata:
  type: reference
---

`~/.claude/scripts/commit-agent-memory.sh`'s sweep mode (no `--app` — used by
`post-turn-hook.sh`'s Stop hook, which fires after *every* turn for *every*
concurrent session, and by the 15-minute cron fallback) originally did one
giant commit spanning the whole `agent-memory/` tree, always attributed to
`lucos-system-administrator[bot]` regardless of whose files were actually
dirty.

**Consequence, caught by `lucos-architect` 2026-08-09**: because the Stop hook
fires so often and across every concurrent session, another persona's
in-flight (not-yet-committed) memory edit could get scooped up by someone
else's turn-end sweep before the author's own `commit-claude-main` call
landed — committing it under the wrong bot identity with a generic message,
silently discarding whatever rationale the actual author had written. Nothing
failed, nothing alerted; the content landed correctly, just under the wrong
name with the reasoning gone.

**Fixed**: sweep mode now iterates every `agent-memory/<persona>/`
subdirectory with pending changes and commits+pushes each one *separately*
under that persona's own looked-up identity — structurally identical to
calling `--app <persona>` directly, so it can never cross-attribute again. A
directory with no matching `personas.json` entry is skipped with a loud
warning rather than silently falling to the sysadmin catch-all. `projects/`
(dispatcher auto-memory, no single-persona owner) stays on the sysadmin
identity. Incidental fix in the same pass: the old all-in-one-commit design
meant a conflict-marker file anywhere in `agent-memory/` blocked the *entire*
sweep; each persona's commit is now isolated, so one persona's conflict no
longer holds everyone else's clean changes hostage.

Residual, accepted: a persona's own in-flight edit can still be grabbed by
the sweep before they commit it themselves — same-identity self-race, message
still generic — but that's a much smaller harm than another persona's
identity and rationale disappearing, which is what this fix actually closes.

Landed as `lucas42/lucos_claude_config@da85439`, tested first in an isolated
sandbox (throwaway bare repo + fake `personas.json`, zero production paths
touched) — see the commit message for the full test list.

Separately: don't run a broad `env | grep -i "secret-shaped-pattern"` on this
VM — it will print `LUCOS_AGENT_PEM` (the git-signing private key) in full.
Grep for specific expected var names only.
