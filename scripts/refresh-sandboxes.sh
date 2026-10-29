#!/bin/bash
# refresh-sandboxes.sh — keep the per-repo checkouts under ~/sandboxes current with origin.
# Runs hourly from cron. lucos_agent_coding_sandbox#96.
#
# Per repo: fetch, then fast-forward the working tree ONLY if all hold (else leave it, log why):
#   clean     — no modified/staged tracked files (untracked files are fine)
#   idle      — no rebase/merge/cherry-pick/revert/bisect in progress
#   merged    — HEAD is an ancestor of origin/<default> (so no commit can be lost)
# The checked-out branch is never switched. Never runs reset/checkout/clean/stash/pull/--force.

set -uo pipefail

SANDBOXES_DIR="${SANDBOXES_DIR:-$HOME/sandboxes}"
LOCK_FILE="${LOCK_FILE:-$HOME/.claude/scripts/.refresh-sandboxes.lock}"
FETCH_TIMEOUT="${FETCH_TIMEOUT:-60}"
export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -i $HOME/.ssh/id_ed25519_lucos_agent -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o BatchMode=yes}"
export GIT_TERMINAL_PROMPT=0

log() { echo "$(date -Iseconds) $*"; }

exec 9>"$LOCK_FILE"
flock -n 9 || { log "another run holds the lock; exiting"; exit 0; }

fetched=0; ffwd=0; dirty=0; unmerged=0; busy=0; ffail=0; fetchfail=0

for dir in "$SANDBOXES_DIR"/*/; do
    dir="${dir%/}"; name=$(basename "$dir")
    [ -e "$dir/.git" ] || continue
    [ "$(realpath "$dir")" = "$(realpath "$HOME/.claude")" ] && continue   # handled by return-to-main.sh
    git -C "$dir" remote get-url origin >/dev/null 2>&1 || continue

    if ! timeout "$FETCH_TIMEOUT" git -C "$dir" fetch --prune --quiet origin 2>/dev/null; then
        fetchfail=$((fetchfail+1)); log "FETCH-FAILED $name"; continue
    fi
    fetched=$((fetched+1))

    default=$(git -C "$dir" symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null); default="${default#origin/}"
    default="${default:-main}"
    if ! git -C "$dir" rev-parse -q --verify "refs/remotes/origin/$default" >/dev/null; then
        log "SKIP $name: no origin/$default"; continue
    fi

    gd=$(git -C "$dir" rev-parse --absolute-git-dir 2>/dev/null) || { log "SKIP $name: unusable git dir"; continue; }
    if [ -n "$(git --no-optional-locks -C "$dir" status --porcelain --untracked-files=no 2>/dev/null)" ]; then
        dirty=$((dirty+1)); log "SKIP $name: modified or staged tracked files"; continue
    fi
    if [ -e "$gd/rebase-merge" ] || [ -e "$gd/rebase-apply" ] || [ -e "$gd/MERGE_HEAD" ] || \
       [ -e "$gd/CHERRY_PICK_HEAD" ] || [ -e "$gd/REVERT_HEAD" ] || [ -e "$gd/BISECT_LOG" ]; then
        busy=$((busy+1)); log "SKIP $name: rebase/merge/cherry-pick/revert/bisect in progress"; continue
    fi
    if ! git -C "$dir" merge-base --is-ancestor HEAD "origin/$default" 2>/dev/null; then
        unmerged=$((unmerged+1)); log "SKIP $name: HEAD has commits not in origin/$default"; continue
    fi
    [ "$(git -C "$dir" rev-parse HEAD)" = "$(git -C "$dir" rev-parse "origin/$default")" ] && continue   # already current

    if git -C "$dir" merge --ff-only --quiet "origin/$default" >/dev/null 2>&1; then
        ffwd=$((ffwd+1))
    else
        ffail=$((ffail+1)); log "FF-FAILED $name"
    fi
done

log "SUMMARY fetched $fetched, fast-forwarded $ffwd, skipped dirty $dirty, skipped unmerged $unmerged, fetch failures $fetchfail, skipped in-progress $busy, ff failures $ffail"
