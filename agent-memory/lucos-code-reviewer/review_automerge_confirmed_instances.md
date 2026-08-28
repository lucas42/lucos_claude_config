---
name: review-automerge-confirmed-instances
description: Additional confirmed instances of auto-merge status misreporting, supplementing the two-workflows/supervision rules already in agents/workflows/review-pr.md (read that file first — this just adds evidence).
metadata:
  type: feedback
---

The core rules (dependabot-auto-merge.yml vs code-reviewer-auto-merge.yml, `check-unsupervised` usage, `auto_merge: null` does not imply supervision, never claim "auto-merge triggered" from a check-run `conclusion: success` alone) live in `agents/workflows/review-pr.md`, loaded fresh every invocation — read that first.

Additional confirmed misreport instances beyond what's quoted there: lucos_media_metadata_api PR #101 ("auto-merge triggered" reported while awaiting lucas42), lucos_eolas #218 and lucos_contacts #672 (both implied lucas42 needed to click Merge manually — he doesn't, the workflow does it on his approval). All corrected by lucos-site-reliability 2026-04-29.

**lucos_backups#407 (2026-08-28) — reported own supervision check, then contradicted it minutes later.** I ran `check-unsupervised lucos_backups` earlier in the same session (during #406's review) and correctly got exit 1 (supervised). Later, after approving #407 and seeing it already merged (`merged_at` set) within a minute of my approval, I wrote "merged (lucos_backups is unsupervised)" in the completion report — a guess from the short gap, not a re-check, and it directly contradicted data already sitting in my own context. Reviews list showed lucas42 approved 25s after me, merge followed 15s after that — his approval triggered it, not mine. Caught by team-lead. **Lesson: a short gap between your approval and a merge is not evidence of *how* it merged — re-run `check-unsupervised` and pull the reviews list every time, even (especially) when you already "know" the answer from earlier in the session.** Fixed the instruction gap directly: `agents/workflows/review-pr.md`'s merged-PR bullet now explicitly bars any cause/attribution commentary — including a passing parenthetical — without a fresh reviews-list check.
