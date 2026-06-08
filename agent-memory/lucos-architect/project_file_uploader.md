---
name: file-uploader
description: lucas42/lucos#209 LucOS File Uploader — ADR-0013 written (draft PR #235); stateless 3-tier uploader + uniform backend ingest contract; all 6 product Qs answered
metadata:
  type: project
---

# LucOS File Uploader (lucas42/lucos#209) — ADR-0013 drafted

lucas42 answered all 6 product/one-way-door questions 2026-06-08. ADR-0013 written and opened as **draft PR lucas42/lucos#235** (lucos is unsupervised → draft to block auto-merge; pinged @lucas42; mark ready only after sign-off). Status in ADR = Proposed until merge.

**Architecture (decided):**
- **Three tiers:** browser = stateful coordinator (holds upload session/retry); uploader = stateless transform+route (server-side archive extraction, route per-file+metadata to backend); backends = durable store + schema validation + permissions + dedup.
- **Uniform ingest contract** (NOT adapter-plugins-in-uploader): each backend exposes a standard ingest endpoint AND **owns + advertises its own metadata schema** from a dedicated discovery endpoint. UI "folders" are backend-declared discrete fields → new upload types / metadata values = config/backend-side, never uploader code.
- **Schema location (lucas42 left to me):** backend-owned-and-advertised on a dedicated endpoint. Explicitly NOT YAML-in-uploader (re-couples) NOR configy (wrong grain). Closest to his "/_info" idea but a separate functional endpoint (keep monitoring vs functional contract apart). Uploader holds only a thin registry of backend ingest URLs.

**lucas42's 6 answers, folded in:**
1. "Done" = handed-off, not fully-ingested; backends log full-ingest to loganne for user to verify. Async ingest endpoints follow lucos ADR-0006 (accept-202-enqueue).
2. Attribution = via logs (which user, which system), NOT a stored DB column. So no contact-ID provenance column in backends.
3. Batch = partial-success + browser-driven retry-of-failures.
4. Extraction = server-side.
5. Extensibility = ingestion schema; config location not fussy.
6. Dedup = backend's job (eolas 409 precedent); uploader surfaces "duplicate" gracefully.

**Heterogeneous backends + Bandcamp perm fix:** filesystem backends satisfy the contract via a thin ingest endpoint owned by the storage owner. Perm fix (700→770) lives at the NAS-write boundary inside that endpoint — likely moot by construction (uploader forwards extracted constituent files; ingest endpoint creates dirs fresh under its own umask). `lucos_media_import` is the big build cost (a scanner with NO HTTP surface today). `lucos_private` already serves HTTP. `lucos_photos POST /photos` needs *conforming*, not building.

**Security:** server-side extraction concentrates zip-slip/zip-bomb surface in the uploader (design-in). Uploader is a machine principal to backends → [[machine-principal-sessions]] (#132) consumer; uses signed+scoped session, ingest scope only.

**Deferred build tickets (enumerated in ADR Follow-up, NOT raised yet — ADR-0006 precedent, raise on ADR acceptance):** (1) create lucos_file_uploader [new repo, raised on lucos]; (2) lucos_photos conform; (3) lucos_media_import ingest endpoint + perm fix; (4) lucos_private documents ingest. Items 2-4 downstream of 1 defining wire format. **How to apply:** when ADR-0013 merges, raise these 4 and hand URLs to coordinator.
