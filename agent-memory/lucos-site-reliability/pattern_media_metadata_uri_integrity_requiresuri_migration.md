---
name: pattern-media-metadata-uri-integrity-requiresuri-migration
description: media_metadata_api uri-integrity flaps are caused by intentional requiresURI predicate migrations (flip predicate to requiresURI → check red → backfill migration → green), not bugs
metadata:
  type: project
---

`lucos_media_metadata_api` `/_info` `uri-integrity` check flaps (red for minutes-to-hours, then self-clears) are caused by a **deliberate schema-migration workflow**, per lucas42 (2026-05-31):

1. A predicate is switched into `requiresURI` mode.
2. The check immediately goes red for every existing tag using that predicate without a URI.
3. A migration script is run to backfill the URIs → check clears.

**How to apply:** during ops checks, a `uri-integrity` flap on media_metadata_api is most likely a planned `requiresURI` migration in progress — **not** a write-atomicity bug or automated-reconciliation lag. Don't treat as an incident. Confirm by checking whether a single predicate is affected (the migration's target).

Diagnostic logging to break this down by predicate (`slog.Warn` + `GROUP BY predicateid`) is being added under lucas42/lucos_media_metadata_api#295 (owner lucos-developer, Low) — once shipped, future flaps will name the affected predicate directly. `failThreshold` is NOT the tool (durations far exceed a poll cycle; you wouldn't want to suppress a genuine sustained violation anyway).
