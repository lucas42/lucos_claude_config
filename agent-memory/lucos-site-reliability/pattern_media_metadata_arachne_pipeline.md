---
name: pattern-media-metadata-arachne-pipeline
description: How the lucos_media_metadata_api → /v2/export → lucos_arachne ingest pipeline works, plus reliability landmines (#272 OPEN; #271 FIXED via #592) and the ad-hoc trigger runbook
metadata:
  type: project
---

The media→knowledge-graph pipeline and its current (2026-05-28) failure modes.

**Data flow:**
- `lucos_media_metadata_api` (container `lucos_media_metadata_api`, image `lucas42/lucos_media_metadata_api`) holds the SQLite DB at volume `lucos_media_metadata_api_db` → `/var/lib/media-metadata/media.sqlite` (WAL mode).
- A **separate** container `lucos_media_metadata_api_exporter` runs `rdf-exporter` on a busybox cron (`5 * * * *`, hourly + once on startup), reads `db:/data:ro`, writes `all-media.ttl` (~16-17MB healthy) to volume `lucos_media_metadata_api_exports` → `/var/lib/exports/`.
- The API serves that **cached file** at `https://media-api.l42.eu/v2/export` (auth-gated; `http.ServeFile` of `RDF_OUTPUT_PATH`). NOT generated live.
- `lucos_arachne` ingestor fetches `/v2/export` as graph `<https://media-api.l42.eu/v2/export>`. Ad-hoc: `docker exec lucos_arachne_ingestor sh -c 'INGEST_STARTUP_DELAY=0 pipenv --quiet run python -u ingest.py'` (runs once, exits) — **this `ingest.py` one-shot is the ONLY correct ad-hoc trigger. NEVER `docker restart lucos_arachne_ingestor` to force an ingest: a restart fires a startup ingest against whatever (possibly stale) export is currently served AND bounces the webhook server (`server.py`:8099). Bit me 2026-05-29 — restarted on a corrupted read before I had this runbook, which ingested the stale pre-migration export.** Daily cron: 04:15 UTC. Skips a source if its content hash is unchanged.

**Ad-hoc commands (avalon.s.l42.eu):**
- Regenerate export: `docker exec lucos_media_metadata_api_exporter /usr/local/bin/rdf-exporter` (slow — ~8-9 min at 100% CPU; rdf2go is O(n²)-ish on ~150k triples).
- Query raw triplestore (basic-auth `lucos_arachne`/`KEY_LUCOS_ARACHNE`, from inside ingestor): `session.post("http://triplestore:3030/raw_arachne/sparql", data={"query":…})`. The `arachne` (OWL-inferred) endpoint is what the MCP tools hit; `raw_arachne` for GRAPH-clause queries.

**Landmine 1 — exporter serves torn/empty exports (lucos_media_metadata_api#272):** `copySQLiteDB` does a naive `io.Copy` of the live WAL-mode DB (no consistent snapshot, no `-wal`, and `rdfgen.TrackToRdf` never checks `rows.Err()`). Under write load (migration / playback tag writes) it produces a truncated or **track-less** export and reports success. Happened 2026-05-28 23:47 right after the 1.0.60 (#270) restart copied the DB during the post-migration write spike (768KB / 0 tracks vs 16.9MB / 14,707).

**Landmine 2 — arachne ingest deletes on diff (no shrink guard):** if a source's export collapses to near-empty AND parses without error, the ingest's cleanup step **deletes everything not in the export** — wiping all 14,707 media tracks from triplestore + search index. There is NO "source shrank by >X%" guard. So: **never re-run arachne ingestion against a possibly-broken export** — verify `/v2/export` has tracks first (`grep -c "/tracks/"`).

**Interaction (important):** an **empty** export → no skos:Concept subjects → searchindex "succeeds" → cleanup runs → WIPE. A **complete** export → hits [[pattern_arachne_preflabel_makes_indexable]] (#271 skos:Concept) → searchindex FAILS → cleanup SKIPPED → no wipe but no clean ingest. The two bugs fail in opposite directions at 04:15. **UPDATE 2026-05-29: #271 is FIXED — shipped as lucos_arachne#591 / PR #592 (merged 00:47Z; adds the SKOS namespace to `META_NAMESPACES`, excludes skos:Concept/ConceptScheme). A complete export's searchindex step now succeeds and cleanup runs normally — the "complete export → searchindex FAILS" arm no longer applies. Runtime-confirmed 2026-05-29: a searchindex walk over a SKOS-containing export logged zero SKOS errors. Only #272 (torn-export) remains open, so the residual risk is now just "torn/empty export → wipe", which the track-count gate defends against.**

**How to apply:** until #272 ships (the torn-export bug — #271 is now fixed, see above), treat the 04:15 arachne media ingest as risky. Before any manual arachne re-ingest, confirm the served export is complete. The exporter copy bug means a "green" `exporter` schedule check does NOT prove the export has data — check track count, not just freshness/success.

**Pre-trigger safety gate — no irreversible action on corrupted/untrustworthy reads:** both the export regenerate (#272 torn-export) and the ingest (wipe-on-diff, no shrink guard) are irreversible-capable. Only pull either trigger when the tool output you are reading back *in that moment* is trustworthy; if reads are in a corrupted/garbled/laggy window, PAUSE and flag rather than act on a doubtful read — the same discipline applied to production DB migrations applies here. Always gate the ingest on a fresh, clean read of the served export's track count (`grep -c '/tracks/'` == 14707) taken immediately beforehand. (2026-05-29: the premature `docker restart` above happened precisely because I acted on a corrupted read before this runbook was in hand.)

**Decision (2026-05-29, lucas42):** the 04:15 wipe risk was **accepted for the night, no cron change** — #272 is a long-standing latent bug only manifesting under write contention (normal overnight). I had briefly paused the arachne `15 04` ingest cron as a precaution, then **reverted it per lucas42's call** — both crons are back to normal. #271 (search-index failures) is the higher priority and was routed to the architect for the source-side-vs-arachne-side design decision; the shrink-guard defense-in-depth folds into that discussion. Don't re-propose pausing crons for this — the team chose to accept the risk and fix forward. **(#271 subsequently shipped as lucos_arachne#592, merged 2026-05-29 00:47Z — resolved. The shrink-guard for #272 is still the open defense-in-depth item.)**
