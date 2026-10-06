#!/bin/bash
# prune-worktrees.sh — remove per-issue worktrees under ~/sandboxes/.worktrees whose
# work has landed. Runs daily from cron. lucos_claude_config#159.
#
# A worktree is removed only if ALL hold; any failure means "keep and report":
#   1. valid   — it is a working git worktree (else reported as broken, never deleted)
#   2. clean   — no staged, unstaged or untracked changes
#   3. landed  — HEAD is an ancestor of freshly-fetched origin/main, OR its branch's PR
#                is merged/closed and HEAD equals that PR's head SHA (squash/rebase
#                merges; equality also proves nothing is unpushed)
#   4. quiet   — newest file mtime older than QUIESCENCE_SECS (default 48h), so a
#                just-created worktree whose HEAD still equals origin/main isn't taken
#
# An entry failing the checks for >= ALERT_AFTER_SECS (default 7 days) raises ONE
# Loganne "staleWorktreeNeedsReview" event. Usage: prune-worktrees.sh [--dry-run]

set -uo pipefail

WORKTREES_DIR="${WORKTREES_DIR:-$HOME/sandboxes/.worktrees}"
STATE_DIR="${STATE_DIR:-$HOME/.claude/scripts/.prune-worktrees-state}"
QUIESCENCE_SECS="${QUIESCENCE_SECS:-172800}"
ALERT_AFTER_SECS="${ALERT_AFTER_SECS:-604800}"
LOGANNE_EVENT_SCRIPT="${LOGANNE_EVENT_SCRIPT:-$HOME/sandboxes/lucos_agent/loganne-event}"
# Prints "<merged:true|false> <state> <head_sha>" for a repo+branch, or nothing if no PR.
PR_LOOKUP_CMD="${PR_LOOKUP_CMD:-pr_lookup_gh}"
DRY_RUN=0; [ "${1:-}" = "--dry-run" ] && DRY_RUN=1

export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519_lucos_agent -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

pr_lookup_gh() {
    local repo="$1" branch="$2" enc
    enc=$(jq -rn --arg b "$branch" '$b|@uri')
    "$HOME/sandboxes/lucos_agent/gh-as-agent" --app lucos-system-administrator \
        "repos/lucas42/$repo/pulls?head=lucas42:$enc&state=all&per_page=1" \
        --jq '.[0] | select(. != null) | "\(.merged_at != null) \(.state) \(.head.sha)"' 2>/dev/null
}

emit_loganne_event() {   # best-effort: must never break the prune itself
    [ -x "$LOGANNE_EVENT_SCRIPT" ] && { "$LOGANNE_EVENT_SCRIPT" "$1" "$2" >/dev/null 2>&1 || \
        echo "$(date -Iseconds) WARNING: could not emit Loganne event '$1'." >&2; }
    return 0
}

mkdir -p "$STATE_DIR"
now=$(date +%s)
declare -A fetched          # repo dir -> ok|failed (one fetch per repo per run)
declare -A touched          # repo dirs needing `worktree prune`
removed=0; not_landed=0; dirty=0; recent=0; broken=0; fetchfail=0
seen=()

# keep <name> <reason>: record the failure, alert once it has persisted.
keep() {
    local name="$1" reason="$2" first
    echo "$(date -Iseconds) KEEP $name: $reason"
    seen+=("$name")
    [ "$DRY_RUN" -eq 1 ] && return 0   # dry-run must not write state or emit events
    [ -f "$STATE_DIR/$name.first" ] || echo "$now" > "$STATE_DIR/$name.first"
    first=$(cat "$STATE_DIR/$name.first")
    if [ $((now - first)) -ge "$ALERT_AFTER_SECS" ] && [ ! -f "$STATE_DIR/$name.alerted" ]; then
        emit_loganne_event "staleWorktreeNeedsReview" \
            "Worktree $name has been kept for over $((ALERT_AFTER_SECS / 86400)) days and needs a human look: $reason"
        touch "$STATE_DIR/$name.alerted"
    fi
}

newest_mtime() {   # newest file mtime in a worktree, ignoring dependency/vcs dirs; epoch seconds
    local wt="$1" gd="$2"
    { find "$wt" \( -name .git -o -name node_modules \) -prune -o -type f -printf '%T@\n' 2>/dev/null
      stat -c %Y "$gd/HEAD" "$gd/index" "$gd/logs/HEAD" 2>/dev/null; } | sort -n | tail -1 | cut -d. -f1
}

