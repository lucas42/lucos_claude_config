# Persistent Memory — lucOS Code Reviewer

## Cross-Repo Review Rules

### Docker Healthchecks — `localhost` vs `127.0.0.1`
- **Always flag `localhost` in healthcheck URLs as a blocking issue.** On Alpine-based containers, `localhost` can resolve to `::1` (IPv6) rather than `127.0.0.1` (IPv4). If the service binds only IPv4, the healthcheck will fail silently.
- The correct pattern is `http://127.0.0.1:<port>/_info`.
- This was confirmed as a real failure mode via lucos_arachne#91. A missed instance in lucos_contacts PR #533 required a follow-up issue (#534).

### Docker Healthchecks — tool availability in Debian-based images
- **`golang:N` images do NOT include `nc` or `wget` by default**, despite being Debian-based. Unlike `node:N` (which bundles `buildpack-deps` with many tools), `golang:N` is a minimal Debian image. Any tool needed for healthchecks must be explicitly installed.
- `node:N` (non-slim, non-alpine) DOES include `wget` and `nc` via `buildpack-deps`.
- `nginx:N` (Debian) images include `curl` but NOT `wget`. Use `curl --fail -s -o /dev/null <url>` for healthchecks. Confirmed: approved `wget` in lucos_router#22; required fix in #24.
- `debian:*` minimal base images do NOT include `wget`, `nc`, or `curl` by default.
- Confirmed: lucos_creds#88 approved `nc` healthcheck without verifying it was installed; required fix in #89.

### Docker Healthchecks — verify the correct port
- **For services that do NOT use `$PORT` (e.g. internal app containers), always verify the actual bind port from `startup.sh` or the CMD before approving.** Do not assume the port from the Dockerfile's `EXPOSE` or `FROM` image name.
- Example: lucos_eolas `app` uses gunicorn binding on `:80` (confirmed in `app/startup.sh`), not port 8000. Approved the wrong port (8000) in lucos_eolas#80; required a follow-up fix in lucos_eolas#84.

## Review Patterns — Common Mistakes to Avoid

### Post code review immediately, then follow up if CI fails
- **Do not wait for CI before posting your code review.** Read the diff, evaluate the code, and post your review (APPROVE or REQUEST_CHANGES) immediately based on code quality alone.
- After posting, wait for CI to complete. If CI fails, post a second REQUEST_CHANGES review flagging the failure. If CI passes, nothing more needed.
- **Why:** Waiting for CI before reviewing creates a window where the developer can push a new commit, making your diff stale. Posting immediately eliminates this race, and gives the author faster feedback.
- Confirmed failure mode: lucos_configy PR #64 — read components.yaml diff, waited for CI, developer pushed scripts.yaml version in the meantime. Review was posted on a commit I hadn't examined.

### Be assertive — request changes for concrete fixable issues, even minor ones
- If you spot something concrete and fixable (e.g. an implicit ordering dependency, a missing idempotent call), **request changes** — don't bury it as a parenthetical note in an approval.
- Reserve approvals-with-notes for genuinely subjective points or things requiring significant design discussion.
- **Why:** A note in an approval is easy to miss and may never get fixed. A REQUEST_CHANGES ensures the author addresses it before merging. Confirmed: lucos_monitoring PR #93 — the `ssl`/`inets` ordering dependency in `fetcher_circleci` was noted but not blocked on; user confirmed it should have been a REQUEST_CHANGES.

### `try/except` refactors can silently drop variable assignments
- When a PR refactors a `try/except` block (e.g. replacing bare `except:` with an explicit check), **always verify that all variable assignments inside the original `try` block are preserved** in the refactored code.
- Missed instance: lucos_backups PR #62 dropped `project = labels[...]` (which was inside the original `try`) when consolidating the error check. The variable was still used downstream, causing `NameError` on every labelled volume. Required emergency fix in PR #63.

## Erlang Pitfalls

### `lists:join/2` returns an iolist, not a flat string
- **`lists:join/2`** (OTP 22+) returns a nested iolist, NOT a flat string. Using it with `++` string concatenation produces a nested char list that fails string comparisons and pattern matching.
- **`string:join/2`** returns a proper flat string and is the correct choice when the result will be concatenated with `++` or compared as a string.
- Similarly, `re:replace/4` with `{return, list}` can return an iolist — wrap with `lists:flatten/1` before using with `++`.
- Confirmed as a real CI failure in lucos_monitoring PR #58.

## Android / MediaStore Pitfalls

