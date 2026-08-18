---
name: shared-claude-checkout-ref-state
description: How the shared ~/.claude checkout's HEAD/index drifts, why it matters (defeats the memory sweep's cheap path), and the git-reset branch-clobbering hazard
metadata:
  type: reference
---

The shared `~/.claude` checkout (`lucas42/lucos_claude_config`) is written by ~7 concurrent personas. All commits go via **throwaway worktrees** (`commit-claude-main`, `scripts/commit-agent-memory.sh`) so the shared dirty tree is never touched — which means **nothing ever advances the shared checkout's own HEAD/index**. Assessed on `lucos_claude_config#127` (2026-08-18), 715 commits behind, HEAD pinned at 2026-06-28.

**The illusion.** `git diff <commit>` is *index*-constrained, so files present both on disk and in `origin/main` but absent from the stale index are reported as `D` (deleted). That produced 212 phantom deletions + 212 phantom untracked entries. Only **1** file genuinely differed. To measure real divergence, iterate `git ls-tree -r origin/main` and compare blob hashes — never trust `git diff` against a stale index. (`git hash-object` fails on symlinked paths — `agent-memory/career-advisor` is a symlink to an external dir; filter those or you'll log a false DIFFERS.)

**`git reset <ref>` moves whatever branch is checked out.** Rehearsed: on a feature branch it silently rewrites that branch ref to the target and orphans its commits — no error, no prompt; files survive as untracked, the commit and message do not. That checkout held 40 local branches, **16 unmerged**, and `scripts/return-to-main.sh` exists precisely because the tree does get left on branches. Any reset-based refresh needs a `symbolic-ref --short HEAD == main` guard.

**Mixed reset is otherwise genuinely safe** — rehearsed on a disposable repo: md5sums of every on-disk file identical before/after; uncommitted in-flight edits survive and become *more* visible (status went 6 noisy lines → 3 truthful). Concurrency: 30 mixed resets racing 30 `worktree add`/`remove` — 0 failures, `fsck` clean.

**The real cost of the stale index is not cosmetic.** `commit-agent-memory.sh` gates its expensive path on `git diff --quiet origin/main -- <path>` + `git ls-files --others`, both index-relative — so a stale index makes both permanently true. 24h sample: **1,933 expensive-path entries, 1,880 (97%) ending "Nothing to commit after sync", 4 actual pushes** — each a fetch + worktree add + recursive dir copy + full re-hash, after every turn of every session. Natural control: `agent-memory/lucos-issue-manager/` (defunct, frozen before the index snapshot) is the only real persona dir taking the cheap path.

`settings.json` chronically differs (key ordering + local `"tui"`), so this tree can never have a clean `git status` — a refresh makes it legible, not clean.

Related: [[verify-mechanism-before-relying-on-it]], [[test-prescribed-values-against-rule]].
