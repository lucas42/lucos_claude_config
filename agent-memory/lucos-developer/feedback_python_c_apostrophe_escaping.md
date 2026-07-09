---
name: feedback-python-c-apostrophe-escaping
description: Avoid python -c with manual '"'"' bash-quote-escaping for multi-line JS edits containing apostrophes — use the Edit tool instead
metadata:
  type: feedback
---

Don't use `python3 -c "..."` with manually-escaped apostrophes (the classic
`'"'"'` bash single-quote-escaping trick) to reapply multi-line JS/text edits
that contain apostrophes (e.g. "aithne's", "jose's", "isn't"). It's easy to
get the escaping wrong in a way that *doesn't* raise an error — the literal
`'"'"'` sequence ends up embedded in the output file as visible text, silently
shipped in a comment. This actually happened twice in one session (both
`lucos_media_seinn` PR #552 and required a follow-up fix commit) while
reapplying the JWKS serve-stale wrapper against freshly-rebased worktrees.

**Why:** a hard error would have been self-correcting; a silent corruption
in a comment isn't caught by tests or linting, only by a human or reviewer
actually reading the file closely. It shipped in a pushed PR before code
review even started.

**How to apply:** when reapplying edits against a freshly-rebased worktree
(e.g. because the shared checkout was stale — see the implement-issue
workflow's Step 3/4 staleness warning), prefer the `Edit` tool over
`python3 -c` / `sed` one-liners whenever the text contains apostrophes or
other shell-special characters. The `Edit` tool takes literal strings with
no shell-quoting layer, so there's no escaping to get wrong. If a `python3`
script is unavoidable (e.g. bulk find/replace across many similar edits),
write the script to a file with the `Write` tool first (which also takes a
literal string, not a shell argument) and run `python3 script.py`, rather
than passing the script inline via `-c "..."` inside a Bash command.

After any such reapplication, grep the result for the giveaway artifact
(`'"'"'`) before committing, as a cheap safety net.
