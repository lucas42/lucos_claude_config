# Ops Checks Tracking

Track when each periodic ops check was last run. Update this file after completing each check.

Format: `check_name: YYYY-MM-DD`

A check is due if there is no entry for it, or if elapsed time since last_run >= the check's frequency.

## Every-run checks

| Check | Last run |
|---|---|
| dependabot-alerts | 2026-11-12 |
| codeql-secret-scanning | 2026-11-12 |
<!-- last updated: 2026-10-02 — 29 dependabot alerts (13 lucos_contacts, 16 lucos_eolas), all PyJWT 2.13.0 batch published 2026-10-01 (+3 stale urllib3 on eolas, lock already 2.8.0). Filed one issue per repo (deviation from one-per-alert; same fix): lucos_contacts#818, lucos_eolas#362. eolas dependabot pip job failing 'Expected Pipfile.lock to change' (certifi). CodeQL: same 3 alerts, no new; 0 secret-scanning. Prior: 2026-09-27 — 0 open dependabot alerts. 3 codeql alerts same as prior runs, still tracked by open issues (lucas42/lucos_contacts#771, lucas42/lucos_contacts_googlesync_import#218, lucas42/lucos_media_metadata_api#325, all re-confirmed open via direct issue fetch). 1 NEW codeql alert: lucos_media_seinn js/stored-xss on tests/web-components.js:82 — investigated, confirmed false positive (document.createElement(tag) fed from local dir listing + regex, test-only file), filed + closed lucas42/lucos_media_seinn#636, dismissed the alert. 0 secret-scanning. -->

## Monthly checks

| Check | Last run |
|---|---|
| codeql-coverage | 2026-11-06 |
| github-actions-audit | 2026-11-06 |
<!-- last updated: 2026-09-06 — Check 3: every non-fork active repo with a CodeQL-supported primary language already has a CodeQL workflow (checked all Go/Python/JS-TS/Java/Kotlin/Ruby repos); no gaps. Check 4: audited all 217 workflow files across 60 non-fork active repos (via raw.githubusercontent) — zero genuinely third-party `uses:` refs (only self-referencing lucas42/.github reusable workflows, org-owned not third-party); every workflow declares a `permissions:` key (top-level or job-level); no pull_request_target triggers except the well-designed reusable-dependabot-auto-merge.yml (secrets only flow to a GitHub-owned, SHA-pinned action, never to PR-head code). No findings, no issues raised. Not due again until ~2026-10-06. -->

<!-- 2026-10-06 run: same 29 dependabot alerts (PyJWT/urllib3 on contacts+eolas), tracked by lucos_contacts#818 / lucos_eolas#362 (open); 3 codeql alerts unchanged, tracked; 0 secret-scanning. Check 3: 63 non-fork repos, all supported-language repos have CodeQL, no gaps. Check 4: 216 workflow files in 61 repos, no third-party uses refs (only lucas42/.github reusables, one pinned by SHA), all declare permissions, only pull_request_target is the reusable auto-merge. No findings. Next monthly due ~2026-11-06. -->

