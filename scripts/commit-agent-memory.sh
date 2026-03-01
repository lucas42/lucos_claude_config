#!/bin/bash
# commit-agent-memory.sh
#
# Automatically commits and pushes uncommitted changes in ~/.claude/agent-memory/.
#
# Scope: ONLY agent-memory/ — not agents/, CLAUDE.md, settings.json, or any
# other config files. Those warrant deliberate review before going upstream.
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

# Check whether there are any uncommitted changes in agent-memory/ specifically.
# We check both staged and unstaged changes, plus untracked files in that dir.
if git diff --quiet HEAD -- agent-memory/ && \
   git diff --quiet --cached -- agent-memory/ && \
   [ -z "$(git ls-files --others --exclude-standard -- agent-memory/)" ]; then
    echo "$(date -Iseconds) No uncommitted changes in agent-memory/ — nothing to do."
    exit 0
fi

echo "$(date -Iseconds) Uncommitted changes detected in agent-memory/ — committing."

# Stage only agent-memory/ — nothing else
git add agent-memory/

# Commit with the bot identity
git \
    -c user.name="$IDENTITY_NAME" \
    -c user.email="$IDENTITY_EMAIL" \
    commit -m "Auto-commit agent memory updates"

echo "$(date -Iseconds) Committed. Pushing..."

git push

echo "$(date -Iseconds) Push complete."
