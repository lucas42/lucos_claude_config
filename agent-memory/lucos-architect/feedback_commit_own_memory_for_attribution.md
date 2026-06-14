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

**How to apply (updated 2026-06-15).** The worktree-isolation this memory used to describe manually is now productized as `scripts/commit-agent-memory.sh` (commits the memory dirs to `main` via a clean temp worktree at `origin/main` — no shared-tree stash/rebase contention — and now includes a conflict-marker guard, added after my malformed file reached main this session). **BUT it commits with a FIXED identity `lucos-system-administrator[bot]` (script line 31), so it does NOT preserve per-agent attribution** — running it for your own memory attributes it to the sysadmin bot, the exact mis-attribution this memory exists to prevent.

So there is a live tension: clean tooling (the script) vs per-agent attribution (lucas42's requirement). Until resolved:
- **If attribution matters, self-commit** with `git-as-agent --app <persona>` (stage only `agent-memory/<persona>/`), and land it via a throwaway worktree + cherry-pick — clean AND correctly attributed:
```
git-as-agent --app <persona> add agent-memory/<persona>/ && git-as-agent --app <persona> commit -m "..."
MYSHA=$(git -C ~/.claude rev-parse HEAD); WT=$(mktemp -d)
git -C ~/.claude worktree add -q "$WT" origin/main
cd "$WT" && git-as-agent --app <persona> cherry-pick "$MYSHA" && git-as-agent --app <persona> push -q origin HEAD:main
cd ~/.claude && git worktree remove --force "$WT"
```
- **Do NOT hand-roll `rebase --autostash` against the shared tree** — it races the cron and fragments (mess this session, 2026-06-15: leaked stashes + a re-committed conflict-marker file).

**Clean resolution to pursue (flagged to sysadmin, refines lucas42/lucos_claude_config#116):** parametrise `commit-agent-memory.sh` with `--app <persona>` so the clean worktree path *also* attributes per-persona — then "everyone uses the script" becomes the complete fix, clean AND attributed.

**Status:** standalone race/attribution fix (#113) declined, folded into lucas42/lucos#155 (per-agent isolation, which dissolves the shared-tree root cause). Conflict-marker guard is now IN the script (resolved this session).

See [[reference_creds_store_enumeration]] for an unrelated same-session note.
