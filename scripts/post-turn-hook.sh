#!/bin/bash
# post-turn-hook.sh
#
# Claude Code Stop hook — runs after every turn.
# Keeps the shared ~/.claude working tree in a clean state by:
#
#   1. Committing any pending agent memory changes directly to main
#      (via the existing commit-agent-memory.sh worktree-based script).
#
#   2. Switching the working tree back to main if the current branch has
#      been merged into origin/main (via return-to-main.sh).
#
# Both steps are best-effort: a failure in step 1 does not prevent step 2
# from running, and neither failure prevents Claude from continuing work.
# Output is appended to per-script log files for post-hoc inspection.
#
# Registered in settings.json as:
#   "hooks": { "Stop": [{ "type": "command",
#     "command": "/home/lucas.linux/.claude/scripts/post-turn-hook.sh" }] }

SCRIPTS_DIR="/home/lucas.linux/.claude/scripts"

# Step 1: commit pending agent memory
"$SCRIPTS_DIR/commit-agent-memory.sh" \
    >> "$SCRIPTS_DIR/commit-agent-memory.log" 2>&1 || true

# Step 2: return to main if on a merged branch
"$SCRIPTS_DIR/return-to-main.sh" \
    >> "$SCRIPTS_DIR/return-to-main.log" 2>&1 || true
