---
name: pr-merge-never-reaches-working-tree
description: RESOLVED 2026-08-20 (lucos_claude_config#134/#135) — return-to-main.sh now self-materialises PR-merged content onto the shared ~/.claude working tree; this file records the historical gap and the fix's shape for context
metadata:
  type: reference
---

**RESOLVED 2026-08-20.** `lucas42/lucos_claude_config#134` shipped in PR #135 (`435ae61`): `return-to-main.sh` gained `materialize_pr_content`, called right after the mixed reset, before `check_persistent_dirt`. Discriminator: capture `OLD=$(git rev-parse HEAD)` *before* the fetch; for each differing path, `disk == OLD` means untouched locally since the last sync → safe to overwrite with `origin/main`'s blob (temp-file + atomic `mv -f`, never `git checkout -- <path>` in place — that writes through the existing inode and can corrupt a running script mid-execution, verified via rehearsal). Anything else (a genuine local edit, including a path both a PR and a local edit touched) is left alone. A path present upstream but missing on disk materialises unconditionally (needs `mkdir -p` first for a genuinely new directory — the one bug `lucos-code-reviewer` caught in review: the naive `cat-file > $tmp` redirect fails before exec when the parent dir doesn't exist, and the failure leaks past `2>/dev/null` since that redirect only applies once the command execs). A path a PR deleted upstream but that still exists on disk gets a warning, never a delete. Symlinks are skipped entirely.

**Bootstrap wrinkle, expected and now closed out:** the fix's own PR merge hit the exact gap it was closing — `origin/main` had it, disk didn't, until `materialize_pr_content` was itself live from disk. Manually bootstrapped once (same temp-file+atomic-rename technique), then ran the hook for real to confirm HEAD converges and the tree stays clean. Should not recur — this was the last manual materialisation this repo needs.

**Historical context (why this existed):** `commit-claude-main`/`commit-agent-memory.sh` commit *from disk to origin/main*, so disk stays authoritative on that path. A PR merge goes branch → `origin/main` directly, bypassing the working tree — the inverse direction had no mechanism before #134. First surfaced 2026-08-18 (`lucos_claude_config#130` merged but sat unmaterialised on disk for ~an hour).

See also [[project_head_drift_fix_127]], [[settings-json-restart-verification-129]].
