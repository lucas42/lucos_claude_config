---
name: migration-finishoff-state
description: Media-metadata→eolas migration finish-off (2026-05-31); the one held follow-up not captured in any ticket
metadata: 
  node_type: memory
  type: project
  originSessionId: 2557587a-674d-403d-ae41-92b3642a8ffb
---

Media-metadata→eolas migration **finish-off** swept on 2026-05-31: all teammates polled, ~14 tickets raised + triaged as migration tier-1 (High) on the lucOS Issue Prioritisation board — across lucos_media_metadata_api / _manager / _weightings, lucos_eolas, lucos_arachne, lucos_creds, lucos_configy. All substantive state lives on tickets / PRs / board; a fresh `/triage` + `/next` picks it up. The urgent fix (reconcile silently no-opping, lucos_media_metadata_api#303) is already merged.

**The one follow-up NOT in any ticket** — capture point for context-clear: **retire the media-metadata migration from `lucos/docs/priorities.md`** (it's listed there as #1 priority, dated 2026-05-22) once the finish-off is fully done — i.e. eolas ADR PR lucos_eolas#288 merged AND lucos_arachne#597 (artist↔person, Option A vs B) decided AND the tidy-up tickets closed. Flagged by architect (A3) + coordinator; do it at close-out. When #597 is decided, the architect also amends eolas#288 §6 to record the canonical-source contract. Cf. [[project_v3_migration]] (prior migration, retired the same way).
