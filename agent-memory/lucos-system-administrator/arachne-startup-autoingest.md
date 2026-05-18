---
name: arachne-startup-autoingest
description: lucos_arachne ingestor auto-runs ingest.py on container startup (30s jitter); post-deploy verification is automatic
metadata:
  type: project
---

`startup.sh` in the `lucos_arachne_ingestor` container automatically runs `ingest.py` on every container startup, with a 30-second jitter before execution.

**Why:** The scheduled ingest cron is `15 04 * * *` (once daily). Without the startup auto-run, verifying recovery after a hotfix deploy would require either waiting until the next 04:15Z run or manually `docker exec`-ing the command.

**How to apply:** For scheduled-job containers where stale data has user-visible impact and the cron is infrequent:
- Startup-also-runs means the deploy itself serves as the verification trigger — no manual intervention needed post-deploy.
- When planning post-deploy verification for similar services, check whether startup.sh already invokes the job. If it does, just watch for the container to cycle through Exited cleanly.
- If a new container of this type is created and doesn't have startup auto-run, it's worth adding — the once-daily cron means you'd otherwise have no timely verification path.

**Incident context:** 2026-05-18 arachne-asymmetric-property-ignore-types-gap — deploy of lucos_arachne#543 hotfix auto-triggered ingest, confirming recovery without manual steps.

See also: [[arachne-one-shot-containers]]
