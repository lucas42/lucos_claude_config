---
name: feedback-pr-loop-full-cycle-on-lucas42-fixes
description: after pushing a fix for lucas42's CHANGES_REQUESTED, always go back through lucos-code-reviewer before re-requesting lucas42 — don't shortcut straight to lucas42
metadata:
  type: feedback
---

Every push to a PR — including a fix requested by lucas42 directly, on a
supervised repo, in what feels like a quick two-line tweak — must go back
through the full loop in `~/.claude/pr-review-loop.md`: fix → SendMessage
`lucos-code-reviewer` ("review PR {url}") → wait for their approval on the
*new* head → only then re-request lucas42. Re-requesting lucas42 alone,
without the code-reviewer step, is a documented failure mode (see the loop
doc's "Important: this also applies…" paragraph near line 70) — a new push
resets `review_decision` to null regardless of who asked for the change.

**Why:** On lucos_creds#560 I fixed lucas42's review comments twice (icon
sizing/stroke/sr-only comment, then the link-icon path) and both times went
straight fix → push → re-request lucas42, skipping lucos-code-reviewer
entirely. team-lead caught it because neither 6eb46ad nor fd57317 had a
fresh code-reviewer approval — the last one was on the original commit from
2026-09-13. The instruction already covered this explicitly; this was an
execution miss under the pull of "it's just a tiny CSS/SVG tweak, surely
that's fine," not a gap in the doc.

**How to apply:** Treat *every* push to an open PR — no matter how small
the diff, and even when the requester was lucas42 himself — as iteration N
of the loop. Before re-requesting lucas42, check off: has
`lucos-code-reviewer` reviewed *this exact head SHA* and approved? If not,
send them first. Small-diff fixes are not an exception to the loop.
