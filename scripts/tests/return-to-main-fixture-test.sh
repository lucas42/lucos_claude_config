#!/bin/bash
# return-to-main-fixture-test.sh
#
# Exercises scripts/return-to-main.sh end-to-end against a disposable
# fixture — never the live ~/.claude checkout. This repo has no CI, so this
# is a script a reviewer runs by hand before/after touching
# return-to-main.sh, not an automatic gate. See lucas42/lucos_claude_config#147.
#
# Builds a throwaway local git repo standing in for the shared checkout,
# plus a bare repo standing in for origin, and points return-to-main.sh's
# two parameterised overrides at them:
#   - CLAUDE_DIR         -> the fixture checkout, never the real one
#   - LOGANNE_EVENT_SCRIPT -> a no-op stub that appends to a local log file
#     instead of posting to the live https://loganne.l42.eu/events. Without
#     this, deliberately exercising the alerting path (job 3 / job 2c) would
#     fire a real production event with a fabricated message.
#
# Quiescence-window timestamps (DIRTY_QUIESCENCE_SECONDS / STALL_SECONDS in
# the script under test) are pre-seeded directly into the fixture's state
# files / file mtimes, so nothing here has to actually wait 20 minutes.
#
# Usage: scripts/tests/return-to-main-fixture-test.sh  (run from anywhere)

set -uo pipefail  # not -e: keep running through failures and report a tally

SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../.." && pwd)/scripts/return-to-main.sh"

PASS=0
FAIL=0

pass() { echo "  PASS  $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL  $1"; FAIL=$((FAIL + 1)); }

# --- Fixture scaffolding -------------------------------------------------

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

BARE_ORIGIN="$WORKDIR/origin.git"
export CLAUDE_DIR="$WORKDIR/claude-checkout"
LOGANNE_LOG="$WORKDIR/loganne-events.log"
LOGANNE_STUB="$WORKDIR/loganne-event-stub"
SECOND_CLONE="$WORKDIR/second-clone"

GIT_AUTHOR="-c user.name=fixture -c user.email=fixture@example.invalid"

git init --bare -q "$BARE_ORIGIN"

git init -q -b main "$CLAUDE_DIR"
(
    cd "$CLAUDE_DIR"
    mkdir -p scripts
    echo "one" > file-a.txt
    git $GIT_AUTHOR add file-a.txt
    git $GIT_AUTHOR commit -q -m "initial"
    git remote add origin "$BARE_ORIGIN"
    git push -q origin main
)

cat > "$LOGANNE_STUB" <<'STUB_EOF'
#!/bin/bash
echo "$1|$2" >> "$LOGANNE_LOG_PATH"
STUB_EOF
chmod +x "$LOGANNE_STUB"
export LOGANNE_EVENT_SCRIPT="$LOGANNE_STUB"
export LOGANNE_LOG_PATH="$LOGANNE_LOG"

git clone -q "$BARE_ORIGIN" "$SECOND_CLONE"

run_script() {
    "$SCRIPT_UNDER_TEST" > "$WORKDIR/last-run.log" 2>&1
}

reset_loganne_log() { : > "$LOGANNE_LOG"; }

echo "return-to-main.sh fixture tests"
echo "--------------------------------"

# === Job 1: branch-switching ===============================================

# --- 1a. Freshly-branched, no commits (guard #117): stays put -------------
(
    cd "$CLAUDE_DIR"
    git checkout -q main
    git checkout -q -b feature-fresh
)
run_script
branch_after=$(git -C "$CLAUDE_DIR" rev-parse --abbrev-ref HEAD)
if [[ "$branch_after" == "feature-fresh" ]]; then
    pass "job1: freshly-branched (no commits) stays on the branch"
else
    fail "job1: freshly-branched (no commits) — expected feature-fresh, got $branch_after"
fi

