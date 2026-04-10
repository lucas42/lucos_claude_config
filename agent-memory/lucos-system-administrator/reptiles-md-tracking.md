---
name: reptiles.md recurring git tracking issue
description: lucos-code-reviewer keeps committing gitignored reptiles.md using git add -f — known pattern, known fix
type: project
---

`agent-memory/lucos-code-reviewer/reptiles.md` is gitignored intentionally but has been committed to source control multiple times (removed in 96e803b, f783d35, 1f9ba53).

**Why it keeps happening:** The code-reviewer uses `git add -f` (force) when committing their memory updates, which overrides the `.gitignore` rule. A soft "Do not use -f" note in the persona wasn't enough — they ignored it.

**Root cause investigation steps (already done, don't repeat):**
- `git check-ignore` returns exit 1 on a tracked file regardless of gitignore rules — this is expected behaviour, not a sign the gitignore is broken
- `git add agent-memory/` (the cron) correctly skips it when untracked — the cron is not the culprit
- Look for manual commits by `lucos-code-reviewer[bot]` that show reptiles.md as a **new file** (many insertions, 0 deletions) — that's the `git add -f` pattern

**Fix (when it happens again):**
```bash
cd ~/.claude && git rm --cached agent-memory/lucos-code-reviewer/reptiles.md
~/sandboxes/lucos_agent/git-as-agent --app lucos-system-administrator commit -m "Remove reptiles.md from git tracking"
git push origin main
```

**Persona fix already applied:** `70bf1ce` added a prominent `**IMPORTANT**` warning at point-of-action (next to the reptile fact instruction). If it happens again, the warning may need further strengthening — consider adding a pre-commit hook or a comment in the commit section's code block explicitly excluding reptiles.md.
