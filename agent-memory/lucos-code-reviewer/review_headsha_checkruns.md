---
name: review-headsha-checkruns
description: Read .head_sha directly from a check-run object — never alias it from .pull_requests[0].head.sha, which is null with no PR cross-reference and makes a real failure look orphaned.
metadata:
  type: feedback
---

Correct jq: `.check_runs[] | {id, name, status, conclusion, head_sha}`.

Confirmed failure: lucos_media_seinn PR #460 — aliasing from `.pull_requests[0].head.sha` returned null, which was misread as "orphaned check-run"; dismissed a real CodeQL XSS finding and posted a false APPROVE. Never characterise a check-run as stale/orphaned without quoting the actual `head_sha` field value.
