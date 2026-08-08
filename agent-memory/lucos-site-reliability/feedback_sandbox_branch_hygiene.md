---
name: sandbox-branch-hygiene
description: Always verify sandbox repo is on clean main before branching; past sessions leave stale branches and dirty working trees that will be inherited
type: feedback
---

Before branching off `main` in a sandbox repo, **always explicitly switch to main and verify a clean working tree first**. The sandbox environment is reproduced across sessions but the git state is NOT — stale feature branches and uncommitted working-tree changes from past sessions persist.

**⚠️ RECURRED 2026-08-08 — the rule existed and did not fire, so the fix went into the instruction.** `git checkout -b incident-report-…` in `~/sandboxes/lucos` (which holds **~75 stale incident branches**) branched off `incident-report-home-link-packet-loss`, and PR lucas42/lucos#281 silently carried all of lucas42/lucos#280's report — 5 commits, 2 files. Merging it would have landed a second incident report whose own domain review was still outstanding. **Nothing in the PR body reveals this**; the only tell is checking. `references/incident-reporting.md` Step 2 now carries the `checkout main && reset --hard origin/main` opener *and* a post-open `pulls/{N}/files` verification, because a memory that has failed twice needs to be at the point of action instead.

Two mechanics worth keeping: recovery is `git rebase --onto origin/main <last-foreign-commit> <branch>` then `push --force-with-lease` (get the upstream from `git log --oneline --topo-order origin/main..HEAD` — the GitHub commits API does **not** list topologically, and using its order picks the wrong parent and conflicts). GitHub takes several seconds to re-derive `changed_files` after a force-push, so **re-check rather than trusting the first response** — it will still show the old count.

Same trap, opposite direction: a checked-out-but-unmerged branch makes a file look like merged history. On 2026-08-08 I reported an incident as "already covered" by a report that was only an open draft PR. For "does a report exist?", check `origin/main`, not the working tree.

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
