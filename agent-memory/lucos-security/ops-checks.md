# Ops Checks Tracking

Track when each periodic ops check was last run. Update this file after completing each check.

Format: `check_name: YYYY-MM-DD`

A check is due if there is no entry for it, or if elapsed time since last_run >= the check's frequency.

## Every-run checks

| Check | Last run |
|---|---|
| dependabot-alerts | 2026-10-09 |
| codeql-secret-scanning | 2026-10-09 |
<!-- last updated: 2026-10-02 — 29 dependabot alerts (13 lucos_contacts, 16 lucos_eolas), all PyJWT 2.13.0 batch published 2026-10-01 (+3 stale urllib3 on eolas, lock already 2.8.0). Filed one issue per repo (deviation from one-per-alert; same fix): lucos_contacts#818, lucos_eolas#362. eolas dependabot pip job failing 'Expected Pipfile.lock to change' (certifi). CodeQL: same 3 alerts, no new; 0 secret-scanning. Prior: 2026-09-27 — 0 open dependabot alerts. 3 codeql alerts same as prior runs, still tracked by open issues (lucas42/lucos_contacts#771, lucas42/lucos_contacts_googlesync_import#218, lucas42/lucos_media_metadata_api#325, all re-confirmed open via direct issue fetch). 1 NEW codeql alert: lucos_media_seinn js/stored-xss on tests/web-components.js:82 — investigated, confirmed false positive (document.createElement(tag) fed from local dir listing + regex, test-only file), filed + closed lucas42/lucos_media_seinn#636, dismissed the alert. 0 secret-scanning. -->

## Monthly checks

| Check | Last run |
|---|---|
| codeql-coverage | 2026-10-06 |
| github-actions-audit | 2026-10-06 |
<!-- last updated: 2026-09-06 — Check 3: every non-fork active repo with a CodeQL-supported primary language already has a CodeQL workflow (checked all Go/Python/JS-TS/Java/Kotlin/Ruby repos); no gaps. Check 4: audited all 217 workflow files across 60 non-fork active repos (via raw.githubusercontent) — zero genuinely third-party `uses:` refs (only self-referencing lucas42/.github reusable workflows, org-owned not third-party); every workflow declares a `permissions:` key (top-level or job-level); no pull_request_target triggers except the well-designed reusable-dependabot-auto-merge.yml (secrets only flow to a GitHub-owned, SHA-pinned action, never to PR-head code). No findings, no issues raised. Not due again until ~2026-10-06. -->

<!-- 2026-10-06 run: same 29 dependabot alerts (PyJWT/urllib3 on contacts+eolas), tracked by lucos_contacts#818 / lucos_eolas#362 (open); 3 codeql alerts unchanged, tracked; 0 secret-scanning. Check 3: 63 non-fork repos, all supported-language repos have CodeQL, no gaps. Check 4: 216 workflow files in 61 repos, no third-party uses refs (only lucas42/.github reusables, one pinned by SHA), all declare permissions, only pull_request_target is the reusable auto-merge. No findings. Next monthly due ~2026-11-06. -->

<!-- 2026-10-09 run: 32 dependabot alerts (contacts 14 PyJWT, eolas 13 PyJWT+3 urllib3, tracked by lucos_contacts#818/lucos_eolas#362 open); 2 NEW sprintf-js (GHSA-hp3w-g68c-fv3c, medium, dev-scope, no patch) on lucos_notes + tfluke — auto-resolvable rule, no issue, report only. 3 codeql unchanged/tracked, 0 secret-scanning. Checks 3/4 not due (last 2026-10-06). -->
