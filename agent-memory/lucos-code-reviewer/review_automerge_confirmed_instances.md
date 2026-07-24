---
name: review-automerge-confirmed-instances
description: Additional confirmed instances of auto-merge status misreporting, supplementing the two-workflows/supervision rules already in agents/workflows/review-pr.md (read that file first — this just adds evidence).
metadata:
  type: feedback
---

The core rules (dependabot-auto-merge.yml vs code-reviewer-auto-merge.yml, `check-unsupervised` usage, `auto_merge: null` does not imply supervision, never claim "auto-merge triggered" from a check-run `conclusion: success` alone) live in `agents/workflows/review-pr.md`, loaded fresh every invocation — read that first.

Additional confirmed misreport instances beyond what's quoted there: lucos_media_metadata_api PR #101 ("auto-merge triggered" reported while awaiting lucas42), lucos_eolas #218 and lucos_contacts #672 (both implied lucas42 needed to click Merge manually — he doesn't, the workflow does it on his approval). All corrected by lucos-site-reliability 2026-04-29.
