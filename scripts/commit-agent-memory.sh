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
# Commit identity: lucos-system-administrator[bot]
# Bot user ID: 264392982 (used in noreply email for correct GitHub avatar)
#
# Usage: run manually or via cron, e.g.:
#   */15 * * * * /home/lucas.linux/.claude/scripts/commit-agent-memory.sh >> /home/lucas.linux/.claude/scripts/commit-agent-memory.log 2>&1

set -euo pipefail

CLAUDE_DIR="/home/lucas.linux/.claude"
IDENTITY_NAME="lucos-system-administrator[bot]"
IDENTITY_EMAIL="264392982+lucos-system-administrator[bot]@users.noreply.github.com"

# Ensure git uses the correct SSH key, even in cron's minimal environment.
# GIT_SSH_COMMAND overrides whatever SSH binary git would otherwise use.
export GIT_SSH_COMMAND="ssh -i /home/lucas.linux/.ssh/id_ed25519_lucos_agent -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

cd "$CLAUDE_DIR"

# Fetch the latest main so our diff baseline is accurate regardless of the
# currently checked-out branch.
git fetch --quiet origin main

# Check whether the working tree has any changes vs origin/main in the memory
# directories. We check modified tracked files, staged files, and untracked files.
if git diff --quiet origin/main -- agent-memory/ projects/ && \
   git diff --quiet --cached -- agent-memory/ projects/ && \
   [ -z "$(git ls-files --others --exclude-standard -- agent-memory/ projects/)" ]; then
    echo "$(date -Iseconds) No changes in agent-memory/ or projects/ vs origin/main — nothing to do."
    exit 0
fi

echo "$(date -Iseconds) Changes detected vs origin/main — committing to main via temporary worktree."

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

# Copy the current working-tree state of both memory directories into the
# worktree. cp -rT copies directory contents (not the directory itself as a
# child), so agent-memory/ → $WORKTREE_DIR/agent-memory/ (not /agent-memory/agent-memory/).
# Memory files are append-only by design — we do not delete files that exist on
# main but have been removed locally; that is intentional.
cp -rT "$CLAUDE_DIR/agent-memory/" "$WORKTREE_DIR/agent-memory/"
if [ -d "$CLAUDE_DIR/projects/" ]; then
    cp -rT "$CLAUDE_DIR/projects/" "$WORKTREE_DIR/projects/"
fi

cd "$WORKTREE_DIR"

# Stage only agent-memory/ and projects/ — nothing else.
git add agent-memory/ projects/

# If nothing actually changed after the copy (e.g. all changes were already on
# main from a previous tick), exit cleanly without an empty commit.
# The EXIT trap handles worktree cleanup.
if git diff --quiet --cached -- agent-memory/ projects/; then
    echo "$(date -Iseconds) Nothing to commit after sync — worktree already matches working tree."
    exit 0
fi

# Commit with the bot identity.
git \
    -c user.name="$IDENTITY_NAME" \
    -c user.email="$IDENTITY_EMAIL" \
    commit -m "Auto-commit agent memory updates"

echo "$(date -Iseconds) Committed. Pushing to main..."

git push origin HEAD:main

echo "$(date -Iseconds) Push complete."
# EXIT trap handles worktree cleanup.