for wt in "$WORKTREES_DIR"/*/; do
    wt="${wt%/}"; [ -d "$wt" ] || continue
    name=$(basename "$wt")

    # 1. valid
    if ! gd=$(git -C "$wt" rev-parse --absolute-git-dir 2>/dev/null); then
        broken=$((broken+1)); keep "$name" "not a usable git worktree (broken or missing gitdir)"; continue
    fi
    common=$(git -C "$wt" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    repo_dir="${common%/.git}"; repo_name=$(basename "$repo_dir")

    # 2. clean
    if [ -n "$(git --no-optional-locks -C "$wt" status --porcelain --untracked-files=all 2>/dev/null)" ]; then
        dirty=$((dirty+1)); keep "$name" "uncommitted or untracked changes"; continue
    fi

    # 3. landed (needs fresh refs; if the fetch fails we cannot judge, so keep)
    if [ -z "${fetched[$repo_dir]:-}" ]; then
        if git -C "$repo_dir" fetch -q origin 2>/dev/null; then fetched[$repo_dir]=ok; else fetched[$repo_dir]=failed; fi
    fi
    if [ "${fetched[$repo_dir]}" = failed ]; then
        fetchfail=$((fetchfail+1)); keep "$name" "could not fetch origin for $repo_name; unable to judge"; continue
    fi
    head=$(git -C "$wt" rev-parse HEAD); branch=$(git -C "$wt" symbolic-ref --short -q HEAD || true)
    landed=""
    if git -C "$wt" merge-base --is-ancestor HEAD origin/main 2>/dev/null; then
        landed=ancestor
    elif [ -n "$branch" ]; then
        read -r merged state pr_head <<<"$($PR_LOOKUP_CMD "$repo_name" "$branch")"
        if [ -n "${pr_head:-}" ] && { [ "$merged" = true ] || [ "$state" = closed ]; } && [ "$pr_head" = "$head" ]; then
            landed=pr
        fi
    fi
    if [ -z "$landed" ]; then
        not_landed=$((not_landed+1)); keep "$name" "work not landed (not on origin/main, no merged/closed PR at this HEAD)"; continue
    fi

    # 4. quiescent
    newest=$(newest_mtime "$wt" "$gd")
    if [ -z "$newest" ] || [ $((now - newest)) -lt "$QUIESCENCE_SECS" ]; then   # unknown mtime keeps it
        recent=$((recent+1)); keep "$name" "landed but modified within the last $((QUIESCENCE_SECS / 3600))h"; continue
    fi

    # remove
    if [ "$DRY_RUN" -eq 1 ]; then echo "$(date -Iseconds) WOULD REMOVE $name (landed via $landed)"; removed=$((removed+1)); continue; fi
    if git -C "$repo_dir" worktree remove "$wt" 2>/dev/null; then
        echo "$(date -Iseconds) REMOVED $name (landed via $landed)"
        removed=$((removed+1)); touched[$repo_dir]=1
        # -d refuses an unmerged branch, so this is a second safety net.
        [ "$landed" = ancestor ] && [ -n "$branch" ] && git -C "$repo_dir" branch -d "$branch" >/dev/null 2>&1
        rm -f "$STATE_DIR/$name.first" "$STATE_DIR/$name.alerted"
    else
        keep "$name" "git worktree remove refused"
    fi
done

[ "$DRY_RUN" -eq 0 ] && for r in "${!touched[@]}"; do git -C "$r" worktree prune 2>/dev/null; done

# Drop state for entries that are gone or no longer failing.
[ "$DRY_RUN" -eq 0 ] && for f in "$STATE_DIR"/*.first; do
    [ -e "$f" ] || continue; n=$(basename "$f" .first)
    case " ${seen[*]:-} " in *" $n "*) ;; *) rm -f "$f" "$STATE_DIR/$n.alerted";; esac
done

echo "$(date -Iseconds) SUMMARY removed=$removed not-landed=$not_landed dirty=$dirty recent=$recent broken=$broken fetch-failed=$fetchfail dry-run=$DRY_RUN"
