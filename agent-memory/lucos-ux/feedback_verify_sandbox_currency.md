---
name: verify-sandbox-currency
description: Check git log HEAD..origin/main before filing cross-repo bugs based on local sandbox code reads
metadata:
  type: feedback
---

Verify sandboxes are current before filing issues based on local code reads.

**Why:** In the aithne post-migration review (2026-06-30), four false-positive issues were filed against lucos_loganne, lucos_notes, lucos_creds, and lucos_media_metadata_manager based on `~/sandboxes` checkouts that were ~2 weeks stale. The consumer auth migration had already landed on origin/main. All four issues were closed after team-lead probed the live services.

**How to apply:** Before asserting that a sandboxed repo has a bug or stale reference, run:

```bash
git -C ~/sandboxes/{repo} log HEAD..origin/main --oneline
```

If the output is non-empty, the checkout is stale. Either fetch first or hedge the finding explicitly. This applies during any cross-repo review — proactive, post-migration, or triage consultation.

The instruction fix is in the "Proactive UX Reviews" section of `~/.claude/agents/lucos-ux.md`.
