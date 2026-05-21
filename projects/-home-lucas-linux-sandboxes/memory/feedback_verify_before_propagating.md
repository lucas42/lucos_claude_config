---
name: feedback-verify-before-propagating
description: "Verify identifiers (URLs, paths) AND behavioural claims about systems (how a script handles X, what gets auto-cleaned) before relaying to teammates — neither agent reports nor lucas42's recollection are verified facts; check the source"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 43800831-9ee6-4716-b001-e07766f613bc
---

When I am about to put something a teammate (or lucas42) told me into multiple downstream artifacts — a new ticket body, body PATCHes on existing issues, follow-up dispatches, instructions to a third party who will act on them — verify it against an authoritative source first. The original speaker's "X is Y" or "Y handles X" is a useful summary, not a verified fact.

Two categories where this trap is common:

1. **Concrete identifiers** (URL, domain, repo name, API path, port, hostname). The speaker may have pasted from an adjacent repo with a similar name, or from outdated docs.

2. **Behavioural / architectural claims about how a system works** ("configy sync cleans up removed-system creds", "the loganne webhook fires on event X", "the orb job re-tags on every merge"). The speaker may have an outdated mental model, or be describing what they intended rather than what the code does. **lucas42 is not exempt here** — he's authoritative for *decisions*, but his recollection of how a script behaves is just as fallible as any agent's report. Verify by reading the actual code, not by trusting the assertion.

**Why (incident 1, identifier):** On 2026-05-18 the developer reported the media-metadata API endpoint as `https://media-metadata.l42.eu/webhooks`. I propagated that into the new `lucos_loganne#466` body, into a body PATCH on `lucos_media_metadata_api#139`, and into a body PATCH on `lucos_media_metadata_api#236`. The code reviewer also accepted it. lucas42 caught it at PR review: `media-metadata.l42.eu` is actually `lucos_media_metadata_manager`'s domain, not `lucos_media_metadata_api`'s. The bad value had landed in four places by the time anyone noticed.

**Why (incident 2, behavioural):** On 2026-05-21 during the `lucos_comhra` decommission, lucas42 said "`PORT` and `APP_ORIGIN` come from the configy sync, so should be updated the next time it runs after the configy change has been deployed." I relayed that to sysadmin and explicitly told them not to remove those creds manually. The code-reviewer caught it on a doc PR ~30 mins later: `configy_sync/sync.py` iterates over systems currently *in* configy and only sets/updates creds for those — it has no logic to discover removed systems and clean their creds. So `lucos_comhra/production/PORT` and `APP_ORIGIN` sat orphaned, and a Phase 2d step I'd told sysadmin was handled was not actually done. Reading the 20-line sync.py would have caught it immediately.

**How to apply:** When a single propagation step turns someone's claim into multiple downstream artifacts or instructions, treat it as a fan-out and verify first. Cheap checks: `curl -sI https://X.l42.eu/_info` to identify what system answers an endpoint; read the target repo's `docker-compose.yml`, `sync.py`, or whatever ~20-line script implements the behaviour being claimed; ask the actual owner of the system. If verification isn't practical in the moment, propagate with a `TODO verify` placeholder rather than the unverified value. The cost of getting this wrong is *every* downstream artifact needing correction — and every reader has to re-read corrected text. See [[feedback-correct-agents]] for the two-message correction sequence; this memory captures the upstream side (don't propagate the error in the first place).