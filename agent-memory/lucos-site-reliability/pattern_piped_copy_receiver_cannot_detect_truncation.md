---
name: pattern-piped-copy-receiver-cannot-detect-truncation
description: In `ssh A 'dump' | ssh B 'cat > x.part && mv x.part x'` the receiver can't see a sender failure — the atomic rename publishes a truncated/empty file as complete
metadata:
  type: feedback
---

**In a piped copy, the receiving end cannot tell a dropped sender from a normal end of stream.** `ssh A 'pg_dumpall | gzip' | ssh B 'cat > x.part && mv x.part x'`: when A dies, B's `cat` sees EOF, exits 0, and the "atomic" rename publishes a truncated file under its final name. **The rename only protects against the receiver dying, not the sender.**

**Why:** 2026-09-14, emergency copies off failing avalon (lucas42/lucos#294). The contacts dump dropped after 58 min with 0 bytes, and xwing was left with a **0-byte file under the final name**. Same for an earlier failed aithne attempt. My script's own log said FAILED, because the local `pipefail` saw the sender's status, but the artefact on disk lied. I caught it only because I listed the directory to size the partial file.

**How to apply:** do the rename in a *separate* step after checking the local pipeline status (`if pipeline; then ssh B mv …; fi`). Or verify content on the receiver (`gzip -t`, a trailer or checksum sent after the data). Then list the destination and treat a 0-byte or undersized "final" file as a failure. Don't edit a bash script while it's running to fix this: bash reads scripts incrementally. Fix a copy. Related: [[pattern-reconcile-silent-success-masking]].
