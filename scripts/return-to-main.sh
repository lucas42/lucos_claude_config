#!/bin/bash
# return-to-main.sh
#
# Three jobs for the shared ~/.claude working tree:
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
# 3. After syncing on main, check whether the tree is still dirty — and if
#    so, whether it has been dirty for longer than one sweep cycle. A dirty
#    moment is normal (an in-flight memory write mid-commit, or a scratch
#    file mid-atomic-write) and resolves within a cycle on its own; a dirty
#    tree that PERSISTS is a file outside commit-agent-memory.sh's scope
#    (agents/, references/, scripts/, CLAUDE.md, .github/, ...) that someone
#    edited and never committed via commit-claude-main, with nothing else to
#    catch it. lucos_claude_config#129 — see the target definition there:
#    clean at any instant no agent is mid-write; anything that persists past
#    a cycle gets surfaced here rather than staying silent indefinitely.
#    Calibrated tight deliberately: post-#127 the synced state is durable and
#    self-correcting (no expected "decay"), so persistence past one cycle is
#    real signal, not noise to be tolerated.
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
# - Dirty tree persisting past one cycle (on main only) → logs a WARNING

set -euo pipefail

CLAUDE_DIR="/home/lucas.linux/.claude"

# State file for the persistence check (job 3) — records the epoch timestamp
# the tree was FIRST observed dirty in the current unbroken streak. Not
# committed (see .gitignore) — purely local bookkeeping, safe to lose (worst
# case: one streak's clock restarts, delaying a warning by up to one window).
DIRTY_STATE_FILE="$CLAUDE_DIR/scripts/.return-to-main-dirty-since"

# How long a dirty tree must persist before it's surfaced. The cron interval
# is 15 minutes and the post-turn hook fires far more often during active
# sessions, so 20 minutes is comfortably more than "one sweep cycle" even
# accounting for cron scheduling jitter, while still catching a forgotten
# edit well within the hour. See the header comment for why this must stay
# tight rather than being loosened to absorb false "decay".
DIRTY_QUIESCENCE_SECONDS=1200

export GIT_SSH_COMMAND="ssh -i /home/lucas.linux/.ssh/id_ed25519_lucos_agent \
    -o IdentitiesOnly=yes \
    -o StrictHostKeyChecking=accept-new"

# check_persistent_dirt — job 3. Call only on main, after the sync attempt
# above. Compares the current `git status --porcelain` against the recorded
# first-seen timestamp of the current dirty streak: clears the state file the
# moment the tree is clean, starts a new streak the moment it isn't, and logs
# a WARNING only once a streak has outlived DIRTY_QUIESCENCE_SECONDS. Never
# fatal — every path through this function returns 0.
check_persistent_dirt() {
    local porcelain
    porcelain=$(git status --porcelain 2>/dev/null) || return 0

    if [[ -z "$porcelain" ]]; then
        rm -f "$DIRTY_STATE_FILE" 2>/dev/null || true
        return 0
    fi

    local now first_seen elapsed
    now=$(date +%s)
    if [[ -f "$DIRTY_STATE_FILE" ]]; then
        first_seen=$(cat "$DIRTY_STATE_FILE" 2>/dev/null || echo "$now")
        # Guard against a corrupt/non-numeric state file rather than failing
        # the whole script under set -e on the arithmetic comparison below.
        [[ "$first_seen" =~ ^[0-9]+$ ]] || first_seen="$now"
    else
        first_seen="$now"
    fi
    echo "$first_seen" > "$DIRTY_STATE_FILE" 2>/dev/null || true

    elapsed=$((now - first_seen))
    if (( elapsed > DIRTY_QUIESCENCE_SECONDS )); then
        echo "$(date -Iseconds) WARNING: working tree has been dirty for ${elapsed}s (since $(date -Iseconds -d "@$first_seen")) — longer than one sweep cycle. This is likely a file outside commit-agent-memory.sh's scope (agents/, references/, scripts/, CLAUDE.md, .github/, ...) that was edited and never committed via commit-claude-main:" >&2
        echo "$porcelain" | sed 's/^/  /' >&2
    fi
    return 0
}

cd "$CLAUDE_DIR"

current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")

# On main: sync local HEAD/index to origin/main. See the header comment for
# why this must be exactly "main" (not detached HEAD) and must stay a plain
# mixed reset forever.
if [[ "$current_branch" == "main" ]]; then
    if git fetch --quiet origin main 2>/dev/null && git reset --mixed --quiet origin/main 2>/dev/null; then
        echo "$(date -Iseconds) Synced local main to origin/main ($(git rev-parse --short HEAD))."
        # Only check for persistent dirt once we know the index actually
        # reflects origin/main. A repeatedly-failing sync (network blip, SSH
        # key issue) leaves the index stale — the #127 shape — and running
        # the check there would misattribute that as a forgotten local edit
        # via check_persistent_dirt's "likely a file ... never committed"
        # wording. The "could not sync" WARNING in the else branch below
        # already surfaces the real cause on every cycle, so nothing is
        # lost by skipping this check during an outage.
        check_persistent_dirt
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
