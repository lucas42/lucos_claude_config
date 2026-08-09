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
#   commit-agent-memory.sh                  # sweep/cron mode: per-persona commits, all agent-memory/ + projects/
#   commit-agent-memory.sh --app <persona>  # persona mode: persona's bot, only agent-memory/<persona>/
#
# In sweep mode (no args) this iterates every agent-memory/<persona>/ subdirectory
# that has pending changes and commits+pushes EACH ONE SEPARATELY under that
# persona's own bot identity — never under a single catch-all identity. This
# matters: an earlier version did one giant commit spanning every persona's
# subtree, attributed to lucos-system-administrator[bot] regardless of whose
# files were actually dirty. That meant the sweep — which fires after every
# turn via the Stop hook, not just every 15 minutes via cron — could (and did:
# lucas42/lucos_claude_config, 2026-08-09, flagged by lucos-architect) grab
# another persona's in-flight, not-yet-committed memory edit mid-write, commit
# it under the wrong bot identity with a generic message, and silently discard
# whatever rationale that persona had written into their own intended commit
# message. Nothing failed and nothing alerted — the file landed correctly, just
# under the wrong name and with the reasoning gone. Per-persona scoping in sweep
# mode makes that structurally impossible: the sweep can now only ever commit a
# persona's own subtree under that persona's own identity, exactly like calling
# `--app <persona>` directly would. `projects/` (dispatcher auto-memory) has no
# single-persona owner, so it stays on the sysadmin catch-all identity — that
# part of the cross-attribution risk doesn't apply there.
#
# In persona mode (--app <persona>) the commit is attributed to that persona's bot
# identity (looked up from ~/sandboxes/lucos_agent/personas.json) and is scoped
# exclusively to agent-memory/<persona>/.  Use this when committing from within a
# persona session so that memory history preserves per-agent attribution.
#
# Called primarily from post-turn-hook.sh (Claude Code Stop hook), which fires after
# every turn (in sweep mode).  Also called from a 15-minute cron as a fallback:
#   */15 * * * * /home/lucas.linux/.claude/scripts/commit-agent-memory.sh >> /home/lucas.linux/.claude/scripts/commit-agent-memory.log 2>&1

set -uo pipefail

CLAUDE_DIR="/home/lucas.linux/.claude"
PERSONAS_JSON="/home/lucas.linux/sandboxes/lucos_agent/personas.json"

# Sysadmin identity — used for persona-mode when --app is sysadmin, and for the
# projects/ (dispatcher memory) slice in sweep mode, which has no single-persona
# owner to attribute to instead.
SYSADMIN_NAME="lucos-system-administrator[bot]"
SYSADMIN_EMAIL="264392982+lucos-system-administrator[bot]@users.noreply.github.com"

# Quiescence window for sweep mode only (seconds). A persona directory with
# any file modified more recently than this is skipped for this cycle rather
# than committed immediately.
#
# Why: post-turn-hook.sh's Stop hook runs sweep mode after every single turn,
# for every session. The documented agent workflow is "write a memory file,
# then commit it" — necessarily two different turns — so without this window
# the hook races that workflow on every memory write, not just occasionally.
# lucos-architect hit exactly this (2026-08-09): their own commit-claude-main
# call lost the race to a sweep that fired in the gap between their edit and
# their own commit, and — even after the per-persona attribution fix above —
# the sweep would still have committed their file under their own identity
# with the generic "Auto-commit agent memory updates" message, discarding the
# rationale they'd written into their intended commit message. Skipping
# recently-modified directories lets a persona's own deliberate commit land
# first in the common case, while still catching genuinely-forgotten files
# once they've been quiet for a while — the 15-minute cron re-checks on every
# tick regardless, so nothing is ever silently missed forever, just delayed.
# Tracked in lucas42/lucos_claude_config (cross-referenced against #124, a
# different symptom of the same underlying "the sweep stages things it
# doesn't own" root cause — that one's about partial/atomic-write races, not
# attribution).
QUIESCENCE_SECONDS=300

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

