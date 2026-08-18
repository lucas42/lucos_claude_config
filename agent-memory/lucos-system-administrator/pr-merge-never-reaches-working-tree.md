---
name: pr-merge-never-reaches-working-tree
description: A PR merge to lucos_claude_config's origin/main never lands on the shared ~/.claude working tree — #127's mixed reset deliberately never touches working-tree files, so PR-shipped script/config changes silently don't run until manually materialized
metadata:
  type: reference
---

Confirmed 2026-08-18: lucas42/lucos_claude_config#130 merged, HEAD showed `0 behind origin/main` (the #127 fix working correctly), but `scripts/return-to-main.sh` and `.gitignore` on disk still lacked #130's changes for ~an hour — `git check-ignore` resolved the wrong rule, the new function didn't exist in the script the post-turn hook actually executes.

**Why:** `commit-claude-main`/`commit-agent-memory.sh` commit *from disk to origin/main* — disk stays authoritative on that path. `return-to-main.sh`'s `git reset --mixed` (never `--hard`) deliberately never touches working-tree files, by design (that's what makes it safe against in-flight edits). A PR merge goes branch → `origin/main` directly, bypassing the working tree entirely — the inverse direction has no mechanism at all. Git state can't distinguish "stale because nobody's touched it since the PR merged" from "genuinely locally edited," so this can't be fixed by naively extending the reset to also overlay differing files.

**How to apply — until lucas42/lucos_claude_config#134 (the tracking issue) ships a real fix:** after any PR to `lucos_claude_config` merges and touches a script/config/persona/reference file, manually materialize it onto disk — `git show origin/main:<path>` written byte-for-byte (verify via `git hash-object` against the tree object, not just a text diff), then verify via actually executing the changed code path, not just reading the file. Do this every time, not just once — I did it for #127's own script after that PR merged and forgot to repeat it for #130's further changes to the same file, which is exactly how this was discovered.

See also [[project_head_drift_fix_127]], [[settings-json-restart-verification-129]].
