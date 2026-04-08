---
name: Verify Dockerfile COPY when adding new files
description: When adding new files/directories to a Dockerised service, always check the Dockerfile covers them
type: feedback
---

When adding new files or directories to a service that runs in Docker, read the Dockerfile and verify the new path is covered by a `COPY` instruction before committing.

**Why:** PR #267 added `ingestor/ontologies/` but the ingestor Dockerfile only had `COPY *.py .` — the ontology directory was silently absent from the image, causing all 11 ontology ingestions to fail. SRE fixed it in PR #282.

**How to apply:** Any time you create a new directory or non-Python/non-JS file inside a Dockerised service directory, open the Dockerfile and confirm there's a COPY that covers it. `COPY *.py .` misses subdirectories; `COPY . .` covers everything. Add or update the COPY line if needed.
