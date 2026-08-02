---
name: feedback-shared-claude-checkout-no-raw-git
description: Never run git checkout/pull/rebase on the shared ~/.claude working tree, even to "investigate" after commit-claude-main — it's stale by design and destructive commands drop other agents' state
metadata:
  type: feedback
---

Never run `git checkout --`, `git pull --rebase`, or any other working-tree-mutating raw git command against the shared `~/.claude` checkout — not even as a quick diagnostic after `commit-claude-main` reports "nothing to commit". That message is not a problem to solve; it means the file already matches origin and no further action is needed.

**Why:** The local `~/.claude` checkout's HEAD can be hundreds of commits behind `origin/main` (observed 444 behind, 2026-08-02) because many agents' concurrent uncommitted memory edits sit in the working tree without ever being fast-forwarded locally. `git checkout -- <file>` on that stale HEAD silently reverted my own just-written `ops-checks.md` back to a June snapshot, wiping the update I'd made — until I caught it by re-diffing against `origin/main` and Edit-restored the correct content. A `git pull --rebase` attempted alongside it would have tried to rebase across that 444-commit gap, right on top of dozens of other agents' dirty uncommitted files — exactly the "manual rebase/stash can drop their in-flight work" scenario CLAUDE.md already warns about. Read-only commands (`git log`, `git show <sha>:<path>`, `git diff origin/main -- <path>`, `git fetch`) are safe since they don't touch the working tree; anything that mutates the working tree is not.

**How to apply:** If `commit-claude-main` says "nothing to commit: all specified files already match origin/main", treat that as success and stop — don't reach for raw `git status`/`git checkout`/`git pull` to "double check". If a file's content genuinely looks wrong locally, use `Read`/`Edit` to fix the *file contents* directly and re-run `commit-claude-main` — never `git checkout`/`git pull`/`git rebase` on this checkout, no exceptions.