### MediaStore `NOT IN` with bound parameters silently returns empty cursor
- **Never approve a PR that uses `NOT IN (?, ?)` in a MediaStore selection string with bound parameters.** On some Android versions, the MediaStore ContentProvider silently returns an empty cursor — no error, no exception, just zero results.
- The correct approach is to apply the exclusion filter in Kotlin inside the cursor loop (e.g. `if (ownerPackage in EXCLUDED_PACKAGES) continue`).
- Confirmed as a real production regression in lucos_photos_android: the TikTok `OWNER_PACKAGE_NAME NOT IN (?, ?)` filter broke sync entirely from v1.0.13 on at least one device. Fixed in PR #79.

## CircleCI Build Convention

### `build-multiplatform` is the standard for ARM-targeted services — amd64-only services stay on `build-amd64`
- `lucos/build-multiplatform` (Docker buildx + QEMU, produces a unified `linux/amd64,linux/arm64` manifest) is the standard for services deployed to ARM architectures.
- **amd64-only services stay on `build-amd64`** — the migration to `build-multiplatform` is NOT universal. Confirmed: lucos_monitoring stays on `build-amd64` (lucas42/lucos_monitoring#83 closed as not_planned).
- `build-armv7l`, `build-arm64`, and the pici Docker-in-Docker build host are retired. pici repo is archived.
- **Do NOT flag `build-amd64` as needing migration without first checking whether the service targets ARM.** Only flag if the service is confirmed to be deployed to ARM hosts.
- When a service uses `build-multiplatform`, the `docker-compose.yml` image tag should be a plain image name (e.g. `lucas42/lucos_foo`) with no `${ARCH}-latest` suffix — Docker resolves the correct platform from the manifest automatically.
- No `architecture` parameter is needed in CircleCI deploy jobs unless the image intentionally uses a tag suffix (which it should not for new services).

## CircleCI — `max_auto_reruns` and Exit Code Suppression

### `|| true` breaks `max_auto_reruns` — never combine them
- **CircleCI's `max_auto_reruns` triggers on a non-zero exit code.** If a step uses `|| true` (or any other exit-code suppression), the step always exits 0 and retries will never trigger — making `max_auto_reruns` dead code.
- When reviewing a step that uses both `|| true` and `max_auto_reruns`, flag this as a bug.
- Confirmed: lucos_deploy_orb PR #36 — first version used `|| true` which I approved; lucas42 caught that retries would never fire. Fixed by restoring `--fail` and increasing the delay instead.

## GitHub Actions — Dependabot Auto-Merge Workflows

### `startup_failure` on auto-merge workflow — causes and patterns
- **Missing secrets**: When a repo has no Actions secrets at all, the auto-merge workflow fails with `startup_failure` on all runs. Confirmed in lucos_navbar (#46) and lucos_backups (#83). Escalate to `lucos-site-reliability`.
- **`pull_request_target` + `uses:` (reusable workflow)**: This combination causes `startup_failure` for non-Dependabot PRs regardless of `if:` guards or `secrets: inherit`. GitHub resolves `uses:` references and `secrets: inherit` before evaluating `if:` conditions, so the workflow fails to start. Confirmed via lucas42/.github #13/#14.
- **Non-Dependabot actor on `pull_request` trigger (expected)**: With the correct `pull_request` + `permissions` pattern, non-Dependabot PRs trigger the workflow but the `if:` guard on the reusable workflow's internal job causes it to be skipped. Workflow concludes `skipped` — **expected, not an error**.

### Correct caller pattern — `pull_request` + `permissions` block
- **`pull_request` is the correct trigger** (NOT `pull_request_target`) for Dependabot auto-merge caller workflows. `pull_request_target` + `uses:` causes `startup_failure`.
- Caller template:
  ```yaml
  on:
    pull_request:
      types: [opened, synchronize, reopened]
  permissions:
    pull-requests: write
    contents: write
  jobs:
    dependabot:
      uses: lucas42/.github/.github/workflows/dependabot-auto-merge.yml@main
  ```
- No `secrets: inherit` — not needed, and causes `startup_failure` on `pull_request_target`.
- No `if:` guard in caller — the guard lives on the job in the reusable workflow.
- The security guard is `github.event.pull_request.user.login == 'dependabot[bot]'` in the reusable workflow — checks PR *author*, stable against maintainer re-runs.
- Confirmed and validated via smoke test in lucas42/.github #14. Production rollout to ~33 repos still pending as of 2026-03-20.

### NOTE: Prior memory was wrong
- Earlier note said "`pull_request_target` is required, `pull_request` is insufficient" — this was incorrect. `pull_request` with a `permissions` block gives Dependabot the write token it needs, and avoids the `startup_failure` caused by `pull_request_target` + `uses:`.

## Auto-Merge: Two Separate Workflows

There are two distinct auto-merge workflows — do not conflate them:

### 1. `dependabot-auto-merge.yml` — for Dependabot PRs
- Triggers on Dependabot PRs and runs `gh pr merge --auto --merge`.
- Does **NOT** check `unsupervisedAgentCode`. Dependabot PRs auto-merge on all repos that have this workflow, regardless of supervised/unsupervised status.
- If an approved Dependabot PR is not merging, the problem is a workflow issue (startup failure, missing workflow file, etc.) — NOT the supervised flag.

### 2. `code-reviewer-auto-merge.yml` — for agent-authored PRs
- Triggers on PR reviews from `lucos-code-reviewer[bot]`.
- Fetches the `unsupervisedAgentCode` flag from `https://configy.l42.eu/repositories/{repo}`.
- If `true`: bot approval triggers `gh pr merge --auto --merge`.
- If `false`: bot review is posted but doesn't enable auto-merge — human approval needed.
- **Most lucos repos are supervised (`unsupervisedAgentCode: false`)**. As of 2026-04-02, only `lucos_agent_coding_sandbox` is confirmed unsupervised.

### Key distinction
- `unsupervisedAgentCode` only affects **agent-authored PRs** (via code-reviewer-auto-merge). It has NO bearing on Dependabot PRs.
- If a Dependabot PR is stuck after approval, investigate the dependabot-auto-merge workflow — do not attribute it to the supervised flag.
- Check configy for a repo's flag: `curl -sf "https://configy.l42.eu/repositories/{repo}" | jq '.unsupervisedAgentCode'`

## Repo-Specific Review Rules

### lucos_repos
- If a PR adds or changes a convention definition, compare it against the "Checklist for reviewing convention PRs" in `docs/convention-guide.md` in that repo.
- **`RepoTypeScript` is NOT about the TypeScript language.** It refers to repos in configy's *scripts* list (tools designed to run locally). Do not confuse the two when raising issues or reviewing convention PRs.

## Recently Mentioned Reptiles

**IMPORTANT**: Before choosing a reptile fact, always read `/home/lucas.linux/.claude/agent-memory/lucos-code-reviewer/reptiles.md` in full. The list below is only a summary of the most-overused animals — the full history is in that file. Many animals appear in reptiles.md that are not listed here.

- Thorny devil (2026-03-07)
- Green iguana (2026-03-07)
- Common snapping turtle (2026-03-07, 2026-03-10)
- Gila monster (2026-03-07, 2026-03-10)
- Slow worm (2026-03-07)
- Leatherback sea turtle (2026-03-07)
- Nile crocodile (2026-03-07)
- Veiled chameleon (2026-03-07)
- Blue-tongued skink (2026-03-07, 2026-03-09, 2026-03-10) — DO NOT USE
- Green tree python (2026-03-07)
- Tokay gecko (2026-03-07)
- Black mamba (2026-03-10)
- Inland taipan (2026-03-10)
- Malagasy leaf-tailed gecko (2026-03-10)
- Satanic leaf-tailed gecko (2026-03-04, 2026-03-06, 2026-03-10, 2026-03-12, 2026-03-19) — DO NOT USE, massively overused
- Pancake tortoise (2026-03-10) — COMPLETELY BANNED, massively overused
- Panther chameleon (2026-03-10) — DO NOT USE AGAIN SOON
- Komodo dragon (2026-03-10, 2026-03-11, 2026-03-13, 2026-03-16) — DO NOT USE, massively overused
- Tuatara (2026-03-04, 2026-03-05, 2026-03-06, 2026-03-07, 2026-03-14) — heavily used, avoid for now
- Axolotl (2026-03-10, 2026-03-12, 2026-03-14, 2026-03-17) — DO NOT USE, massively overused (also technically an amphibian)
- Texas horned lizard / Horned lizard / Phrynosoma (2026-03-05, 2026-03-17, 2026-03-19) — DO NOT USE, used three times
- Spiny softshell turtle / Apalone spinifera (2026-03-05, 2026-03-06, 2026-03-23) — DO NOT USE, used multiple times
- Bog turtle (2026-03-05, 2026-03-21, 2026-04-02) — used 3 times, avoid for now