# --- 1b. Unmerged branch with real commits: stays put ----------------------
(
    cd "$CLAUDE_DIR"
    echo "unmerged work" >> file-a.txt
    git $GIT_AUTHOR commit -q -am "unmerged commit"
)
run_script
branch_after=$(git -C "$CLAUDE_DIR" rev-parse --abbrev-ref HEAD)
if [[ "$branch_after" == "feature-fresh" ]]; then
    pass "job1: unmerged branch stays on the branch"
else
    fail "job1: unmerged branch — expected feature-fresh, got $branch_after"
fi

# --- 1c. Merged branch: switches back to main, deletes the branch ---------
(
    cd "$CLAUDE_DIR"
    git checkout -q main
    git merge -q --no-ff feature-fresh -m "merge feature-fresh"
    git push -q origin main
    git checkout -q feature-fresh
)
run_script
branch_after=$(git -C "$CLAUDE_DIR" rev-parse --abbrev-ref HEAD)
branch_gone=$(git -C "$CLAUDE_DIR" branch --list feature-fresh)
if [[ "$branch_after" == "main" && -z "$branch_gone" ]]; then
    pass "job1: merged branch switches back to main and is deleted"
else
    fail "job1: merged branch — branch=$branch_after, still-exists=${branch_gone:-no}"
fi

echo "--------------------------------"
echo "Results so far: $PASS passed, $FAIL failed"

# === Job 2 / 2b: sync + materialize_pr_content =============================

# --- 2a. " D": PR-added file lands on disk (untouched locally) ------------
(
    cd "$SECOND_CLONE"
    git pull -q origin main
    echo "brand new file from a merged PR" > new-file.txt
    git $GIT_AUTHOR add new-file.txt
    git $GIT_AUTHOR commit -q -m "add new-file.txt"
    git push -q origin main
)
run_script
if [[ -f "$CLAUDE_DIR/new-file.txt" ]] && grep -q "brand new file from a merged PR" "$CLAUDE_DIR/new-file.txt"; then
    pass "job2b: PR-added file (\" D\") materialised onto disk"
else
    fail "job2b: PR-added file (\" D\") not materialised (see $WORKDIR/last-run.log)"
fi

# --- 2b. " M": PR-modified, untouched-locally file is overwritten ---------
(
    cd "$SECOND_CLONE"
    git pull -q origin main
    echo "remote-edit-1" > file-a.txt
    git $GIT_AUTHOR commit -q -am "modify file-a.txt (remote-edit-1)"
    git push -q origin main
)
run_script
content=$(cat "$CLAUDE_DIR/file-a.txt" 2>/dev/null || echo "<missing>")
if [[ "$content" == "remote-edit-1" ]]; then
    pass "job2b: PR-modified file (\" M\", untouched locally) materialised"
else
    fail "job2b: PR-modified file — expected 'remote-edit-1', got '$content'"
fi

# --- 2c. " M": a genuine local edit is left alone, never overwritten ------
(
    cd "$SECOND_CLONE"
    git pull -q origin main
    echo "remote-edit-2" > file-a.txt
    git $GIT_AUTHOR commit -q -am "modify file-a.txt (remote-edit-2)"
    git push -q origin main
)
echo "local-edit-should-survive" > "$CLAUDE_DIR/file-a.txt"
run_script
content=$(cat "$CLAUDE_DIR/file-a.txt" 2>/dev/null || echo "<missing>")
if [[ "$content" == "local-edit-should-survive" ]]; then
    pass "job2b: genuine local edit left alone (not overwritten by PR content)"
else
    fail "job2b: local edit was overwritten — expected 'local-edit-should-survive', got '$content'"
fi

echo "--------------------------------"
echo "Results so far: $PASS passed, $FAIL failed"

# === Job 3: persistent-dirt detection/clearing ==============================

# Builds on the local edit left dirty by the last job2c test above.
DIRTY_STATE_FILE="$CLAUDE_DIR/scripts/.return-to-main-dirty-since"
DIRTY_ALERTED_FILE="$CLAUDE_DIR/scripts/.return-to-main-dirty-alerted"

