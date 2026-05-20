---
name: codeql-false-positive-policy
description: lucas42's stated policy for resolving CodeQL false positives — GHAS dismissal only, no inline suppression or config exclusions
metadata:
  type: feedback
---

## CodeQL False Positive Resolution: GHAS Dismissal Only (with caveats)

**Lucas42's stated preference (2026-05-20):** GHAS alert dismissal is the **primary** mechanism for CodeQL false positives. Inline suppression comments are also non-functional in lucos repos (code-reviewer verified empirically on PR #460 with four failed commits).

**How to apply:** When a CodeQL alert is confirmed to be a false positive, dismiss it directly via the API (see [[codeql-dismissal-capability]]). `lucos-security[bot]` has this permission — no need to route to lucas42.

**Important: dismissal whack-a-mole problem.** CodeQL fingerprints alerts by code location (file + line range + snippet). When line numbers shift between commits (e.g., due to insertions/deletions elsewhere in the file), a new alert instance is created at the new location — the old dismissal doesn't apply. This makes dismissal-only an ongoing maintenance burden for false positives in actively-edited files.

**`query-filters` (rule-scoped) vs `paths-ignore` (blanket) — critical distinction:**
- `paths-ignore: tests/**` = blanket exclusion of ALL CodeQL rules from test files. This IS silent security debt — real SQL injection, command injection etc. in test code would be suppressed.
- `query-filters: exclude: id: js/stored-xss, paths: tests/**` = rule-scoped exclusion. Only that specific rule is suppressed; all other rules still run on test files. This is NOT silent security debt and is a defensible durable fix for false positives that recur due to line-shift churn.

For persistent false positives in frequently-edited files, the `query-filters` approach is the more practical long-term solution. This is lucas42's call to make (it's a workflow config change), but the security concern with blanket `tests/**` only applies to `paths-ignore`, not to rule-scoped `query-filters`.

Note: the earlier claim that "dismissals must be by lucas42" was an unverified assumption — it was wrong. Always verify permission claims by probing the API rather than guessing.
