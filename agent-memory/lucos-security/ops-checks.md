# Ops Checks Tracking

Track when each periodic ops check was last run. Update this file after completing each check.

Format: `check_name: YYYY-MM-DD`

A check is due if there is no entry for it, or if elapsed time since last_run >= the check's frequency.

## Every-run checks

| Check | Last run |
|---|---|
| dependabot-alerts | 2026-09-08 |
| codeql-secret-scanning | 2026-09-08 |
<!-- last updated: 2026-09-08 — same lucos_arachne#25 (decode-uri-component DoS) alert, already fixed via open PR #823 (npm override) from 2026-09-06 run; belatedly sent lucos-code-reviewer the review request this run (missed doing so on 2026-09-06 — pr-review-loop.md requires it regardless of trigger), now in the review loop. Same 3 codeql alerts as last run, still tracked by open issues (contacts#771, googlesync_import#218, media_metadata_api#325, all confirmed open), 0 secret-scanning -->

## Monthly checks

| Check | Last run |
|---|---|
| codeql-coverage | 2026-09-06 |
| github-actions-audit | 2026-09-06 |
<!-- last updated: 2026-09-06 — Check 3: every non-fork active repo with a CodeQL-supported primary language already has a CodeQL workflow (checked all Go/Python/JS-TS/Java/Kotlin/Ruby repos); no gaps. Check 4: audited all 217 workflow files across 60 non-fork active repos (via raw.githubusercontent) — zero genuinely third-party `uses:` refs (only self-referencing lucas42/.github reusable workflows, org-owned not third-party); every workflow declares a `permissions:` key (top-level or job-level); no pull_request_target triggers except the well-designed reusable-dependabot-auto-merge.yml (secrets only flow to a GitHub-owned, SHA-pinned action, never to PR-head code). No findings, no issues raised. -->
