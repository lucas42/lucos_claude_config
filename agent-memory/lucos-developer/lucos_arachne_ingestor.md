---
name: lucos-arachne-ingestor
description: Entry points, triplestore helpers, skolemisation, and diff-path notes for lucos_arachne's ingestor
metadata:
  type: project
---

- **Entry**: `ingestor/ingest.py`. Tests: `python3 -m pytest` in `ingestor/`. All 117 pass.
- **Triplestore helpers**: `ingestor/triplestore.py`. `rdflib` already in Pipfile.
- **Skolemisation**: `ingestor/skolemise.py`. Blank nodes → `urn:lucos:skolem:<sha256>` (tree-shaped hash, cycle detection → UUID fallback).
- **Diff path** (PR #439, Option 2): `diff_graph_in_triplestore()` returns SPARQL Update fragment. Migration case (old graph has bnodes) uses `DELETE WHERE + INSERT DATA`. Phase 1 collects all live-source fragments, executes as one SPARQL Update. Ontologies keep `replace_graph_in_triplestore`.
- **loc_mads.rdf** doesn't parse with rdflib (invalid RDF/XML) — don't apply diff path to ontologies.
- **`COPY *.py .`** in Dockerfile covers all new `.py` files in `ingestor/`.
