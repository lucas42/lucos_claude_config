---
name: project-fb-import-decommission
description: lucos#271 — decommission of lucos_contacts_fb_import, RESOLVED 2026-08-30
metadata:
  type: project
---

`lucas42/lucos#271` — "Decommission lucos_contacts_fb_import (archival walk)". **RESOLVED 2026-08-30.**

Confirmed script-only repo (no `systems.yaml`/`volumes.yaml` entry, no CircleCI project, not in arachne `live_systems`). Work done: `lucos_configy` scripts.yaml entry removed (lucas42/lucos_configy#279, merged+deployed), development credential `KEY_LUCOS_CONTACTS` (linked to `lucos_contacts`) deleted via `ssh -p 2202 creds.l42.eu "rm lucos_contacts_fb_import/development => lucos_contacts/development"`, repo archived. No open issues, no project-board items existed to clean up.

**Residuals, both non-sensitive, surfaced rather than actioned:**
- Dev `SYSTEM`/`ENVIRONMENT` keys are reserved and rejected the delete-via-empty-value form (`Validation Error: SYSTEM is a reserved key`) — orphaned, harmless (no secret content), left in place.
- Production credentials (almost certainly the same `KEY_LUCOS_CONTACTS` + `SYSTEM`/`ENVIRONMENT` shape as dev) are read/write-denied to the agent key — surfaced to lucas42 for his own cleanup rather than attempted.

No durable lesson beyond what's already captured in [[feedback_follow_archival_checklist]] and the lucos_comhra precedent (lucos#171) — this repo's archival matched that shape closely. Keeping this note only until Phase 6 notification lands; safe to delete after.
