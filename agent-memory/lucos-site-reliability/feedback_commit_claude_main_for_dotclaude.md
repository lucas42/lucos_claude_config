---
name: feedback-commit-claude-main-for-dotclaude
description: Commit ~/.claude files with commit-claude-main, never a hand-rolled git-as-agent rebase/stash on the shared tree
metadata:
  type: feedback
---

Commit any file under `~/.claude` with `~/sandboxes/lucos_agent/commit-claude-main --app lucos-site-reliability -m "..." <paths…>` — NOT a hand-rolled `git-as-agent add/commit/pull --rebase/push`.

**Why:** The `~/.claude` checkout is *shared* and routinely dirty with other agents' uncommitted memory files. A manual `pull --rebase`/stash dance on it can silently drop another session's in-flight work. `commit-claude-main` commits the named files onto a freshly-fetched `origin/main` via an isolated throwaway worktree — never checks out main, never pulls/stashes/rebases the shared tree, never touches other agents' files. The helper already exists and resolves identity per `--app` from `personas.json` (works for every persona) — there was never a tooling gap.

**How to apply:** The moment you've edited a persona/reference/memory/CLAUDE.md file under `~/.claude` and need to commit, reach for `commit-claude-main`, not `git-as-agent`. The always-loaded global rule "use git-as-agent for all git operations" is the trap — it primed the reflex; the `~/.claude` exception is now pinned at that reflex point in global CLAUDE.md and in [agent-github-identity.md]'s "Committing ~/.claude changes" section. On a push race it exits non-zero → just re-run. For agent-memory specifically, `~/.claude/scripts/commit-agent-memory.sh --app <persona>` is the memory-scoped equivalent.

**Grounding:** 2026-06-27 I hand-rolled `git-as-agent` + `pull --rebase` + a two-stage stash to land an instruction commit, then had to carefully restore other sessions' stashed work. Worked, nothing lost, but it was exactly the hazard `commit-claude-main` exists to remove. The instruction had already mandated the helper; the miss was mine.

**Ownership boundary — top-level global `~/.claude/CLAUDE.md`:** this is lucas42's *personal, always-loaded* instruction file for every agent in every project. Even a correct, strictly-additive one-liner to it is **his** to sign off — **propose the change to team-lead/lucas42, don't self-apply.** (2026-06-27 I self-applied an accurate exception to its git rule; team-lead held it for lucas42's call. Content was fine; the issue was blast-radius/ownership.) Everything *else* under `~/.claude` — my persona, shared references, my memory — stays mine to edit directly via `commit-claude-main`. The tell that you've crossed the line: you're editing `CLAUDE.md` at the repo root, not a file under `agents/`, `references/`, or `agent-memory/`.
