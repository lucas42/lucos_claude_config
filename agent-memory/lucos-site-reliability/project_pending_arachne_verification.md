---
name: project-pending-arachne-verification
description: PENDING follow-up due 2026-05-30 — verify the composer/producer→eolas:Person migration landed cleanly in arachne after the 04:15 UTC daily ingest cron
metadata:
  type: project
---

**PENDING — do this on the first live session on/after 2026-05-30 (after 04:15 UTC).**

The 2026-05-29 composer/producer → eolas:Person migration (lucas42/lucos_media_metadata_api #237, shipped via #274) is fully done & verified on the media side (2138 tags → 861 Person URIs, 816 created; track-count 14707, uri-integrity green). The new Person links land in arachne only via the **04:15 UTC daily ingest cron** of the migration-current export (the migration is a direct DB UPDATE, so no per-entity webhooks). team-lead agreed (2026-05-29) to verify post-cron in the next live session rather than via a scheduled remote agent — the `/schedule` skill is broken (v1→v2 API drift, routed to sysadmin) and a remote CCR env may lack SSH-to-prod anyway.

**Why:** team-lead asked to close lucas42's "ensure nothing broke" end-to-end. Migration is proven safe; this is a confirmation, not a risk-watch.

**How to apply (gate every read on a clean window):**
1. NO-WIPE gate — arachne `mo:Track` count stable ~14707 (collapse = #272 torn-export wipe → incident). SPARQL from inside `lucos_arachne_ingestor` on avalon: `SELECT (COUNT(?s) AS ?c) WHERE { ?s a <http://purl.org/ontology/mo/Track> }` against `http://triplestore:3030/arachne/query`.
2. Links present — `person/904` (https://eolas.l42.eu/metadata/person/904/, 'stic.man') in graph; migrated composers (Hans Zimmer, Quincy Jones) resolve to eolas Person entities; composer/producer predicates point at eolas person URIs not freetext.
3. Both ingest code paths clean in the 04:15 logs (`docker logs --since … lucos_arachne_ingestor`): `graph_to_typesense_docs` ('Upserted N documents to tracks collection') + `update_person_docs_in_searchindex` ('Upserted N Person documents'), no Tracebacks, no track wipe. (`contacts.l42.eu/people/2 [Errno 404]` is benign.)

**On result:** all-pass → comment confirmation on lucas42/lucos_media_metadata_api#237 + tell team-lead; anything off → raise an incident per normal process + flag team-lead/lucas42. Full runbook: [[pattern_media_metadata_arachne_pipeline]]. (Was task #4 in the 2026-05-29 migration session.)
