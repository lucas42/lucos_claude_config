---
name: sandbox-branch-hygiene
description: Always verify sandbox repo is on clean main before branching; past sessions leave stale branches and dirty working trees that will be inherited
type: feedback
---

Before branching off `main` in a sandbox repo, **always explicitly switch to main and verify a clean working tree first**. The sandbox environment is reproduced across sessions but the git state is NOT — stale feature branches and uncommitted working-tree changes from past sessions persist.

**Why:** On 2026-04-24, `git checkout -b fix/exporter-healthcheck-mtime` was run from what I assumed was main. In fact the sandbox's `HEAD` was on an unrelated branch `fix-bulk-patch-tag-only-loganne` with a prior session's commit (`Fire Loganne for bulk PATCH when only tags change`) already in its history. The `-b` branched from that polluted history, and my first `git push` carried the unrelated commit into PR #203 alongside my own work. Had to force-push-rebuild after the PR was already open.

**How to apply:** The correct opening sequence in any sandbox repo is:

```bash
cd ~/sandboxes/<repo>
git fetch origin
git checkout main
git reset --hard origin/main        # discard any residual changes from prior sessions
git checkout -b <feature-branch>
```

The `reset --hard` is the key addition to the persona's existing workflow — `git pull origin main` from step 2 of "Working on GitHub Issues" only fast-forwards a *clean* working tree; it silently does nothing useful if the tree is dirty or on a different branch. Also worth checking: `git log main ^origin/main` should be empty (no local commits ahead of origin) before branching.

If a previous session left intentional work-in-progress it'll be in `git stash` or on a named branch — respect that, but don't inherit it.
