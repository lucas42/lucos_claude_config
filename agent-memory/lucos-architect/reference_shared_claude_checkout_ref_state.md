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

**Simulating the post-refresh state without touching the shared tree:** `GIT_INDEX_FILE=$(mktemp) git read-tree origin/main && git status --porcelain` — the *second* column (worktree-vs-index) is what status will show once HEAD/index track `origin/main`; the first column is just the stale-HEAD delta, ignore it. Measured 2026-08-18: **one line, `M settings.json`, zero untracked.**

**I got the steady-state claim wrong once (2026-08-18, #127 §7):** said the tree "will never have a clean `git status`" because in-flight untracked memory files are the normal working state. That conflates an *instantaneous* observation with a *steady state* — an in-flight file is transient by construction and becomes tracked+clean within one sweep cycle. lucas42 pushed back and was right. Distinguish "true at this instant" from "true at rest" before calling anything a permanent residual.

**Why the tree is nearly clean already:** `.gitignore` is **allowlist-shaped** (`*` and `.*` ignored, named paths re-included), so Claude Code's runtime state is structurally excluded rather than enumerated. Preserve that shape. But the allowlist also re-includes Claude Code's `*.tmp.<pid>.<hash>` atomic-write scratch files (`git check-ignore -v` shows `!agent-memory/**` winning) — #124 stopped them being *committed*, nothing stops them being *seen*.

**Precedent for a tool-rewritten tracked file:** `teams/*/config.canonical.json` tracked, `config.json` gitignored. Reuse it for `settings.json` (rewritten at session start) — but note the difference: `teams/config.json` is regenerable runtime state, `settings.json` is *functional* (hooks + permissions), so a canonical file needs a **materialisation step** or it decays into fiction. Do **not** solve it by auto-committing: that file carries `defaultMode: bypassPermissions` and a `Stop` hook running arbitrary code every turn, so it must stay behind deliberate review. Follow-up: `lucos_claude_config#129`.

**RESOLVED 2026-08-18 by `lucos_claude_config#127`** (PR #128, `d262acb`, merged 21:36Z). `scripts/return-to-main.sh` now has two branches: **line 62** is the on-`main` sync, `git fetch && git reset --mixed --quiet origin/main`, guarded on the branch being literally `main`; **line 105**'s `git merge --ff-only` is the *other* branch (merged-feature-branch return). Don't confuse them — I cited 105 as the on-main path and argued against my own design. Steady state after the fix: **0 behind, 0 porcelain**, self-correcting after every turn via the Stop hook.

**A commit produces a one-cycle lag, not decay.** Right after a worktree push the tree reads `behind: 1` with the new files untracked, because the local index hasn't caught up; the hook resolves it in well under a minute (observed: `df0f62c` push → sync logged 40s later, unattended). Do not read that reading as drift, and do not loosen a drift detector's tolerances to absorb it — calibrate tight and alert only on what survives more than one cycle.

Related: [[verify-mechanism-before-relying-on-it]], [[test-prescribed-values-against-rule]].
