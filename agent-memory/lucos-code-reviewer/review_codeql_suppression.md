---
name: review-codeql-suppression
description: For CodeQL false positives, recommend the config-file exclusion or Security-UI dismissal, not inline // codeql[] comments — inline suppression needs specific action config and silently does nothing otherwise.
metadata:
  type: feedback
---

Preferred fixes, in order: (1) `.github/codeql/codeql-config.yml` query-filter exclusion for the affected path/query, (2) dismiss the alert via the GitHub Security UI, (3) refactor to remove the taint path entirely.

Inline `// codeql[query-id]` comments require the repo's CodeQL action to have inline-suppression support configured — without it, they silently do nothing. Confirmed: 4 attempts (preceding-line and same-line) on lucos_media_seinn PR #460 all failed silently; the action's post-processing only added fingerprints, no suppression-comment processing occurred at all.
