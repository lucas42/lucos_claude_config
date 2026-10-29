#!/bin/bash
# Fixture test for refresh-sandboxes.sh: local bare repos as origin. Run: bash scripts/tests/refresh-sandboxes-fixture-test.sh
# (lucos_agent_coding_sandbox#96). SCRIPT can be overridden to run a sabotaged copy.
set -uo pipefail
SCRIPT="${SCRIPT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/refresh-sandboxes.sh}"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
export GIT_CONFIG_GLOBAL="$W/gitconfig"; : > "$GIT_CONFIG_GLOBAL"
export SANDBOXES_DIR="$W/sandboxes" LOCK_FILE="$W/lock" FETCH_TIMEOUT=10
G="git -c user.name=fixture -c user.email=fixture@example.invalid"
mkdir -p "$SANDBOXES_DIR"
fails=0
check() { if eval "$2"; then echo "ok - $1"; else echo "FAIL - $1"; fails=$((fails+1)); fi; }

# mkrepo <name>: bare origin with one commit, plus a sandbox clone at that commit.
mkrepo() {
    git init -q --bare -b main "$W/$1.git"
    git clone -q "$W/$1.git" "$SANDBOXES_DIR/$1" 2>/dev/null
    (cd "$SANDBOXES_DIR/$1"; echo a > a; git add a; $G commit -qm init; git push -q origin main)
}
# advance <name>: push a new commit to origin via a scratch clone.
advance() {
    git clone -q "$W/$1.git" "$W/scratch-$1" 2>/dev/null
    (cd "$W/scratch-$1"; echo "$2" > "$2"; git add "$2"; $G commit -qm "$2"; git push -q origin main)
    rm -rf "$W/scratch-$1"
}
head_of() { git -C "$SANDBOXES_DIR/$1" rev-parse HEAD; }
origin_main() { git -C "$W/$1.git" rev-parse main; }

for r in clean dirty staged untracked parked unpushed busy fetchfail; do mkrepo $r; done
git -C "$SANDBOXES_DIR/parked" checkout -q -b old-feature          # parked on a merged feature branch
for r in clean dirty staged untracked parked unpushed busy fetchfail; do advance $r new1; done
echo x >> "$SANDBOXES_DIR/dirty/a"
(cd "$SANDBOXES_DIR/staged"; echo s >> a; git add a)
echo u > "$SANDBOXES_DIR/untracked/u"
(cd "$SANDBOXES_DIR/unpushed"; echo p > p; git add p; $G commit -qm local-only)
(cd "$SANDBOXES_DIR/busy"; touch "$(git rev-parse --absolute-git-dir)/MERGE_HEAD")
git -C "$SANDBOXES_DIR/fetchfail" remote set-url origin "$W/does-not-exist.git"
git init -q "$SANDBOXES_DIR/noorigin"; mkdir -p "$SANDBOXES_DIR/.worktrees/x"; mkdir "$SANDBOXES_DIR/notarepo"
unpushed_before=$(head_of unpushed); dirty_before=$(head_of dirty); busy_before=$(head_of busy); ff_before=$(head_of fetchfail)

"$SCRIPT" > "$W/run1.log" 2>&1

check "clean checkout behind origin is fast-forwarded" '[ "$(head_of clean)" = "$(origin_main clean)" ]'
check "untracked-only files do not block the fast-forward" '[ "$(head_of untracked)" = "$(origin_main untracked)" ] && [ -f "$SANDBOXES_DIR/untracked/u" ]'
check "parked merged feature branch is advanced in place (branch not switched)" '[ "$(head_of parked)" = "$(origin_main parked)" ] && [ "$(git -C "$SANDBOXES_DIR/parked" symbolic-ref --short HEAD)" = old-feature ]'
check "modified tracked file: HEAD and edit untouched" '[ "$(head_of dirty)" = "$dirty_before" ] && grep -q x "$SANDBOXES_DIR/dirty/a"'
check "staged change: HEAD and index untouched" '[ "$(head_of staged)" != "$(origin_main staged)" ] && [ -n "$(git -C "$SANDBOXES_DIR/staged" diff --cached --name-only)" ]'
check "unpushed commit: fetched but HEAD not moved" '[ "$(head_of unpushed)" = "$unpushed_before" ] && git -C "$SANDBOXES_DIR/unpushed" rev-parse -q --verify origin/main >/dev/null && [ "$(git -C "$SANDBOXES_DIR/unpushed" rev-parse origin/main)" = "$(origin_main unpushed)" ]'
check "operation in progress (MERGE_HEAD): not moved" '[ "$(head_of busy)" = "$busy_before" ]'
check "unreachable origin: logged, HEAD unchanged, run continued" 'grep -q "FETCH-FAILED fetchfail" "$W/run1.log" && [ "$(head_of fetchfail)" = "$ff_before" ] && grep -q SUMMARY "$W/run1.log"'
check "no-origin repo, .worktrees and non-repo dirs are ignored" '! grep -qE "noorigin|\.worktrees|notarepo" "$W/run1.log"'
check "summary counts are right" 'grep -q "SUMMARY fetched 7, fast-forwarded 3, skipped dirty 2, skipped unmerged 1, fetch failures 1, skipped in-progress 1, ff failures 0" "$W/run1.log"'

# Idempotent: second run changes nothing and logs no fast-forward.
"$SCRIPT" > "$W/run2.log" 2>&1
check "second run fast-forwards nothing" 'grep -q "fast-forwarded 0" "$W/run2.log"'

# Concurrency: a second run while the lock is held exits immediately.
( exec 8>"$LOCK_FILE"; flock -n 8; "$SCRIPT" > "$W/run3.log" 2>&1 )
check "concurrent run exits on the lock" 'grep -q "holds the lock" "$W/run3.log" && ! grep -q SUMMARY "$W/run3.log"'

[ "$fails" -ne 0 ] && sed 's/^/  run1: /' "$W/run1.log"
echo "$fails failure(s)"; [ "$fails" -eq 0 ]