<!-- 2026-10-09 run: 32 dependabot alerts (contacts 14 PyJWT, eolas 13 PyJWT+3 urllib3, tracked by lucos_contacts#818/lucos_eolas#362 open); 2 NEW sprintf-js (GHSA-hp3w-g68c-fv3c, medium, dev-scope, no patch) on lucos_notes + tfluke — auto-resolvable rule, no issue, report only. 3 codeql unchanged/tracked, 0 secret-scanning. Checks 3/4 not due (last 2026-10-06). -->

<!-- 2026-10-13 run: PyJWT alerts all cleared (fixed 2026-10-11). 5 dependabot alerts: eolas 3 urllib3 (develop section of app/Pipfile.lock still 2.7.0, default 2.8.0) -> filed lucas42/lucos_eolas#367; sprintf-js on lucos_notes + tfluke (medium, no patch, auto-resolvable, no issue). 3 codeql unchanged/tracked, 0 secret-scanning. Checks 3/4 not due (last 2026-10-06). -->

<!-- 2026-10-15 run: identical to 10-13 — 5 dependabot alerts (eolas 3 urllib3 -> lucos_eolas#367 open; sprintf-js notes+tfluke auto-resolvable, no issue). 3 codeql unchanged, tracked by open issues. 0 secret-scanning. Checks 3/4 not due (last 2026-10-06). -->

<!-- 2026-10-17 run: identical to 10-15 — 5 dependabot alerts (eolas 3 urllib3 -> lucos_eolas#367; sprintf-js notes+tfluke auto-resolvable, no issue). 3 codeql unchanged, tracked. 0 secret-scanning. Checks 3/4 not due (last 2026-10-06). -->

<!-- 2026-10-18 run: eolas urllib3 cleared (lucos_eolas#367 closed completed). 2 dependabot alerts left: sprintf-js on notes + tfluke (medium, no patch, auto-resolvable, no issue). 3 codeql unchanged, tracked by open issues. 0 secret-scanning. Checks 3/4 not due (last 2026-10-06). -->

<!-- 2026-10-23 run: sprintf-js alerts gone. 1 NEW dependabot alert: lucos_eolas certifi GHSA-6q48-6c7w-9gw2 (critical; develop section of Pipfile.lock still 2026.6.17, default already fixed by merged dependabot PR 372). Opened workaround PR lucas42/lucos_eolas#374 (lucos-code-reviewer messaged, lucas42 requested). 3 codeql unchanged, tracked (contacts#771, googlesync_import#218, media_metadata_api#325). 0 secret-scanning. Checks 3/4 not due (last 2026-10-06). -->

<!-- 2026-10-28 run: eolas certifi cleared. 4 NEW dependabot alerts: deepmerge GHSA-gcqx-w48m-w2h4 (low, dev-scope, no patch) on arachne/loganne/notes/search_component — auto-resolvable, no issue. 3 codeql unchanged/tracked, 0 secret-scanning. Checks 3/4 not due (last 2026-10-06). -->

<!-- 2026-11-01 run: identical to 10-28 — 4 deepmerge GHSA-gcqx-w48m-w2h4 (low, dev-scope, no patch) on arachne/loganne/notes/search_component, auto-resolvable, no issue. 3 codeql unchanged/tracked, 0 secret-scanning. Checks 3/4 not due (last 2026-10-06; due ~2026-11-06). -->

<!-- 2026-11-06 run: all 4 checks. 10 dependabot alerts: minimatch GHSA-g3hv-75wg-m249 reappeared on 5 repos (arachne, creds, loganne, media_seinn, notes; dev-scope, parent-capped; no issue per the preamble rule) + 5 deepmerge (low, no patch). 3 codeql unchanged/tracked, 0 secret-scanning. Check 3: 65 non-fork repos (GraphQL, totalCount==nodes, no next page); every supported-language primary repo has CodeQL; no gaps. Check 4: 203 workflow files in 65 repos fetched; non-GitHub uses refs are only lucas42/.github reusables (org-owned); github/codeql-action mostly tag-pinned (GitHub-owned, out of scope); all files declare permissions; workflow_run only in codeql files; no pull_request_target. No findings. Next monthly due ~2026-12-06. -->

<!-- 2026-11-05 run: minimatch alerts all cleared. 5 dependabot alerts, all deepmerge GHSA-gcqx-w48m-w2h4 (low, dev-scope, no patch) on arachne/loganne/notes/search_component + NEW time_component; auto-resolvable, no issue. 3 codeql unchanged, tracked (contacts#771, googlesync_import#218, media_metadata_api#325 all open, re-fetched). 0 secret-scanning. Checks 3/4 not due (last 2026-10-06; due 2026-11-06). -->

<!-- 2026-11-03 run: 13 dependabot alerts. NEW: minimatch GHSA-g3hv-75wg-m249 (medium DoS, dev-scope, patched 11.0.1 but transitive parents glob/test-exclude cap at ^9/^10 so Dependabot can't PR) on 9 repos: arachne, creds, loganne, media_seinn, notes, time, time_component, restful-queue, tfluke. Judgement call: no issue filed (dev-only, no attacker-controlled glob path; no actionable fix) - deviates from strict auto-resolvable rule since a patch exists; told team-lead. Unchanged: 4 deepmerge GHSA-gcqx-w48m-w2h4 (low, auto-resolvable). 3 codeql unchanged, tracked (contacts#771, googlesync_import#218, media_metadata_api#325 all open). 0 secret-scanning. Checks 3/4 not due (last 2026-10-06; due ~2026-11-06). -->

<!-- 2026-11-07 run: 14 dependabot alerts: minimatch GHSA-g3hv-75wg-m249 on 9 repos (arachne, creds, loganne, media_seinn, notes, time, time_component, restful-queue, tfluke; dev-scope, parents cap it; re-verified lockfiles for time_component/restful-queue/tfluke, lucos_time lockfile not fetched at root path) + 5 deepmerge (low, no patch). No issues. 3 codeql unchanged/tracked, 0 secret-scanning. Checks 3/4 not due (last 2026-11-06). -->

<!-- 2026-11-12 run: identical to 11-07 — 14 dependabot alerts: minimatch GHSA-g3hv-75wg-m249 on 9 repos (dev-scope, parent-capped, no issue) + 5 deepmerge GHSA-gcqx-w48m-w2h4 (low, no patch, auto-resolvable). 3 codeql unchanged/tracked, 0 secret-scanning. Checks 3/4 not due (last 2026-11-06). -->
