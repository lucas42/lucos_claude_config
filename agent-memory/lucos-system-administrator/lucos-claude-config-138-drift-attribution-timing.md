---
name: lucos-claude-config-138-drift-attribution-timing
description: Open follow-up — return-to-main.sh's "drift" Loganne message can reference syncFailurePersisted before that event has fired (two independent clocks, shared window)
metadata:
  type: project
---

lucas42/lucos_claude_config#138, filed 2026-08-20 from a lucos-code-reviewer review note on PR #136 (#131's implementation). Not urgent — explicitly non-blocking, attribution is still directionally correct ("drift" is the right call), just an occasionally-premature cross-reference to a specific event name that might never fire if the sync self-heals fast. Two fix directions named, neither decided: per-path clocks (more precise, more complex) vs. gating the "(see syncFailurePersisted)" wording on that track's own alerted-state marker already existing (smaller, keeps tracks independent). Whoever picks this up should read the full issue body before choosing — the acceptance criterion is written to be direction-agnostic.
