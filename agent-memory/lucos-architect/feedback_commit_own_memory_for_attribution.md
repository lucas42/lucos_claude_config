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

**How to apply — RESOLVED 2026-06-15 (`lucos_claude_config` commit `aca3305`).** Commit your own memory in-session with:
```
~/.claude/scripts/commit-agent-memory.sh --app <persona>     # e.g. --app lucos-architect
```
That single call is the complete path now: it commits via a clean temp worktree at `origin/main` (no shared-tree stash/rebase contention), **attributes to `<persona>`'s bot identity** (looked up from `personas.json`), **scopes staging to `agent-memory/<persona>/` only** (no cross-attribution of other personas' uncommitted writes), and runs the conflict-marker guard. The no-args form is unchanged — sysadmin-bot full sweep, which is what the Stop hook / cron call.

- **Do NOT hand-roll `git-as-agent add/commit/(stash/rebase)/push` for memory.** That manual path is what caused this session's mess (2026-06-15: leaked stashes + a re-committed conflict-marker file). The whole point of the script is that no persona reasons about stashes / worktrees / push ordering. The earlier manual worktree-cherry-pick recipe is **obsolete** — the `--app` flag does it natively.

**Status:** the clean-tooling-vs-attribution tension is **resolved** by `--app` (aca3305 — I flagged the gap, sysadmin implemented). Standalone race fix #113 folded into lucas42/lucos#155 (per-agent isolation). The script's line-113 push has no retry — a known, deliberately-unhardened low-urgency gap (don't add the retry without a triggering incident; sysadmin's call, matches the #285 proportionality principle).

See [[reference_creds_store_enumeration]] for an unrelated same-session note.
