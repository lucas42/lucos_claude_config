#!/bin/bash
# commit-agent-memory.sh
#
# Automatically commits and pushes uncommitted changes in ~/.claude/agent-memory/
# and ~/.claude/projects/ (dispatcher auto-memory) directly to the main branch,
# regardless of which branch is currently checked out in ~/.claude.
#
# IMPORTANT — branch safety: this script always commits to main via a temporary
# git worktree. It never commits to, or pushes to, whatever feature branch a
# teammate might currently have checked out. This prevents memory updates from
# contaminating feature-branch PRs when cron fires mid-session.
#
# Scope: ONLY agent-memory/ and projects/ — not agents/, CLAUDE.md, settings.json,
# or any other config files. Those warrant deliberate review before going upstream.
#
# Designed to run via cron in a minimal environment:
# - Uses the full path to HOME (not relying on shell initialisation)
# - No SSH_AUTH_SOCK needed: the key at ~/.ssh/id_ed25519_lucos_agent has no
#   passphrase and is explicitly configured in ~/.ssh/config for github.com
#
# Usage:
#   commit-agent-memory.sh                  # sweep/cron mode: sysadmin bot, all agent-memory/ + projects/
#   commit-agent-memory.sh --app <persona>  # persona mode: persona's bot, only agent-memory/<persona>/
#
# In sweep mode (no args) the commit is attributed to lucos-system-administrator[bot]
# and covers both agent-memory/ (all personas' unsynced writes) and projects/ (dispatcher
# auto-memory).  This is the correct identity for the cron's catch-all sweep.
#
# In persona mode (--app <persona>) the commit is attributed to that persona's bot
# identity (looked up from ~/sandboxes/lucos_agent/personas.json) and is scoped
# exclusively to agent-memory/<persona>/.  Use this when committing from within a
# persona session so that memory history preserves per-agent attribution.
#
# Called primarily from post-turn-hook.sh (Claude Code Stop hook), which fires after
# every turn (in sweep mode).  Also called from a 15-minute cron as a fallback:
#   */15 * * * * /home/lucas.linux/.claude/scripts/commit-agent-memory.sh >> /home/lucas.linux/.claude/scripts/commit-agent-memory.log 2>&1

set -euo pipefail

CLAUDE_DIR="/home/lucas.linux/.claude"
PERSONAS_JSON="/home/lucas.linux/sandboxes/lucos_agent/personas.json"

# Default identity (sweep/cron mode — sysadmin bot)
IDENTITY_NAME="lucos-system-administrator[bot]"
IDENTITY_EMAIL="264392982+lucos-system-administrator[bot]@users.noreply.github.com"
APP=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --app)
            if [[ "$#" -lt 2 ]]; then
                echo "$(date -Iseconds) ERROR: --app requires a persona name." >&2
                exit 1
            fi
            APP="$2"
            shift 2
            ;;
        *)
            echo "$(date -Iseconds) ERROR: Unknown argument '$1'. Usage: $0 [--app <persona-name>]" >&2
            exit 1
            ;;
    esac
done

# If --app was provided, look up the persona's bot identity from personas.json.
# personas.json keys are persona names (e.g. "lucos-architect"); each entry has
# bot_name and bot_user_id used to construct the noreply attribution email.
if [[ -n "$APP" ]]; then
    BOT_INFO=$(python3 - "$APP" "$PERSONAS_JSON" <<'EOF'
import json, sys
app, path = sys.argv[1], sys.argv[2]
d = json.load(open(path))
p = d.get(app)
if not p:
    print(f"unknown-persona", "", sep="\t")
    sys.exit(1)
print(p["bot_name"], p["bot_user_id"], sep="\t")
EOF
    ) || {
        echo "$(date -Iseconds) ERROR: Unknown persona '$APP' — not found in personas.json." >&2
        exit 1
    }
    IDENTITY_NAME=$(echo "$BOT_INFO" | cut -f1)
    BOT_USER_ID=$(echo "$BOT_INFO" | cut -f2)
    IDENTITY_EMAIL="${BOT_USER_ID}+${IDENTITY_NAME}@users.noreply.github.com"
fi

# Ensure git uses the correct SSH key, even in cron's minimal environment.
# GIT_SSH_COMMAND overrides whatever SSH binary git would otherwise use.
export GIT_SSH_COMMAND="ssh -i /home/lucas.linux/.ssh/id_ed25519_lucos_agent -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

cd "$CLAUDE_DIR"

# Fetch the latest main so our diff baseline is accurate regardless of the
# currently checked-out branch.
git fetch --quiet origin main

