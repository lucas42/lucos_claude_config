---
name: project-head-drift-fix-127
description: lucos_claude_config#127 settled scope — extend return-to-main.sh with guarded mixed reset, not a new tool. Ready/High/mine, awaiting /next dispatch.
metadata:
  type: project
---

lucas42/lucos_claude_config#127 (shared `~/.claude` checkout HEAD/index never advances). Architect assessment (2026-08-18) changed the shape from my original candidate design — read in full before implementing, this is only the settled headline scope:

1. **Guard on `git symbolic-ref --short HEAD` being exactly `main`** — refuse otherwise. Non-negotiable: `git reset <ref>` moves whatever branch is checked out, demonstrated silently orphaning an unmerged feature commit. This checkout holds ~40 local branches, 16+ unmerged.
2. **Extend `scripts/return-to-main.sh`**, don't add a new script — its on-`main` early exit (`[[ "$current_branch" == "main" || "$current_branch" == "HEAD" ]] && exit 0`) is the actual gap, and "on main" is ~100% of the time. Replace that branch with `git fetch --quiet origin main && git reset --quiet origin/main`.
3. **Add to the 15-minute cron** alongside the sweep, so ref state converges with no session live.
4. **Best-effort, never fatal** — log and continue on failure.
5. **Never `--hard`, never `-u`, never a pathspec** — the whole safety argument (working-tree files untouched, in-flight edits survive byte-for-byte and become *more* visible, not less) rests on plain mixed reset. State this in the script's header comment.
6. **Rename is explicitly out of scope** — issue-manager settled it, don't touch the filename/hook/cron wiring names.

**Why:** not cosmetic — `commit-agent-memory.sh`'s cheap-path check (`git diff --quiet origin/main`, `git ls-files --others`) is index-relative, so the stale index defeats it: 1,933/1,940 sweep runs in a 24h window hit the expensive worktree-copy path for nothing (97%+), only ~500 took the cheap path. Fixing the index is the actual fix for that waste, tidiness is secondary.

**Status:** Ready, Priority High, Owner me. **Do not start until dispatched** via `/next` or `/dispatch` — Ready ≠ dispatched, confirmed explicitly by team-lead 2026-08-18.

See also [[lucos-278-network-recreation-reporting-gap]], [[commit-claude-main-delete-support]].
