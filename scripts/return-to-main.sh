#!/bin/bash
# return-to-main.sh
#
# Two jobs for the shared ~/.claude working tree:
#
# 1. If it's on a feature branch whose commits are fully contained in
#    origin/main (i.e. the branch has been merged), switch it back to main.
# 2. If it's already on main, sync local HEAD/index to origin/main — via
#    `git reset` in MIXED mode (the default; never --hard, never -u, never a
#    pathspec). Mixed reset only moves HEAD and the index; it never touches
#    working-tree files. Any file where the tree still differs from the new
#    index shows up afterwards as an ordinary unstaged modification, so an
#    in-flight uncommitted edit survives byte-for-byte and becomes MORE
#    visible (one of a handful of real diffs) rather than less (buried among
#    hundreds of phantom ones from a stale index). This is what actually
#    fixes lucos_claude_config#127: commit-claude-main and
#    commit-agent-memory.sh both commit via throwaway worktrees and never
#    advance this checkout's own HEAD, so without this job HEAD only drifts
#    further behind origin/main forever, and git status becomes exactly the
#    misleading "hundreds of files modified" shape that invites someone to
#    reach for `git reset --hard` — which CLAUDE.md correctly forbids here,
#    because it WOULD discard those in-flight edits.
#
# The main-branch sync in job 2 is guarded to run ONLY when the checkout is
# on a branch literally named "main" (not detached HEAD, not any other
# branch). `git reset <ref>` moves whatever branch is currently checked out —
# running it while parked on a feature branch would silently rewrite that
# branch to origin/main and orphan its commits, with no error. This checkout
# routinely holds dozens of local branches, many unmerged, so that is not a
# theoretical risk. Detached HEAD is left alone too — it isn't the steady
# state this addresses, and this script doesn't try to disambiguate why the
# tree would be detached.
#
# Designed to run after commit-agent-memory.sh as part of the post-turn Stop
# hook (post-turn-hook.sh), so pending memory writes are already committed
# before we attempt checkout or reset. Also runs from the 15-minute cron
# alongside commit-agent-memory.sh, so HEAD keeps converging even with no
# session live.
#
# Safe to run at any time:
# - On main → best-effort fetch + mixed reset to origin/main; never fatal
# - Branch not yet merged → exits silently
# - Checkout blocked by dirty files → logs a warning, does not force
# - Detached HEAD → exits silently

set -euo pipefail

CLAUDE_DIR="/home/lucas.linux/.claude"

export GIT_SSH_COMMAND="ssh -i /home/lucas.linux/.ssh/id_ed25519_lucos_agent \
    -o IdentitiesOnly=yes \
    -o StrictHostKeyChecking=accept-new"

cd "$CLAUDE_DIR"

current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")

# On main: sync local HEAD/index to origin/main. See the header comment for
# why this must be exactly "main" (not detached HEAD) and must stay a plain
# mixed reset forever.
if [[ "$current_branch" == "main" ]]; then
    if git fetch --quiet origin main 2>/dev/null && git reset --mixed --quiet origin/main 2>/dev/null; then
        echo "$(date -Iseconds) Synced local main to origin/main ($(git rev-parse --short HEAD))."
    else
        echo "$(date -Iseconds) WARNING: could not sync local main to origin/main (fetch or reset failed) — leaving HEAD as-is." >&2
    fi
    exit 0
fi

# Detached HEAD — nothing to do
[[ "$current_branch" == "HEAD" ]] && exit 0

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
