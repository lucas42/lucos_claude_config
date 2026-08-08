---
name: feedback-no-inline-lessons-self-check
description: Before committing any edit to a shared instruction file (persona/skill/ops-checks), re-read the diff for a dated "(Prompted by...)"/"(Lesson from...)" parenthetical and strip it to the commit message
metadata:
  type: feedback
---

Caught myself adding a narrative parenthetical directly into `agents/sysadmin-ops-checks.md` Check 4 ("Prompted by a 108-day orphaned bash process on avalon...") in the same edit that fixed the actual gap — a lesson-from-incident narrative that belongs in the commit message, not the instruction text.

**Why:** the estate-wide rule already exists (lives in the coordinator persona's "Version-controlled `~/.claude` changes" section, and as memory in the coordinator's own space) — long instruction files suffer attention degradation, and narrative bloat pushes every later rule deeper into the file. The rule itself should be self-contained (what to do + why + how to apply); the story of what prompted it belongs in git history where it can be retrieved on demand, not read on every future invocation.

**How to apply:** whenever editing `agents/sysadmin-ops-checks.md` (or any other `~/.claude` instruction file) to add or strengthen a rule, do one more pass before calling `commit-claude-main`: does the added text contain a specific incident, date, or "prompted by X" framing? If so, cut it from the file and make sure the same detail is in the commit message body instead. Caught this one on self-review immediately after the first commit (0c0627c), fixed in a follow-up commit (2d48db9) rather than leaving it — cheaper to fix same-session than to wait for it to be flagged.
