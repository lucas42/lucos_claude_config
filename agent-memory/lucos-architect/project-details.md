# Detailed Project Notes

Overflow from MEMORY.md for projects with extensive design history.

## lucos_media_metadata_api -- Multi-value fields (#34)

- Go + SQLite, schema-agnostic key-value tags per track (UNIQUE constraint on trackid+predicateid)
- lucas42 rejected: predicate_schema DB table (prefers schema in code), all-arrays approach (dislikes `track.artist[0]`)
- Revised: `multiValuePredicates` as Go constant map (composer, producer, language, offence, about, mentions)
- Data migration: drop UNIQUE constraint, split comma-separated values into separate rows
- Internal refactor needed: map[string]string -> []Tag before schema change
- Search gets simpler with normalised rows (existing JOIN pattern works unchanged)
- rdfgen already has `splitCSV` for multi-value predicates -- can be removed after migration
- Consumers: lucos_media_metadata_manager (PHP), lucos_media_manager (Java), lucos_arachne ingestor (Python), lucos_media_import, lucos_media_weightings
- GET/PUT/PATCH must use same shape (no asymmetry). PUT/PATCH replaces all values for multi-value predicates.
- `DecodeTrack` needs custom JSON unmarshaller for v3 (tags become `map[string]interface{}`)
- 8-step implementation plan: audit -> internal refactor -> define multiValuePredicates -> DB migration -> v3 endpoints -> update rdfgen -> migrate consumers -> deprecate v2
- Revised design posted. Awaiting lucas42 confirmation before filing implementation tickets.

## lucos_repos -- Greenfield redesign (#22)

- Currently a shell: Node.js /_info + deprecated webhook. lucas42 wants greenfield reimagining.
- Proposed: Go + SQLite, single container, deterministic convention auditing
  - Scheduled sweep every 6 hours (not webhook-driven)
  - Convention checks defined in code (Go functions), not config
  - Raises GitHub issues on non-compliant repos (one per finding)
  - HTML dashboard (server-rendered) + JSON API for compliance matrix
  - Repo list from GitHub API (all lucas42 repos), not hardcoded
  - Auth: GitHub App (not PAT -- lucas42 wants clear attribution)
  - Implementation tickets filed: #23-#30
- Audit issue lifecycle (#30): design posted 2026-03-05
  - Audit result is source of truth, not issue state
  - New issues instead of reopening (cleaner timeline, avoids confusion)
  - `audit-finding` label on all audit-raised issues
  - Auto-close from PRs: let it happen, self-heals on next sweep if fix was incomplete
  - Accepted risk: `audit-suppressed` label on closed issues prevents re-creation
  - Awaiting lucas42 approval

## lucos_photos -- Video upload (#60)

- needs-refining. Reviewed 2026-03-04.
- Key design decisions pending: table rename (photo->media_item vs discriminator column), video size limits, transcoding scope, face detection deferral
- Recommended 6-step incremental delivery
- Streaming upload is prerequisite (current endpoint reads entire file into memory)
- Range request support needed for video serving
- Residual Qdrant check still in /_info endpoint code

## lucos_eolas -- Festival duration (#68)

- Options A/B rejected by lucas42. Proposed Option C (separate FestivalPeriod model with FK to Festival, label, start_day, start_month, duration_days).
- Awaiting decision. lucos_time#76 filed as follow-up (blocked on #68).

## lucos_creds -- SSH key issue (#61)

- Multiline values break .env format. Proposed fixing .env quoting for multiline values rather than adding a new credential type.
- Dedicated key lifecycle management (generation, rotation) deferred as unnecessary at current scale (2-3 keys).
