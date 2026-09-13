# Ops Checks Tracking

Track when each periodic ops check was last run. Update this file after completing each check.

Format: `check_name: YYYY-MM-DD`

A check is due if there is no entry for it, or if elapsed time since last_run >= the check's frequency.

## Every-run checks

| Check | Last run |
|---|---|
| dependabot-alerts | 2026-09-13 |
| codeql-secret-scanning | 2026-09-13 |
<!-- last updated: 2026-09-13 — tfluke#61 (js-yaml maxTotalMergeKeys CPU-DoS, CVE-2026-84375/GHSA-2883-xcg3-v3hh, high, transitive devDependency via supertap+tap-xunit→tap-parser, both resolving to vulnerable 3.15.1): no PR from Dependabot since it needed a manual override for a nested transitive dep (same pattern as the repo's existing webpack-cli override) — added overrides pinning both paths to js-yaml >=3.15.2 <4.0.0, verified 0 npm-audit vulns + 51/51 tests pass, opened tfluke#528 (lockfileVersion kept at 2 to avoid npm10-default-v3 format churn — see risk-npm-lockfile-version-drift.md); PR body initially misused bare-but-qualified `lucas42/tfluke#61` for the alert number (see feedback-alert-ref-self-check.md), code-reviewer caught it, fixed body-only, re-reviewed and APPROVED; lucas42 still in requested_reviewers (supervised, no CHANGES_REQUESTED), awaiting his review to merge. Same 3 codeql alerts as last run, still tracked by open issues (contacts#771, googlesync_import#218, media_metadata_api#325, all re-confirmed open), 0 secret-scanning -->

## Monthly checks

| Check | Last run |
|---|---|
| codeql-coverage | 2026-09-06 |
| github-actions-audit | 2026-09-06 |
<!-- last updated: 2026-09-06 — Check 3: every non-fork active repo with a CodeQL-supported primary language already has a CodeQL workflow (checked all Go/Python/JS-TS/Java/Kotlin/Ruby repos); no gaps. Check 4: audited all 217 workflow files across 60 non-fork active repos (via raw.githubusercontent) — zero genuinely third-party `uses:` refs (only self-referencing lucas42/.github reusable workflows, org-owned not third-party); every workflow declares a `permissions:` key (top-level or job-level); no pull_request_target triggers except the well-designed reusable-dependabot-auto-merge.yml (secrets only flow to a GitHub-owned, SHA-pinned action, never to PR-head code). No findings, no issues raised. Not due again until ~2026-10-06. -->
