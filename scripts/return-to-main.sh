#!/bin/bash
# return-to-main.sh
#
# If the shared ~/.claude working tree is on a feature branch whose commits are
# fully contained in origin/main (i.e. the branch has been merged), switch the
# working tree back to main and attempt a fast-forward pull.
#
# Designed to run after commit-agent-memory.sh as part of the post-turn Stop
# hook (post-turn-hook.sh), so pending memory writes are already committed
# before we attempt checkout.
#
# Safe to run at any time:
# - Already on main → exits silently
# - Branch not yet merged → exits silently
# - Checkout blocked by dirty files → logs a warning, does not force

set -euo pipefail

CLAUDE_DIR="/home/lucas.linux/.claude"

export GIT_SSH_COMMAND="ssh -i /home/lucas.linux/.ssh/id_ed25519_lucos_agent \
    -o IdentitiesOnly=yes \
    -o StrictHostKeyChecking=accept-new"

cd "$CLAUDE_DIR"

current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")

# Already on main (or detached HEAD) — nothing to do
[[ "$current_branch" == "main" || "$current_branch" == "HEAD" ]] && exit 0

# Fetch to get an up-to-date view of origin/main.
# (commit-agent-memory.sh may have already fetched, but this is cheap.)
git fetch --quiet origin main 2>/dev/null || true

# If this branch's tip is not yet an ancestor of origin/main, work is in progress.
if ! git merge-base --is-ancestor HEAD origin/main 2>/dev/null; then
    exit 0
fi

# Guard: if HEAD is AT origin/main (they point to the same commit), the branch
# is empty — it was just created from main with no commits yet.  It is
# in-progress, not merged.  Return early.
#
# Without this guard, git merge-base --is-ancestor passes trivially when
# HEAD == origin/main (every commit is an ancestor of itself), which causes
# return-to-main to switch back immediately, delete the fresh branch, and send
# the next commit to main.  Reproduced and fixed in lucos_claude_config#117.
if [[ "$(git rev-parse HEAD 2>/dev/null)" == "$(git rev-parse origin/main 2>/dev/null)" ]]; then
    exit 0
fi

echo "$(date -Iseconds) Branch '$current_branch' merged into origin/main — switching working tree to main."

# Attempt checkout.  If dirty files that differ between the current branch and
# main block the checkout, log a warning and leave the tree alone rather than
# forcing a discard of another agent's uncommitted work.
if git checkout main 2>/dev/null; then
    echo "$(date -Iseconds) Switched to main (local HEAD: $(git rev-parse --short HEAD))."

    # Best-effort fast-forward to origin/main.  May fail if dirty files in the
    # tree conflict with commits on origin/main — that is acceptable; at least
    # we're on main rather than a stale feature branch.
    if git merge --ff-only origin/main 2>/dev/null; then
        echo "$(date -Iseconds) Fast-forwarded to origin/main at $(git rev-parse --short HEAD)."
    else
        echo "$(date -Iseconds) Could not fast-forward (uncommitted files conflict) — remaining at local main $(git rev-parse --short HEAD)."
    fi

    # Delete the now-merged local branch (safe delete — refuses if not fully merged)
    git branch -d "$current_branch" 2>/dev/null && \
        echo "$(date -Iseconds) Deleted local branch '$current_branch'." || true
else
    echo "$(date -Iseconds) WARNING: wanted to switch to main but checkout failed (dirty files blocking checkout). Manual cleanup needed." >&2
fi
