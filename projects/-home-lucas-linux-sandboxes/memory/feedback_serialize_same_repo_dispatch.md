---
name: feedback-serialize-same-repo-dispatch
description: "Don't have two same-repo tickets being actively implemented at once; an approved PR idle awaiting lucas42 review does NOT block the next dispatch"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1a322f6a-b1ba-45ab-8435-5406ebc4888e
  modified: 2026-09-29T17:28:35.166Z
---

Don't have two tickets on the **same repo** being **actively implemented** at the same time (two agents writing code concurrently in the same area). Also hold same-repo dispatch while a merged ticket's production step (hand-run migration, prod verification) is still pending.

A PR that is code-reviewer-approved and **idle awaiting lucas42's review does not block** the next same-repo dispatch.

**Why:** 2026-06-25 — I planned to dispatch lucos_media_seinn#525 (ux) and #524 (developer) at the same time; lucas42 said do the UX one now, the developer one after. That was about concurrent implementation. I over-generalised it to "wait for the first PR to merge", and on 2026-10-17 held lucos_media_manager#306 behind the approved-and-idle PR #309. lucas42: "I don't remember saying you couldn't dispatch a second ticket while another has a PR open idley waiting for me to review." The production-step part comes from lucos_campaigns#17/#3 (2026-09-29), a separate case.

**How to apply:** at dispatch, a same-repo ticket blocks only if it's mid-implementation (no PR, or still in the review loop) or has a pending production step. Rule lives in the `/dispatch` skill's Same-repo gate.
