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

**How to apply — use `commit-claude-main`, NOT the older script.** The global CLAUDE.md's `~/.claude` exception now prescribes:
```
commit-claude-main --app <persona> -m "message" <files…>      # explicit file paths; a directory arg errors
```
It commits onto a freshly-fetched `origin/main` via an isolated throwaway worktree that never touches the shared (routinely dirty) tree. `~/.claude/scripts/commit-agent-memory.sh --app <persona>` still exists (verified 2026-07-14) but is **superseded** — prefer the CLAUDE.md-prescribed command. Either way: **do NOT hand-roll `git-as-agent` add/commit/stash/rebase/push for memory** — that manual path caused the 2026-06-15 mess (leaked stashes + a re-committed conflict-marker file).

**Status: the race is NOT resolved — only the tooling is.** `--app` fixed *how* to commit cleanly; it did nothing about the sysadmin auto-commit cron sweeping your files before you commit. **Fresh evidence 2026-07-14 (lucos_repos#469 session):** I wrote 4 memory files and committed them promptly in-session, and the cron's "Auto-commit agent memory updates" (`lucos_claude_config` `76efbf8`) still beat me by **66 seconds** — so 2 of the 4 landed attributed to `lucos-system-administrator[bot]` and only 2 to me. Committing promptly narrows the window; it does not close it. Tracked (per-agent isolation) inside lucas42/lucos#155, which is a *broad ideation* ticket rather than a targeted fix — so don't expect it fixed soon, and don't re-file a duplicate.

**Practical consequence:** don't assert "I committed my memory" as if attribution followed. **Verify:** `git log --format='%h %an :: %s' origin/main -- agent-memory/<persona>/<file>`. If the cron got there first, the content is still correct on `main` — that's what matters functionally — and attribution can't be retroactively fixed. Note it and move on; it isn't worth a rewrite-history exercise. The script's push has no retry — a known, deliberately-unhardened low-urgency gap (don't add it without a triggering incident; sysadmin's call, per the #285 proportionality principle).

See [[reference_creds_store_enumeration]] for an unrelated same-session note.
