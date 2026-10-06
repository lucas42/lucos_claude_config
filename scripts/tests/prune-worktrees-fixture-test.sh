#!/bin/bash
# Fixture test for prune-worktrees.sh: synthetic repo + worktrees, stubbed PR lookup and Loganne.
# Run: bash scripts/tests/prune-worktrees-fixture-test.sh   (lucos_claude_config#159)
set -uo pipefail
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/prune-worktrees.sh"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
export GIT_CONFIG_GLOBAL="$W/gitconfig"; : > "$GIT_CONFIG_GLOBAL"
export WORKTREES_DIR="$W/wts" STATE_DIR="$W/state" LOGANNE_EVENT_SCRIPT="$W/loganne-stub" PR_LOOKUP_CMD="$W/pr-stub"
G="git -c user.name=fixture -c user.email=fixture@example.invalid"
mkdir -p "$WORKTREES_DIR"
printf '#!/bin/bash\necho "$1 $2" >> %s\n' "$W/events.log" > "$LOGANNE_EVENT_SCRIPT"; chmod +x "$LOGANNE_EVENT_SCRIPT"
# PR stub: prints the matching line's value from pr-map ("<repo> <branch> <output>").
printf '#!/bin/bash\ngrep "^$1 $2 " %s | cut -d" " -f3-\n' "$W/pr-map" > "$PR_LOOKUP_CMD"; chmod +x "$PR_LOOKUP_CMD"; : > "$W/pr-map"

git init -q --bare "$W/origin.git"; git init -q -b main "$W/repo"; cd "$W/repo"
echo a > a; git add a; $G commit -qm init; git remote add origin "$W/origin.git"; git push -q origin main
git init -q --bare "$W/origin2.git"; git init -q -b main "$W/other"
(cd "$W/other"; echo a > a; git add a; $G commit -qm init; git remote add origin "$W/origin2.git"; git push -q origin main)

mk() { git -C "$W/repo" worktree add -q "$WORKTREES_DIR/$1" -b "$1" origin/main; }
age() { local gd; gd=$(git -C "$WORKTREES_DIR/$1" rev-parse --absolute-git-dir); find "$WORKTREES_DIR/$1" "$gd" -exec touch -d '5 days ago' {} + ; }
commit_in() { (cd "$WORKTREES_DIR/$1"; echo "$2" > "$2"; git add "$2"; $G commit -qm "$2"); }

mk merged; commit_in merged m; git -C "$WORKTREES_DIR/merged" push -q origin merged:main; git -C "$W/repo" fetch -q; age merged
mk dirty; echo x >> "$WORKTREES_DIR/dirty/a"; age dirty
mk staged; (cd "$WORKTREES_DIR/staged"; echo s > s; git add s); age staged
mk untracked; echo u > "$WORKTREES_DIR/untracked/u"; age untracked
mk unpushed; commit_in unpushed u1; age unpushed
mk fresh                                          # HEAD == origin/main, just created
mk squashed; commit_in squashed q; age squashed
echo "repo squashed true closed $(git -C "$WORKTREES_DIR/squashed" rev-parse HEAD)" >> "$W/pr-map"
mk lateedit; commit_in lateedit l; age lateedit
echo "repo lateedit true closed 0000000000000000000000000000000000000000" >> "$W/pr-map"
mkdir "$WORKTREES_DIR/broken"; echo "gitdir: $W/repo/.git/worktrees/gone" > "$WORKTREES_DIR/broken/.git"; age broken 2>/dev/null
git -C "$W/other" worktree add -q "$WORKTREES_DIR/nofetch" -b nofetch origin/main; age nofetch
git -C "$W/other" remote set-url origin "$W/does-not-exist.git"

fails=0
expect() { # <name> <present|absent> <description>
    local here=absent; [ -d "$WORKTREES_DIR/$1" ] && here=present
    if [ "$here" = "$2" ]; then echo "ok - $3"; else echo "FAIL - $3"; fails=$((fails+1)); fi
}

mkdir -p "$STATE_DIR"; echo 1 > "$STATE_DIR/dirty.first"; echo 1 > "$STATE_DIR/ghost.first"   # ghost = entry that no longer exists
before=$(cd "$STATE_DIR" && ls -la --time-style=full-iso . && cat *.first)
out=$("$SCRIPT" --dry-run 2>&1);
after=$(cd "$STATE_DIR" && ls -la --time-style=full-iso . && cat *.first)
[ "$before" = "$after" ] && [ ! -s "$W/events.log" ] && echo "ok - dry-run leaves state dir and Loganne untouched" || { echo "FAIL - dry-run had side effects"; fails=$((fails+1)); }
rm -f "$STATE_DIR/dirty.first" "$STATE_DIR/ghost.first"
 grep -q 'WOULD REMOVE merged' <<<"$out" && [ -d "$WORKTREES_DIR/merged" ] && echo "ok - dry-run removes nothing" || { echo "FAIL - dry-run"; fails=$((fails+1)); }

"$SCRIPT" > "$W/run1.log" 2>&1
expect merged absent    "merged + clean + old is removed"
expect squashed absent  "squash-merged (PR merged, HEAD == PR head) is removed"
expect dirty present    "modified tracked file is kept"
expect staged present   "staged-only change is kept"
expect untracked present "untracked file is kept"
expect unpushed present "unpushed commit with no PR is kept"
expect lateedit present "PR merged but HEAD differs from PR head is kept"
expect fresh present    "brand-new worktree (HEAD == origin/main) is kept by the quiescence guard"
expect broken present   "broken gitdir is reported, never deleted"
expect nofetch present  "worktree of a repo whose fetch fails is kept"
git -C "$W/repo" branch --list merged | grep -q . && { echo "FAIL - merged branch not deleted"; fails=$((fails+1)); } || echo "ok - merged branch deleted"

# Unknown mtime must keep the worktree: shadow find/stat so newest_mtime returns nothing.
mk nomtime; commit_in nomtime n1; git -C "$WORKTREES_DIR/nomtime" push -q origin nomtime:main; git -C "$W/repo" fetch -q; age nomtime
mkdir "$W/nobin"; printf '#!/bin/bash\nexit 0\n' > "$W/nobin/find"; cp "$W/nobin/find" "$W/nobin/stat"; chmod +x "$W/nobin/find" "$W/nobin/stat"
PATH="$W/nobin:$PATH" "$SCRIPT" >/dev/null 2>&1
expect nomtime present "unknown newest-mtime keeps an otherwise-landed worktree"
"$SCRIPT" >/dev/null 2>&1
expect nomtime absent  "...and it is removed once the mtime is readable again"

# Alerting: nothing yet; backdate one marker past the threshold; expect exactly one event across two runs.
[ ! -s "$W/events.log" ] && echo "ok - no Loganne event before the threshold" || { echo "FAIL - early event"; fails=$((fails+1)); }
touch -d '8 days ago' "$STATE_DIR/dirty.first"; echo 1 > "$STATE_DIR/dirty.first"   # epoch 1 = long ago
"$SCRIPT" >/dev/null 2>&1; "$SCRIPT" >/dev/null 2>&1
n=$(grep -c 'staleWorktreeNeedsReview.*dirty' "$W/events.log" 2>/dev/null); [ "$n" = 1 ] && echo "ok - one alert for a long-stuck entry across two runs" || { echo "FAIL - alert count $n"; fails=$((fails+1)); }
# Recovery clears state: clean the dirty worktree and age it, then it lands? (still unlanded -> kept; state persists)
[ "$fails" -ne 0 ] && sed 's/^/  run1: /' "$W/run1.log"
echo "$fails failure(s)"; [ "$fails" -eq 0 ]
