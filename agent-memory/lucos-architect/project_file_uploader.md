---
name: file-uploader
description: Initial design framing for lucas42/lucos#209 — stateless one-stop file uploader; forward design, ideation, awaiting lucas42's answers before ADR
metadata:
  type: project
---

# LucOS File Uploader (lucas42/lucos#209)

Initial design framing posted 2026-06-02 (comment on #209). Ideation — not committed to build. Forward design; ADR follows once lucas42 answers the open product questions.

**Three-tier responsibility model:**
- **Browser** = stateful coordinator (holds the upload session: file list, per-file metadata, progress, retry). State lives here.
- **Uploader service** = stateless transform + route (decompress/extract archives, route each file + metadata to the correct backend, return per-file result). No durable state; bounded transient working space only.
- **Backends** = durable store + metadata validation + permissions.

**Why:** "stateless" means no durable store, not "no transient working space." Statelessness gives a clean reliability story (browser holds the truth, re-drives on failure) — the discipline to protect is keeping the uploader thin so it doesn't become a coupling hub.

**Central crux — backend plugin model:** recommend **uniform ingest contract** (each backend exposes a standard ingest endpoint + declares its own metadata schema) over adapter-plugins-in-the-uploader. Under the contract, the UI "folders" (discrete-metadata selectors) are *backend-declared* → new upload types are config/registration, not uploader code. Matches estate's one-system-owns-its-domain grain.

**Heterogeneous backends:** lucos_photos is HTTP (ingest endpoint natural); music + documents are NAS filesystem drops (scanned by lucos_media_import / served by lucos_private). Resolution: filesystem-backed backends satisfy the contract via a thin ingest endpoint owned by the storage owner.

**Bandcamp 700-perm fix location:** at the NAS-write boundary, in the ingest endpoint — NOT the uploader (uploader must never know serving user/group). Likely moot by construction: uploader extracts archive and forwards constituent files (with relative-path metadata), so dirs are created fresh by the ingest endpoint under its own umask.

**Metadata is two-tiered:** discrete/per-folder (provenance, category — chosen by drag-into-folder) + free/per-file (photo date-taken, reverse notes). Contract must carry per-file metadata.

**Security (design-in, not bolt-on):** archive extraction = zip-slip/path-traversal + zip-bomb surface (sanitise paths, bound expansion, stream, temp budget+cleanup). Plus auth.

**#132 tie-in:** uploader is BOTH a human-auth consumer (login to use) AND a machine principal to backends (deposits files server-side) → natural [[machine-principal-sessions]] consumer. Open product Q: attribute deposited files to lucas42's contact ID or a service account?

**Open questions to lucas42 (on ticket, awaiting answers):** (1) define-of-done for async backends (music→NAS scanned later); (2) attribution; (3) partial-batch + retry-failures model; (4) server-side vs client-side extraction (I recommend server); (5) extensibility = config/registration not code (confirm); (6) dedup is backend's job (eolas 409 precedent).

**How to apply:** when lucas42 answers, write the ADR (context/decision/consequences) and scope the build — the bulk of real work is which backends need a new ingest endpoint.
