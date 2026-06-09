---
name: commit-own-memory-for-attribution
description: Always commit+push your own agent-memory changes in-session (scoped to your path) — the cron is only a backstop; per-agent attribution is load-bearing
metadata:
  type: feedback
---

# Commit your own agent-memory changes — don't lean on the cron

**Rule:** after any write to `agent-memory/<persona>/`, commit AND push it yourself in-session via `git-as-agent --app <persona>`, staging **only your own `agent-memory/<persona>/` path**. The sysadmin auto-commit cron (~every 15 min, "Auto-commit agent memory updates") is a **backstop, not the primary path**.

**Why:** lucas42 overrode a proposal to drop the manual step (`lucos_claude_config` `98ea91a`, 2026-05-31). If the cron is the only committer, every memory change is attributed to `lucos-system-administrator[bot]` and the git log no longer says *which* agent changed what. Per-agent attribution is the point.

**My mistake (2026-05-31):** I hit a non-fast-forward push (the cron had swept my files first) and inferred the manual commit was therefore "redundant and contention-prone", and flagged it for removal. Wrong — the contention is handled by a recipe, not by removing the step. My session's changes landed via the cron and so were mis-attributed to the cron bot; can't retroactively fix that, but follow the recipe next time.

**How to apply — on a non-ff push, don't hand-stash other agents' files.** The documented recipe (`references/agent-memory-conventions.md`, authoritative) is:
```
git -c rebase.autoStash=true pull --rebase origin main   # then re-push; stage only your own path
```
**But that recipe is fragile and failed twice on 2026-06-09:** `pull --rebase` aborts with "untracked working tree files would be overwritten by checkout" when another agent's *new* memory file (now also on origin) sits untracked in the shared `~/.claude` tree — autoStash doesn't cover untracked files, so the rebase can't detach HEAD. **Reliable fallback that worked both times: commit locally, then land it via a throwaway worktree at origin/main and cherry-pick:**
```
MYSHA=$(git -C ~/.claude rev-parse HEAD)        # after committing your staged memory locally
WT=$(mktemp -d); git -C ~/.claude worktree add -q "$WT" origin/main
cd "$WT" && git-as-agent --app <persona> cherry-pick "$MYSHA" && git-as-agent --app <persona> push -q origin HEAD:main
cd ~/.claude && git worktree remove --force "$WT"
```
This never touches the shared working tree (no stash, no index.lock contention) — it's the same isolation the cron already uses, and is exactly the worktree-isolation fix I proposed as #113 Option B′.

**Status (2026-06-09):** the standalone race/attribution fix (#113 Option C/B′) was **declined by lucas42** as more complexity than the friction warrants and **folded into the agent-isolation work on lucas42/lucos#155** (lucos_claude_config#113 closed not_planned). So: don't re-propose a standalone fix; the manual-commit recipe above still stands until lucos#155 delivers per-agent isolation (which dissolves the shared-working-tree root cause). The worktree-cherry-pick fallback above is the interim workaround when autoStash aborts.

See [[reference_creds_store_enumeration]] for an unrelated same-session note.
