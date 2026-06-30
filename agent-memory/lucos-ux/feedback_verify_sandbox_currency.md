---
name: verify-sandbox-currency
description: Check git log HEAD..origin/main before filing cross-repo bugs based on local sandbox code reads
metadata:
  type: feedback
---

Verify sandboxes are current before filing issues based on local code reads.

**Why:** In the aithne post-migration review (2026-06-30), four false-positive issues were filed against lucos_loganne, lucos_notes, lucos_creds, and lucos_media_metadata_manager based on `~/sandboxes` checkouts that were ~2 weeks stale. The consumer auth migration had already landed on origin/main. All four issues were closed after team-lead probed the live services.

**How to apply:** When filing any finding about what code a service runs (still-calls-X, not-migrated, broken), verify against `origin/main` — not just the local checkout. A local grep is not sufficient evidence:

```bash
git -C ~/sandboxes/{repo} fetch -q
git -C ~/sandboxes/{repo} grep "pattern" origin/main -- path/to/file
```

If absent on origin/main, don't file. If fetching is impractical, hedge explicitly rather than stating as fact. Applies during any cross-repo review.

The instruction fix is in the "Proactive UX Reviews" section of `~/.claude/agents/lucos-ux.md`.
