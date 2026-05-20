---
name: codeql-false-positive-policy
description: lucas42's stated policy for resolving CodeQL false positives — GHAS dismissal only, no inline suppression or config exclusions
metadata:
  type: feedback
---

## CodeQL False Positive Resolution: GHAS Dismissal Only

**Lucas42's stated preference (2026-05-20):** GHAS alert dismissal is the **only** mechanism to use for CodeQL false positives. Do not use:

- Inline suppression comments (`// codeql[js/stored-xss]`) — also confirmed non-functional in lucos repos (code-reviewer verified empirically on PR #460 with four failed commits).
- `.github/codeql-config.yml` file-level or directory-level `paths-ignore` exclusions.

**Why:** Lucas42 prefers the dismissal audit trail in GitHub Advanced Security over in-code annotations or config exclusions. Each false positive gets a per-alert conscious decision recorded in the security tab.

**How to apply:** When a CodeQL alert is confirmed to be a false positive, dismiss it directly via the API (see [[codeql-dismissal-capability]]). Do not propose inline suppression or config exclusions as alternatives.

**Confirmed that `lucos-security[bot]` can do this autonomously** — `security_events: write` is granted. No need to route false-positive dismissals to lucas42 unless permission is revoked.

Note: the earlier claim that "dismissals must be by lucas42" was an unverified assumption — it was wrong. Always verify permission claims by probing the API rather than guessing.