# --- 3a. Streak pre-seeded past the quiescence window: alert fires --------
now=$(date +%s)
echo $((now - 1300)) > "$DIRTY_STATE_FILE"          # window is 1200s
touch -d "@$((now - 400))" "$CLAUDE_DIR/file-a.txt"  # stall is 300s
reset_loganne_log
run_script
if [[ -f "$DIRTY_ALERTED_FILE" ]] && grep -q "^persistentDirtDetected|" "$LOGANNE_LOG" \
   && grep -q "forgotten local edit" "$LOGANNE_LOG"; then
    pass "job3: persistentDirtDetected fires with 'forgotten local edit' attribution"
else
    fail "job3: persistentDirtDetected did not fire as expected (log: $(cat "$LOGANNE_LOG" 2>/dev/null))"
fi

# --- 3b. Same streak, second run: does not re-fire (edge-triggered) -------
reset_loganne_log
run_script
if [[ ! -s "$LOGANNE_LOG" ]]; then
    pass "job3: persistentDirtDetected does not re-fire on an unchanged streak"
else
    fail "job3: persistentDirtDetected re-fired unexpectedly (log: $(cat "$LOGANNE_LOG"))"
fi

# --- 3c. Dirt cleared: persistentDirtCleared fires, markers removed -------
echo "remote-edit-2" > "$CLAUDE_DIR/file-a.txt"  # matches index again -> clean
reset_loganne_log
run_script
if grep -q "^persistentDirtCleared|" "$LOGANNE_LOG" \
   && [[ ! -f "$DIRTY_ALERTED_FILE" && ! -f "$DIRTY_STATE_FILE" ]]; then
    pass "job3: persistentDirtCleared fires once the tree is clean again, markers removed"
else
    fail "job3: persistentDirtCleared did not fire/clean up as expected (log: $(cat "$LOGANNE_LOG" 2>/dev/null))"
fi

echo "--------------------------------"
echo "Results so far: $PASS passed, $FAIL failed"

# === Job 2c: sync-failure tracking ==========================================

SYNC_FAIL_STATE_FILE="$CLAUDE_DIR/scripts/.return-to-main-syncfail-since"
SYNC_FAIL_ALERTED_FILE="$CLAUDE_DIR/scripts/.return-to-main-syncfail-alerted"

# --- 2c-a. Sync pre-seeded as failing past the window: alert fires --------
BAD_ORIGIN="$WORKDIR/does-not-exist.git"
GOOD_ORIGIN=$(git -C "$CLAUDE_DIR" remote get-url origin)
git -C "$CLAUDE_DIR" remote set-url origin "$BAD_ORIGIN"

now=$(date +%s)
echo $((now - 1300)) > "$SYNC_FAIL_STATE_FILE"
reset_loganne_log
run_script
if [[ -f "$SYNC_FAIL_ALERTED_FILE" ]] && grep -q "^syncFailurePersisted|" "$LOGANNE_LOG"; then
    pass "job2c: syncFailurePersisted fires once a failing sync outlives the window"
else
    fail "job2c: syncFailurePersisted did not fire as expected (log: $(cat "$LOGANNE_LOG" 2>/dev/null))"
fi

# --- 2c-b. Sync recovers: syncFailureRecovered fires, markers removed -----
git -C "$CLAUDE_DIR" remote set-url origin "$GOOD_ORIGIN"
reset_loganne_log
run_script
if grep -q "^syncFailureRecovered|" "$LOGANNE_LOG" \
   && [[ ! -f "$SYNC_FAIL_ALERTED_FILE" && ! -f "$SYNC_FAIL_STATE_FILE" ]]; then
    pass "job2c: syncFailureRecovered fires once the sync succeeds again, markers removed"
else
    fail "job2c: syncFailureRecovered did not fire/clean up as expected (log: $(cat "$LOGANNE_LOG" 2>/dev/null))"
fi

echo "--------------------------------"
echo "Results: $PASS passed, $FAIL failed"

[[ "$FAIL" -eq 0 ]]
