---
name: feedback-verify-before-propagating
description: "When propagating a concrete identifier (URL, domain, repo name, API path) from a teammate's message into multiple GitHub bodies, verify against an authoritative source — an agent's report is not a verified fact"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 43800831-9ee6-4716-b001-e07766f613bc
---

When a teammate hands me a concrete identifier (URL, domain, repo name, API path, port, hostname) and I am about to put it into multiple GitHub locations — a new ticket body, a body PATCH on existing issues, follow-up dispatches — verify it against an authoritative source before propagating. The agent's "the X is Y" is a useful summary, not a verified fact; they may have pasted from an adjacent repo with a similar name, or from outdated docs, or got it slightly wrong.

**Why:** On 2026-05-18 the developer reported the media-metadata API endpoint as `https://media-metadata.l42.eu/webhooks`. I propagated that into the new `lucos_loganne#466` body, into a body PATCH on `lucos_media_metadata_api#139`, and into a body PATCH on `lucos_media_metadata_api#236`. The code reviewer also accepted it. lucas42 caught it at PR review: `media-metadata.l42.eu` is actually `lucos_media_metadata_manager`'s domain, not `lucos_media_metadata_api`'s. The bad value had landed in four places (one PR, three issue bodies) by the time anyone noticed.

**How to apply:** When a single propagation step turns a teammate's identifier into multiple downstream artifacts, treat it as a fan-out and verify first. Cheap checks: `curl -sI https://X.l42.eu/_info` to see what system answers; read the target repo's docker-compose or deployment config; ask the relevant sysadmin or owner. If verification isn't practical in the moment, propagate with a `TODO verify domain` placeholder rather than the unverified value. The cost of getting this wrong is *every* downstream artifact needing correction — and every reader has to re-read corrected text. See [[feedback-correct-agents]] for the two-message correction sequence; this memory captures the upstream side (don't propagate the error in the first place).