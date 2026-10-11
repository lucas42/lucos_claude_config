---
name: project-photos-migration-prep
description: "State of lucos_photos going into the Google Photos migration (#427) — pre-migration fixes done 2026-10-11, what's still unproven"
metadata:
  node_type: memory
  type: project
  originSessionId: 612d7504-31f9-4642-9197-51f1fe70c266
  modified: 2026-10-11T13:52:05.779Z
---

On 2026-10-11 lucas42 had every Ready lucos_photos ticket except the migration dispatched so known problems were cleared first: #527 (zero-byte uploads), #528 (stuck-count split), #530 (orphan persons), #568 (contact sync hourly + UA), #573 (profile-picture dedupe, two RQ slots per person). All merged. Next step: the migration itself, lucas42/lucos_photos#427, in a fresh session.

**Why:** lucas42 wanted lucos_photos clean ahead of the bulk import.

**How to apply:**
- #573's dedupe is verified on rq 2.12 locally but has never enqueued in prod — the migration import is its first real test; watch for `enqueue_profile_picture: enqueued profilepic-<uuid>` and one regeneration per person, not one per photo.
- Live photos DB verified complete against 09-12/09-18/10-11 backups (SRE, 2026-10-11). The "1,700 persons / 732 orphans" figures came from a DB copy discarded on 09-16 — not lost data.
- lucas42/lucos_photos#469 (pre-name faces) is Blocked and part of the migration; #424 is the epic.
- Related: [[project-avalon-disk-failure]]
