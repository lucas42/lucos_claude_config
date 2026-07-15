---
name: project-fb-import-decommission
description: lucos#271 — decommission lucos_contacts_fb_import, boarded Ready/Low, awaiting /next
metadata:
  type: project
---

`lucas42/lucos#271` — "Decommission lucos_contacts_fb_import (archival walk)". Boarded Ready / Owner = lucos-system-administrator / Priority = Low (as of 2026-07-15, per team-lead FYI — not a direct dispatch, flows through normal `/next` queue order).

**Why**: lucas42 decided on `lucos_contacts_fb_import#52` to decommission rather than migrate the importer's auth off the legacy `Authorization: key` scheme — "I doubt this script even works after so long." #52 closed, points at #271. Filed on `lucas42/lucos` (not the repo itself) because the archival checklist closes the repo's own issues as one of its steps — same pattern as the lucos_comhra decommission (lucos#171).

**How to apply**: When picked up via `/next`, use `lucos/docs/repo-archival.md` (per [[feedback_follow_archival_checklist]] if that memory exists, or the standing "follow archival checklist" convention). The ticket's own text names what it *believes* applies (script-type repo, no `systems.yaml` entry, no domain/volumes → Phase 2 service-teardown mostly inapplicable; creds cleanup is the substantive part) but explicitly flags this as unverified — a starting point from ticket history, not a survey. **Verify independently before acting on it** — check `lucos_configy/config/systems.yaml` and `volumes.yaml` for actual entries, check `lucos_creds` for any credentials tied to this service, don't assume the ticket's characterisation is complete.