# Determine which paths to check and commit based on mode.
# Persona mode: only the calling persona's subtree — avoids cross-attributing
# another persona's uncommitted writes, and keeps the commit targeted.
# Sweep mode: full agent-memory/ + projects/ (catch-all for the cron).
if [[ -n "$APP" ]]; then
    CHECK_PATHS=("agent-memory/$APP/")
else
    CHECK_PATHS=("agent-memory/" "projects/")
fi

# Check whether the working tree has any changes vs origin/main in the target paths.
# We check modified tracked files, staged files, and untracked files.
changes_exist=0
for path in "${CHECK_PATHS[@]}"; do
    if ! git diff --quiet origin/main -- "$path" || \
       ! git diff --quiet --cached -- "$path" || \
       [ -n "$(git ls-files --others --exclude-standard -- "$path")" ]; then
        changes_exist=1
        break
    fi
done

if [ "$changes_exist" -eq 0 ]; then
    echo "$(date -Iseconds) No changes in ${CHECK_PATHS[*]} vs origin/main — nothing to do."
    exit 0
fi

echo "$(date -Iseconds) Changes detected vs origin/main — committing as $IDENTITY_NAME via temporary worktree."

# Create a temporary worktree at origin/main.
# Using a worktree means we commit directly into the main branch object graph
# without disturbing whatever branch is currently checked out in CLAUDE_DIR.
WORKTREE_DIR=$(mktemp -d)
git worktree add --quiet "$WORKTREE_DIR" origin/main

# Ensure the worktree is removed on exit — whether success, error, or signal.
# The 2>/dev/null suppresses noise when the worktree was already cleaned up on
# the success path; || true prevents this handler from masking the original exit code.
_cleanup() {
    cd "$CLAUDE_DIR"
    git worktree remove --force "$WORKTREE_DIR" 2>/dev/null || true
}
trap _cleanup EXIT

# Copy the current working-tree state of the target paths into the worktree.
# cp -rT copies directory contents (not the directory itself as a child), so
# agent-memory/ → $WORKTREE_DIR/agent-memory/ (not /agent-memory/agent-memory/).
# Memory files are append-only by design — we do not delete files that exist on
# main but have been removed locally; that is intentional.
if [[ -n "$APP" ]]; then
    # Persona mode: copy only the persona's subtree.
    mkdir -p "$WORKTREE_DIR/agent-memory/$APP/"
    cp -rT "$CLAUDE_DIR/agent-memory/$APP/" "$WORKTREE_DIR/agent-memory/$APP/"
else
    # Sweep mode: copy full agent-memory/ and projects/.
    cp -rT "$CLAUDE_DIR/agent-memory/" "$WORKTREE_DIR/agent-memory/"
    if [ -d "$CLAUDE_DIR/projects/" ]; then
        cp -rT "$CLAUDE_DIR/projects/" "$WORKTREE_DIR/projects/"
    fi
fi

cd "$WORKTREE_DIR"

# Stage only the target paths — nothing else.
git add "${CHECK_PATHS[@]}"

# Safety guard: refuse to commit any file containing git conflict markers.
# Conflict-marker-laden files on main corrupt the persona's loaded context.
# Checks the staged index (post-add content), not the working tree.
# This catches a real incident: a conflict in agent-memory/lucos-architect/
# reference_firewall_dockeruser_scope.md landed on main (commit before c1ef559).
CONFLICT_FILES=$(git grep -l --cached "^<<<<<<< " -- "${CHECK_PATHS[@]}" 2>/dev/null || true)
if [ -n "$CONFLICT_FILES" ]; then
    echo "$(date -Iseconds) ERROR: Conflict markers found in staged files — aborting commit. Resolve conflicts manually then re-run:"
    echo "$CONFLICT_FILES"
    exit 1
fi

# If nothing actually changed after the copy (e.g. all changes were already on
# main from a previous tick), exit cleanly without an empty commit.
# The EXIT trap handles worktree cleanup.
if git diff --quiet --cached -- "${CHECK_PATHS[@]}"; then
    echo "$(date -Iseconds) Nothing to commit after sync — worktree already matches working tree."
    exit 0
fi

# Commit with the correct bot identity.
git \
    -c user.name="$IDENTITY_NAME" \
    -c user.email="$IDENTITY_EMAIL" \
    commit -m "Auto-commit agent memory updates"

echo "$(date -Iseconds) Committed. Pushing to main..."

git push origin HEAD:main

echo "$(date -Iseconds) Push complete."
# EXIT trap handles worktree cleanup.
