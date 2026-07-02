---
name: pattern-container-restart-log-buffer-artifact
description: A deploy-restart clears Docker logs, so the earliest log line looks like a fresh "onset" of a pre-existing problem — check StartedAt before believing an onset time
metadata:
  type: feedback
---

**A container restart clears its `docker logs` buffer, so the first occurrence of a symptom in the current log is NOT the true onset — it's just where the log starts.** Before reporting an "onset time" from log review, check `docker inspect <c> --format '{{.State.StartedAt}}'` and correlate with deploy events (Loganne `deploySystem`). If the earliest symptom line is minutes after StartedAt, the problem almost certainly predates the restart.

**Why:** 2026-07-02, lucos_arachne#711. I reported "eolas started rejecting arachne's bearer key, onset 06-30 12:35." Reality: eolas_app `StartedAt=06-30T12:04:24Z` (v1.1.17 deploy restart); 12:35 was just the first arachne request in the fresh log. The bulk endpoint had been 200 in the large majority of requests all along.

**Also from the same incident — two self-corrections:**
- **Don't generalize intermittent, self-recovering 403s into a "persistent outage."** I caught 2 transient 403s (each followed by a 200 on retry 30s later) during ops-check log review and wrote them up as "bulk ingest failing / ongoing degraded ingest." Check the *full status distribution over time* (grep all requests, `uniq -c` the status codes) AND the job-success signal (Loganne `knowledgeIngest` = "Knowledge graph updated"; schedule-tracker `ingestor -> True`) before claiming ongoing degradation.
- **Trigger the authoritative end-to-end probe.** The live 200 (arachne's real `KEY_LUCOS_EOLAS` → eolas `/metadata/all/data/` → 200, 1.2 MB RDF) settled it in one command, where log-archaeology left ambiguity.

**How to apply:** any incident where you're about to state an onset time or "ongoing failure since X" from container logs — first (1) check StartedAt, (2) tally the full status-code distribution over the window, (3) check the job/success event stream, (4) run a live probe. See also [[pattern-arachne-eolas-dual-ingest-hyphen-pk]] and [[pattern-eolas-dual-auth-static-key-vs-jwt-middleware]].
