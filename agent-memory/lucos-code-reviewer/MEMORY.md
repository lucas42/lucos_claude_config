# Persistent Memory — lucOS Code Reviewer

## Review Behaviour

- [Three-stage env-var wiring](review_envvar_wiring.md) — new `os:getenv`/`os.environ`/`process.env` reads need matching compose `environment:` entry AND lucos_creds value; `_ENDPOINT` path-append is a convention violation; flag until lucos_repos#387 lands
- [Incident report completeness checks](feedback_incident_report_followups.md) — missing action items, "(updated)" cumulative tables missing prior rows, and detector signal-class mismatches all warrant REQUEST_CHANGES
- [Loganne webhook subscriber hostnames](review_loganne_webhook_urls.md) — curl the hostname before approving; `media-metadata.l42.eu` is manager not API (lucos_loganne PR #467)
- [Stale Dependabot regression PRs](feedback_dependabot_stale_regression.md) — `@dependabot recreate` is deterministic; net regression vs main = close it, not recreate
- [SSH key handling and deploy snapshot heuristics](review_ssh_deploy_patterns.md) — `Load key … error in libcrypto` = corruption class; deploy snapshot vs live state check
- [Shell script undefined variable references](review_shell_scripts_undefined_vars.md) — flag SC2154-class typos in shell scripts as concrete issues; latent path caused 23-min outage (2026-05-21)
- Three quick correctness/process gotchas: [unchecked pre-merge checklist items block auto-merge on unsupervised repos](review_unchecked_premerge_checklist.md) (lucos_arachne #476), [specialist sign-offs must be GitHub artifacts, not SendMessage](review_specialist_signoff_artifact.md), [datetime tz normalisation — check `tzinfo is None` before assuming UTC](review_datetime_tz_normalisation.md) (lucos_media_weightings #192)
- [Detection code path coverage](review_detection_code_coverage.md) & [x-sentinel bash trailing-newline trick](review_xsentinel_bash.md) — check both success/failure paths for alert counters; for x-sentinel with trailing `\n`, use `printf '%s' "$VAR" | cmp -s "$FILE" -`
- [fetchEolasName hotpath + SSRF notes](review_sync_hotpath_external.md) — sync external call in write hot path is a 502-incident risk (2026-05-29 root cause); for SSRF false-positive review cite `fetchEntityNameFromSource` hostname whitelist not `ValidateURIOrigin` ([[feedback-ssrf-request-forgery-assessment]])
- [tom-select `updateOption` keying — first arg must match `valueField`](review_tomselect_updateoption_keying.md) — silent no-op if key doesn't match; confirmed bug in lucos_search_component PR #190 (contact-mode pre-selected-item hydration)
- [Robustness gaps must block — "unlikely in practice" is not a valid downgrade](feedback_robustness_gaps_block.md) — exception-path resource leaks, partial cleanup on error, missing guards: request changes even if the fix is one line and the failure scenario is improbable (lucos_backups #292/#293)
- [Aithne auth integration checklist](review_aithne_migration_prs.md) — three-branch pattern, algorithm pinning, kid sanitisation, open-redirect in next=, JWKS failure logging, AITHNE_ORIGIN env var, inline ENVIRONMENT read; real bugs from lucos_arachne #637–#675 (migration complete 2026-06-29; applies to new integrations too)
- Two more frontend JS event-handling gotchas: [async mutex asymmetry between sibling functions](review_js_async_mutex.md) (seinn cache-thrash, 2026-05-19/20), [delegated-click `preventDefault()` reverts a checkbox's native toggle if called before the target check](review_js_delegated_click_preventdefault.md) — breaks both mouse and keyboard Space-to-toggle; verify empirically with Playwright/Chromium, not just spec-reading (lucos_photos PR #487)

## Cross-Repo Review Rules

- [Docker healthcheck pitfalls](review_docker_healthchecks.md) — `localhost` vs `127.0.0.1` on Alpine, missing `wget`/`nc`/`curl` in minimal base images, verify actual bind port from `startup.sh` not `EXPOSE`

## Review Patterns — Common Mistakes to Avoid

- [`head_sha` on check-runs](review_headsha_checkruns.md) — read the field directly, never alias from `.pull_requests[0].head.sha` (null with no PR cross-ref); false APPROVE on seinn PR #460
- [CodeQL false-positive suppression](review_codeql_suppression.md) — use the config-file exclusion or Security-UI dismissal, not inline `// codeql[]` comments (silently inert without action config)
- [Verify absence before requesting changes](review_verify_absence_before_requesting.md) — read the raw file/full JS source, not just the diff (can be stale); shadow-DOM fixes often live in JS handlers, not CSS
- [Post review immediately, check CI after](review_post_then_check_ci.md) — waiting for CI first risks a race against a developer's mid-CI push (lucos_configy PR #64)
- [Read the full function for error-handling reviews](review_read_full_function_error_handling.md) — an existing guard outside the diff's context window can already cover the case (lucos_media_metadata_manager PR #191)
- [Be assertive — REQUEST_CHANGES for concrete fixable issues](feedback_be_assertive_request_changes.md) — don't bury them as approval notes (lucos_monitoring PR #93)
- [Verify a quoted review via the GitHub API](review_verify_quoted_review_via_api.md) — never trust a coordinator's paraphrase from context recall alone
- [`try/except` refactors can silently drop variable assignments](review_try_except_refactor_variable_drop.md) — verify every original-`try`-block assignment survives (lucos_backups PR #62/#63)

## Language/Platform Pitfalls

- [Erlang: `lists:join/2` returns an iolist, not a flat string](review_erlang_pitfalls.md) — use `string:join/2` for `++`/comparison contexts; also `.app.src` `applications:` ordering vs lazy `httpc`/`ssl`/`inets` starts ([[review-erlang-otp-startup]])
- [Android: MediaStore `NOT IN (?, ?)` silently returns an empty cursor](review_android_mediastore_pitfalls.md) — filter in Kotlin inside the cursor loop instead (lucos_photos_android regression)

## CircleCI

- [`lucos/build` unified orb + `platform` param](review_circleci_build_convention.md) — old `build-multiplatform`/`build-amd64`/`build-armv7l`/`build-arm64`/pici all retired; don't flag missing `platform` without confirming ARM deployment
- [`max_auto_reruns` on `run` steps, and the `|| true` trap](review_circleci_max_auto_reruns.md) — valid at step level, but combined with `|| true` on the same step it never fires (lucos_deploy_orb PR #36/#146)

## GitHub Actions / Auto-Merge

- [Dependabot auto-merge caller workflow pattern](review_dependabot_automerge_workflow.md) — `pull_request` + `permissions`, never `pull_request_target` + `uses:` (causes `startup_failure`)
- Auto-merge two-workflow distinction and supervision-check rules live in `agents/workflows/review-pr.md` (loaded every session) — [additional confirmed misreport instances](review_automerge_confirmed_instances.md) supplement it

## Tooling Gotchas

- [`gh-as-agent` body text starting with `@`](review_gh_body_at_sign.md) — wrap package names like `@types/node` in backticks or it's read as a file path
- [Fetching GitHub Actions logs](review_github_actions_logs.md) — `audit-dry-run` is advisory not required; always use `gh-as-agent`'s job-logs endpoint, never raw `curl` (can serve a stale cached zip)
- [`crane --platform` rejects comma-separated lists](crane-platform-flag.md) — flag each platform separately or omit for all (crane v0.4)

## Repo-Specific Notes

- **lucos_repos:** Convention PRs → check `docs/convention-guide.md`. `RepoTypeScript` = configy *scripts* list, not the TypeScript language.
- [lucos_arachne: triplestore check](lucos_arachne_triplestore.md), [CLAUDE.md caveat](lucos_arachne_claude_md_convention_caveat.md) — triplestore: hold until #74; caveat: "every rdf:type" means domain types only, push back if #544 doesn't fix it
- [lucos_media_seinn mocha regression](lucos_media_seinn_mocha_regression.md) — recurring Dependabot major-group CI failure; #462 fix applied but didn't work, new tracking in #466; leave open as live reference
- [Estate DNS failure pattern in CI](feedback_estate_dns_ci_pattern.md) — simultaneous GitHub Actions + CircleCI `*.l42.eu` DNS failure → authoritative outage, not a PR defect; configy silent fail-closed → .github#68
