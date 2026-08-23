---
name: lucos-claude-config-138-drift-attribution-timing
description: RESOLVED — return-to-main.sh's drift attribution no longer points at syncFailurePersisted unless it's actually fired
metadata:
  type: project
---

lucas42/lucos_claude_config#138, filed 2026-08-20 from a lucos-code-reviewer review note on PR #136 (#131's implementation). **Resolved 2026-08-23, PR #146 merged (`1302688`).**

Fix direction settled as gating the wording, not adding per-path clocks: `check_persistent_dirt`'s drift attribution only appends `"(see syncFailurePersisted)"` when `SYNC_FAIL_ALERTED_FILE` already exists (i.e. `track_sync_failure`'s own event has actually fired for this episode); otherwise the same "drift" attribution with no dangling event-name pointer. No new state, no new clock — the two independent-clock tracks (dirt vs. sync-failure) stay independent.

**Reusable pattern for similar future tickets:** when two tracked conditions share a timing window but run independent clocks, and one's message cross-references the other's event name, gate the cross-reference on the referenced event's own alerted-marker file rather than inferring it from the shared window's elapsed time.
