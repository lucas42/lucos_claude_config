---
name: pattern-arachne-eolas-dual-ingest-hyphen-pk
description: arachne has TWO eolas ingest paths (real-time webhook + daily bulk); hyphenated eolas pks silently fail the webhook path. Plus how to query the triplestore / run ad-hoc ingest.
metadata:
  type: project
---

# arachne↔eolas ingest: dual path + hyphenated-pk bug + diagnostic mechanics

**Fact (2026-06-30):** A new language "Ewokese" (`art-x-ewok`) was absent from arachne (zero triples, not in search). Root cause = **eolas** `app/lucos_eolas/urls.py` content-neg entrypoint `re_path(r'^metadata/(?P<type>[a-z]+)/(?P<pk>(?!add)\w+)/$', thing_entrypoint)`: `\w+` excludes hyphens → hyphenated pks (`art-x-*` constructed-lang codes) don't match → fall through to `path('', admin.urls)` → admin `login_required` → `302 /login/`. arachne's per-item webhook fetch then gets HTML not RDF → `ValueError: Expected RDF... got text/html`. The `/data/` route uses `<slug:pk>` (hyphens OK) so data endpoint is fine — only the redirect breaks. Tracked: lucos_eolas#329 (fix = `[\w-]+`). 

**Why:** Two ingest paths, and the bulk one masks per-item failures:
- **Per-item webhook** (`lucos_arachne_ingestor` server.py) — fires on eolas `itemCreated` Loganne event, fetches the single entity's content-neg entrypoint URL. BROKEN for hyphenated pks (always was).
- **Daily bulk** (`ingest.py`, cron `15 04 * * *` + at startup) — fetches full dump `https://eolas.l42.eu/metadata/all/data/` which serves ALL entities regardless of pk shape; diff-ingests. This is why Na'vi/Simlish (also `art-x-*`) ARE present — bulk backfilled them. A newly-created hyphenated entity stays missing until the next successful bulk reconcile.

**How to apply / diagnostic mechanics (reuse for any arachne/eolas ingest gap):**
- Discriminator test: fetch `/metadata/<type>/<pk>/` with `Accept: application/rdf+xml` + bearer `KEY_LUCOS_EOLAS`, `allow_redirects=False`. Healthy = `303 → …/data/`; broken = `302 → /login/`.
- Query the triplestore: from `lucos_arachne_ingestor`, SPARQL POST to `http://triplestore:3030/{raw_arachne|arachne}/sparql` (raw = as-ingested; `arachne` = OWL-inferred). **Auth = HTTP Basic `lucos_arachne:$KEY_LUCOS_ARACHNE`** (NOT bearer — bearer gives 401). eolas data lives in named graph `https://eolas.l42.eu/metadata/all/data/`; query `GRAPH ?g {...}`. Source-content hash stored in METADATA_GRAPH under LAST_PAYLOAD_HASH_PRED; live≠stored ⇒ bulk would NOT skip.
- Ingestor base `python3` lacks `requests` (ModuleNotFoundError). Use `docker exec -w /home/jobrunner lucos_arachne_ingestor pipenv --quiet run python …`. `from authorised_fetch import fetch_url` / `from triplestore import diff_graph_in_triplestore, get_source_hash` are read-only-safe for diagnosis (diff just CONSTRUCTs + set-diffs, returns a fragment string).
- Ad-hoc bulk ingest to remediate (idempotent, diff-based, = nightly job): `docker exec -w /home/jobrunner lucos_arachne_ingestor pipenv --quiet run python -u ingest.py` (send Loganne plannedMaintenance first). Reconciles all 4 live_systems (eolas, contacts, media_metadata_api, configy). Verify via `search` MCP + raw-graph SPARQL.
