---
name: feedback-commit-claude-main-for-dotclaude
description: Commit ~/.claude files with commit-claude-main, never a hand-rolled git-as-agent rebase/stash on the shared tree
metadata:
  type: feedback
---

Commit any file under `~/.claude` with `~/sandboxes/lucos_agent/commit-claude-main --app lucos-site-reliability -m "..." <paths…>` — NOT a hand-rolled `git-as-agent add/commit/pull --rebase/push`.

**Why:** The `~/.claude` checkout is *shared* and routinely dirty. A manual `pull --rebase`/stash dance on it can silently drop another session's in-flight work. `commit-claude-main` commits the named files onto a freshly-fetched `origin/main` via an isolated throwaway worktree — never checks out main, never pulls/stashes/rebases the shared tree, never touches other agents' files. The helper already exists and resolves identity per `--app` from `personas.json` (works for every persona) — there was never a tooling gap.

## ⚠️ `git status` LIES in ~/.claude — never reason from it

**A file showing "modified" is NOT evidence it's uncommitted.** Both `commit-claude-main` and the `commit-agent-memory.sh` sweep push via a throwaway worktree at `origin/main`: that advances `origin/main` but **never advances the shared checkout's local HEAD**, so the files stay "modified" in `git status` forever. Measured 2026-07-14: of 36 files `git status` called dirty in my memory dir, **9 were byte-identical to `origin/main`**. The script's own closing comment documents this and warns: *"Do not hand-roll a re-commit just because 'git status' looks dirty; that's how duplicate/contention cycles start."*

**Always verify with `git diff origin/main -- <path>`, never `git status`.** I hit both failure modes it warns about: a pointless re-commit attempt (→ "Nothing to commit: all specified files already match origin/main"), and a **phantom hazard report** — I read a dirty status as "the shared tree is accumulating other agents' unreviewed work" and told team-lead so. Wrong twice over: I'd scoped `git status` to **my own persona's directory**, so all of it was *my* pending edits awaiting the next sweep, not anyone else's.

## `commit-agent-memory.sh` (the sweep) is SAFE — do not report it as a hazard

Verified by reading it, 2026-07-14, after I'd wrongly implied it reintroduces the risk `commit-claude-main` exists to prevent:
- **Same safety model** — `git worktree add --quiet "$WORKTREE_DIR" origin/main`, `git add` runs *inside* that worktree, EXIT trap removes it. It never touches the shared checkout.
- **Scoped** to `agent-memory/` + `projects/` only; explicitly excludes `agents/`, `CLAUDE.md`, `settings.json`.
- **`--app <persona>`** gives persona-mode: that persona's bot identity, only `agent-memory/<persona>/`. Sweep mode's generic "Auto-commit agent memory updates" message is the one real cost, and `--app` is the existing answer.

**How to apply:** The moment you've edited a persona/reference/memory/CLAUDE.md file under `~/.claude` and need to commit, reach for `commit-claude-main`, not `git-as-agent`. The always-loaded global rule "use git-as-agent for all git operations" is the trap — it primed the reflex; the `~/.claude` exception is now pinned at that reflex point in global CLAUDE.md and in [agent-github-identity.md]'s "Committing ~/.claude changes" section. On a push race it exits non-zero → just re-run. For agent-memory specifically, `~/.claude/scripts/commit-agent-memory.sh --app <persona>` is the memory-scoped equivalent.

**Grounding:** 2026-06-27 I hand-rolled `git-as-agent` + `pull --rebase` + a two-stage stash to land an instruction commit, then had to carefully restore other sessions' stashed work. Worked, nothing lost, but it was exactly the hazard `commit-claude-main` exists to remove. The instruction had already mandated the helper; the miss was mine.

**Ownership boundary — top-level global `~/.claude/CLAUDE.md`:** this is lucas42's *personal, always-loaded* instruction file for every agent in every project. Even a correct, strictly-additive one-liner to it is **his** to sign off — **propose the change to team-lead/lucas42, don't self-apply.** (2026-06-27 I self-applied an accurate exception to its git rule; team-lead held it for lucas42's call. Content was fine; the issue was blast-radius/ownership.) Everything *else* under `~/.claude` — my persona, shared references, my memory — stays mine to edit directly via `commit-claude-main`. The tell that you've crossed the line: you're editing `CLAUDE.md` at the repo root, not a file under `agents/`, `references/`, or `agent-memory/`.
