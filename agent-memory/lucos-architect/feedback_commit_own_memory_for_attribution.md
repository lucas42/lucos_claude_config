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

**How to apply — on a non-ff push, don't hand-stash other agents' files. Use:**
```
git -c rebase.autoStash=true pull --rebase origin main   # autoStash keeps other agents' uncommitted working-tree files safe
# then re-push
```
Stage only your own path so you never sweep up another agent's in-flight edits. The full recipe is in `references/agent-memory-conventions.md` (authoritative). See [[reference_creds_store_enumeration]] for an unrelated same-session note.
