#!/bin/bash
# prune-inboxes.sh
#
# Removes read messages from all team inbox files under ~/.claude/teams/.
# Inbox files grow indefinitely with an append-only pattern; read messages
# have no value after processing but consume context budget on every load.
#
# Also trims idle_notification messages — these are protocol-level signals
# that are always read immediately and serve no purpose as persistent history.
#
# Designed to run via cron in a minimal environment (no shell initialisation).
#
# Usage: run manually or via cron, e.g.:
#   */15 * * * * /home/lucas.linux/.claude/scripts/prune-inboxes.sh >> /home/lucas.linux/.claude/scripts/prune-inboxes.log 2>&1

set -euo pipefail

TEAMS_DIR="/home/lucas.linux/.claude/teams"

if [ ! -d "$TEAMS_DIR" ]; then
    echo "$(date -Iseconds) No teams directory found — nothing to do."
    exit 0
fi

pruned=0

for inbox in "$TEAMS_DIR"/*/inboxes/*.json; do
    [ -f "$inbox" ] || continue

    # Count messages before pruning
    before=$(jq 'length' "$inbox" 2>/dev/null || echo 0)

    # Keep only unread messages that are not idle_notifications
    tmp=$(mktemp)
    if jq '[.[] | select(
        .read != true and
        (
            (.text | try fromjson catch null | .type) != "idle_notification"
        )
    )]' "$inbox" > "$tmp" 2>/dev/null; then
        after=$(jq 'length' "$tmp" 2>/dev/null || echo 0)
        removed=$((before - after))
        if [ "$removed" -gt 0 ]; then
            mv "$tmp" "$inbox"
            echo "$(date -Iseconds) Pruned $removed messages from $(basename "$inbox") (${before} → ${after})"
            pruned=$((pruned + removed))
        else
            rm -f "$tmp"
        fi
    else
        rm -f "$tmp"
        echo "$(date -Iseconds) WARNING: Failed to parse $inbox — skipping"
    fi
done

if [ "$pruned" -eq 0 ]; then
    echo "$(date -Iseconds) No read messages to prune."
fi