# Look up a persona's bot identity from personas.json.
# Prints "$bot_name\t$bot_email" on success, or exits 1 with nothing on stdout
# if the persona is unknown.
lookup_identity() {
    local persona="$1"
    local bot_info
    bot_info=$(python3 - "$persona" "$PERSONAS_JSON" <<'EOF'
import json, sys
app, path = sys.argv[1], sys.argv[2]
d = json.load(open(path))
p = d.get(app)
if not p:
    sys.exit(1)
print(p["bot_name"], p["bot_user_id"], sep="\t")
EOF
    ) || return 1
    local name email user_id
    name=$(echo "$bot_info" | cut -f1)
    user_id=$(echo "$bot_info" | cut -f2)
    email="${user_id}+${name}@users.noreply.github.com"
    printf '%s\t%s\n' "$name" "$email"
}

# Ensure git uses the correct SSH key, even in cron's minimal environment.
export GIT_SSH_COMMAND="ssh -i /home/lucas.linux/.ssh/id_ed25519_lucos_agent -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

# is_recently_modified <path> <window_seconds>
#
# True (exit 0) if any modified-or-untracked file under <path> (relative to
# origin/main, evaluated from $CLAUDE_DIR) has an mtime within the last
# <window_seconds>. Used only by sweep mode's quiescence check — persona mode
# always commits immediately regardless, since that's an explicit, deliberate
# call by the persona itself.
is_recently_modified() {
    local path="$1" window="$2"
    local now cutoff f mtime
    now=$(date +%s)
    cutoff=$((now - window))
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        [ -f "$CLAUDE_DIR/$f" ] || continue
        mtime=$(stat -c %Y "$CLAUDE_DIR/$f" 2>/dev/null) || continue
        if [ "$mtime" -gt "$cutoff" ]; then
            return 0
        fi
    done < <(cd "$CLAUDE_DIR" && { git diff --name-only origin/main -- "$path"; git ls-files --others --exclude-standard -- "$path"; } | sort -u)
    return 1
}

# commit_scope <identity_name> <identity_email> <check_path...>
#
# Commits and pushes any pending changes under the given path(s) to origin/main,
# attributed to the given identity, via an isolated temporary worktree. Returns
# 0 whether or not there was anything to do; only exits non-zero on an actual
# failure (conflict markers found, rebase conflict, push exhausted retries).
commit_scope() {
    local identity_name="$1" identity_email="$2"
    shift 2
    local check_paths=("$@")

    cd "$CLAUDE_DIR" || return 1
    git fetch --quiet origin main

    local changes_exist=0
    local path
    for path in "${check_paths[@]}"; do
        if ! git diff --quiet origin/main -- "$path" || \
           ! git diff --quiet --cached -- "$path" || \
           [ -n "$(git ls-files --others --exclude-standard -- "$path")" ]; then
            changes_exist=1
            break
        fi
    done

    if [ "$changes_exist" -eq 0 ]; then
        echo "$(date -Iseconds) [$identity_name] No changes in ${check_paths[*]} vs origin/main — nothing to do."
        return 0
    fi

    echo "$(date -Iseconds) [$identity_name] Changes detected vs origin/main — committing via temporary worktree."

    local worktree_dir
    worktree_dir=$(mktemp -d)
    git worktree add --quiet "$worktree_dir" origin/main

    for path in "${check_paths[@]}"; do
        mkdir -p "$worktree_dir/$path"
        cp -rT "$CLAUDE_DIR/$path" "$worktree_dir/$path"
    done

    # Do the risky, multi-step part (stage/verify/commit/push-with-retry) in a
    # subshell rather than returning early from this function directly. This
    # keeps worktree cleanup unconditional and in one place below, regardless
    # of which exit path the subshell takes — no reliance on a RETURN trap,
    # which would otherwise need re-arming per loop iteration when this
    # function is called once per persona in sweep mode and is easy to get
    # subtly wrong (a lingering trap firing on an unrelated function's return,
    # or referencing a `worktree_dir` from a previous iteration).
    (
        cd "$worktree_dir" || exit 1
        git add "${check_paths[@]}"

        # Safety guard: refuse to commit any file containing git conflict markers.
        conflict_files=$(git grep -l --cached "^<<<<<<< " -- "${check_paths[@]}" 2>/dev/null || true)
        if [ -n "$conflict_files" ]; then
            echo "$(date -Iseconds) [$identity_name] ERROR: Conflict markers found in staged files — aborting commit. Resolve conflicts manually then re-run:"
            echo "$conflict_files"
            exit 1
        fi

        if git diff --quiet --cached -- "${check_paths[@]}"; then
            echo "$(date -Iseconds) [$identity_name] Nothing to commit after sync — worktree already matches working tree."
            exit 0
        fi

        git \
            -c user.name="$identity_name" \
            -c user.email="$identity_email" \
            commit -m "Auto-commit agent memory updates"

        echo "$(date -Iseconds) [$identity_name] Committed. Pushing to main..."

        max_push_retries=3
        push_attempt=0
        until git push origin HEAD:main; do
            push_attempt=$((push_attempt + 1))
            if [ "$push_attempt" -ge "$max_push_retries" ]; then
                echo "$(date -Iseconds) [$identity_name] ERROR: Push to main failed after $max_push_retries attempts — giving up." >&2
                exit 1
            fi
            echo "$(date -Iseconds) [$identity_name] Push rejected (non-fast-forward); re-fetching origin/main and rebasing (attempt $push_attempt of $max_push_retries)..."
            git fetch origin main
            git rebase origin/main || {
                git rebase --abort 2>/dev/null || true
                echo "$(date -Iseconds) [$identity_name] ERROR: Rebase failed — unexpected conflict during retry. Aborting." >&2
                exit 1
            }
        done

        echo "$(date -Iseconds) [$identity_name] Push complete."
        exit 0
    )
    local rv=$?

    # Unconditional cleanup, back in $CLAUDE_DIR, regardless of the subshell's
    # exit path above.
    cd "$CLAUDE_DIR" || true
    git worktree remove --force "$worktree_dir" 2>/dev/null || true

    return "$rv"
}

overall_status=0

if [[ -n "$APP" ]]; then
    # Persona mode: exactly one scope, that persona's own subtree and identity.
    identity=$(lookup_identity "$APP") || {
        echo "$(date -Iseconds) ERROR: Unknown persona '$APP' — not found in personas.json." >&2
        exit 1
    }
    name=$(echo "$identity" | cut -f1)
    email=$(echo "$identity" | cut -f2)
    commit_scope "$name" "$email" "agent-memory/$APP/" || overall_status=1
else
    # Sweep mode: one scope PER persona directory that actually has pending
    # changes, each committed under that persona's own identity — never a
    # single cross-persona commit. See the header comment for why this matters.
    if [ -d "$CLAUDE_DIR/agent-memory" ]; then
        for dir in "$CLAUDE_DIR"/agent-memory/*/; do
            [ -d "$dir" ] || continue
            persona=$(basename "$dir")
            identity=$(lookup_identity "$persona") || {
                echo "$(date -Iseconds) WARNING: agent-memory/$persona/ has no matching entry in personas.json — skipping (falls to next cron/hook run, not silently attributed to sysadmin)." >&2
                overall_status=1
                continue
            }

            if is_recently_modified "agent-memory/$persona/" "$QUIESCENCE_SECONDS"; then
                echo "$(date -Iseconds) [$persona] Skipping this cycle — files modified within the last ${QUIESCENCE_SECONDS}s (quiescence window; will retry next run)."
                continue
            fi

            name=$(echo "$identity" | cut -f1)
            email=$(echo "$identity" | cut -f2)
            commit_scope "$name" "$email" "agent-memory/$persona/" || overall_status=1
        done
    fi

    # projects/ (dispatcher auto-memory) has no single-persona owner — keep it
    # on the sysadmin catch-all identity.
    if [ -d "$CLAUDE_DIR/projects" ]; then
        commit_scope "$SYSADMIN_NAME" "$SYSADMIN_EMAIL" "projects/" || overall_status=1
    fi
fi

exit "$overall_status"
