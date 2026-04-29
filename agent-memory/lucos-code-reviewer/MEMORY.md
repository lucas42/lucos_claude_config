# Persistent Memory — lucOS Code Reviewer

## Review Behaviour

- [Incomplete incident reports — request changes, don't approve with a note](feedback_incident_report_followups.md) — if analysis identifies a gap but actions table doesn't capture it, block until it's added
- **Specialist sign-offs must be GitHub artifacts.** A SendMessage confirmation from lucos-security or another specialist is NOT a sign-off. Ask them to post a GitHub review or comment on the PR, then wait for the URL before reporting "signed off" to the team-lead.
- **Datetime timezone normalisation — parse first, then check `tzinfo is None`.** Never blindly append `+00:00` to non-Z timestamps; they may already carry an explicit offset (e.g. `+05:30`) and appending would produce a malformed string. Correct pattern: replace Z→`+00:00`, parse with `fromisoformat`, then `if dt.tzinfo is None: dt = dt.replace(tzinfo=timezone.utc)`. Missed this in lucos_media_weightings PR #192 v1; lucas42 caught it.

## Cross-Repo Review Rules

### Docker Healthchecks — `localhost` vs `127.0.0.1`
- **Always flag `localhost` in healthcheck URLs as a blocking issue.** On Alpine-based containers, `localhost` can resolve to `::1` (IPv6) rather than `127.0.0.1` (IPv4). If the service binds only IPv4, the healthcheck will fail silently.
- The correct pattern is `http://127.0.0.1:<port>/_info`.
- This was confirmed as a real failure mode via lucos_arachne#91. A missed instance in lucos_contacts PR #533 required a follow-up issue (#534).

### Docker Healthchecks — tool availability in Debian-based images
- **`golang:N` images do NOT include `nc` or `wget` by default**, despite being Debian-based. Unlike `node:N` (which bundles `buildpack-deps` with many tools), `golang:N` is a minimal Debian image. Any tool needed for healthchecks must be explicitly installed.
- `node:N` (non-slim, non-alpine) DOES include `wget` and `nc` via `buildpack-deps`.
- `nginx:N` (Debian) images include `curl` but NOT `wget`. Use `curl --fail -s -o /dev/null <url>` for healthchecks. Confirmed: approved `wget` in lucos_router#22; required fix in #24.
- `openjdk:N-jdk-slim` images do NOT include `wget` or `curl` by default — must be explicitly installed. Confirmed as a production outage in lucos_arachne#277: Fuseki 6.0.0 dropped `wget` from the base image, healthcheck failed, web/ingestor/mcp stuck in Created state. Fix: install `curl` and use `curl --fail -s -o /dev/null <url>` (lucos_arachne#278).
- `debian:*` minimal base images do NOT include `wget`, `nc`, or `curl` by default.
- Confirmed: lucos_creds#88 approved `nc` healthcheck without verifying it was installed; required fix in #89.

### Docker Healthchecks — verify the correct port
- **For services that do NOT use `$PORT` (e.g. internal app containers), always verify the actual bind port from `startup.sh` or the CMD before approving.** Do not assume the port from the Dockerfile's `EXPOSE` or `FROM` image name.
- Example: lucos_eolas `app` uses gunicorn binding on `:80` (confirmed in `app/startup.sh`), not port 8000. Approved the wrong port (8000) in lucos_eolas#80; required a follow-up fix in lucos_eolas#84.

## Review Patterns — Common Mistakes to Avoid

### Verify absence of a specific thing in the raw file before requesting changes
- **When planning to REQUEST_CHANGES because something specific is missing (e.g. a type guard, a null check), verify its absence by reading the raw file — not just the diff.** The GitHub PR files API can serve stale diff data that omits lines present in the actual commit.
- Confirmed failure: lucos_notes PR #355 — diff omitted `typeof path !== 'string'` guard which was already in the file at the HEAD SHA. Resulted in a false REQUEST_CHANGES that wasted a review round-trip.
- Pattern: `curl -s "https://raw.githubusercontent.com/lucas42/{repo}/{sha}/{file}" | grep -A N "function"` to verify.

### Post code review immediately, then follow up if CI fails
- **Do not wait for CI before posting your code review.** Read the diff, evaluate the code, and post your review (APPROVE or REQUEST_CHANGES) immediately based on code quality alone.
- After posting, wait for CI to complete. If CI fails, post a second REQUEST_CHANGES review flagging the failure. If CI passes, nothing more needed.
- **Why:** Waiting for CI before reviewing creates a window where the developer can push a new commit, making your diff stale. Posting immediately eliminates this race, and gives the author faster feedback.
- Confirmed failure mode: lucos_configy PR #64 — read components.yaml diff, waited for CI, developer pushed scripts.yaml version in the meantime. Review was posted on a commit I hadn't examined.

### Always read the full function when reviewing error handling near changed lines
- **Before raising a concern about missing error handling (e.g. a missing guard in a catch block), read the full function from the actual file** — not just the diff. Unchanged lines (like `if (err.name === 'AbortError') return;`) won't appear in the diff but directly affect the correctness of new code.
- If new code manipulates DOM state inside async/cancellable operations, fetch the full surrounding function to verify existing guards are present.
- Confirmed failure: lucos_media_metadata_manager PR #191 — raised a false REQUEST_CHANGES about a missing AbortError check; the check was at line 294 in the existing code, invisible in the diff.

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

### `max_auto_reruns` is valid at BOTH workflow-job level AND `run` step level
- **`max_auto_reruns` and `auto_rerun_delay` can be set as attributes on individual `run` steps** inside an orb command — they are NOT exclusively workflow-level job attributes.
- The existing `lucos_deploy_orb` `deploy.yml` already uses `max_auto_reruns: 5` / `auto_rerun_delay: 30s` on multiple `run` steps.
- Do NOT tell a developer these can't go in an orb command — they can. Confirmed: lucos_deploy_orb PR #146.

### `|| true` breaks `max_auto_reruns` — never combine them
- **CircleCI's `max_auto_reruns` triggers on a non-zero exit code.** If a step uses `|| true` (or any other exit-code suppression), the step always exits 0 and retries will never trigger — making `max_auto_reruns` dead code.
- When reviewing a step that uses both `|| true` and `max_auto_reruns`, flag this as a bug.
- A `|| true` on a cleanup sub-command inside the script (e.g. `git tag -d ... || true`) does NOT suppress the overall step exit code — only `|| true` at the end of the final command does.
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
- Triggers on approval reviews from **either** `lucos-code-reviewer[bot]` OR `lucas42`.
- Fetches `unsupervisedAgentCode` from configy and determines the **expected reviewer**:
  - Unsupervised (`true`): expected reviewer = `lucos-code-reviewer[bot]` → bot approval triggers `gh pr merge --auto --merge`
  - Supervised (`false`): expected reviewer = `lucas42` → lucas42's approval triggers `gh pr merge --auto --merge`
- **On supervised repos, bot approval does nothing** (workflow runs but sees bot ≠ lucas42, skips merge). **lucas42's approval is all that's needed** — the workflow calls `gh pr merge --auto --merge` automatically; he does NOT need to click Merge separately.
- **Most lucos repos are supervised.** Confirmed unsupervised as of 2026-04-28: `lucos_agent_coding_sandbox`, `lucos_repos`, **`lucos`**. Always run `check-unsupervised` to verify — never infer from repo name or memory.
- **NEVER use `curl -sf "https://configy.l42.eu/repositories/{repo}" | jq '.unsupervisedAgentCode'` to check supervision.** Repos not in configy return empty output, which silently misclassifies them as supervised. `lucos` and `lucos_backups` are not in configy, causing false "supervised" claims in PR #118 and others. The canonical command is `~/sandboxes/lucos_agent/check-unsupervised {repo}` (exit 0 = unsupervised, exit 1 = supervised, exit 2 = error).

### Key distinction
- `unsupervisedAgentCode` only affects **agent-authored PRs** (via code-reviewer-auto-merge). It has NO bearing on Dependabot PRs.
- If a Dependabot PR is stuck after approval, investigate the dependabot-auto-merge workflow — do not attribute it to the supervised flag.

### Reporting supervised repo PR status
- After bot approval on a supervised repo: `auto_merge: null` is **expected** (bot approval correctly did nothing). Report as: **"awaiting lucas42's approval — the workflow will auto-merge once he approves"**. Do NOT say he needs to click Merge.
- After lucas42 approves: workflow calls `gh pr merge --auto --merge`, setting `auto_merge` non-null. PR merges once CI passes.
- NEVER claim "auto-merge triggered/succeeded" based solely on the workflow check-run having `conclusion: success`. On supervised repos, the bot-approval run succeeds but does nothing. The only reliable signal after lucas42 approves is `auto_merge` being non-null on the PR itself.
- Only flag as stuck (criterion 7) if `unsupervisedAgentCode: true` but `auto_merge` is still null after bot approval.
- Confirmed wrong: lucos_media_metadata_api PR #101 — reported "auto-merge triggered" when PR was awaiting lucas42. Also reported "awaiting lucas42 approval **to merge**" on lucos_eolas #218 and lucos_contacts #672, implying he had to click Merge. Corrected by lucos-site-reliability 2026-04-29.

## gh-as-agent Body Field Gotchas

### `@` in review body text — wrap in backticks or avoid
- **`gh-as-agent ... --field body="..."`** treats any `@word` prefix as "read from file". Even when using a heredoc (so the value is already substituted by bash), if the final body string starts with `@`, gh interprets it as a file path and fails with "no such file or directory".
- Confirmed failure: tfluke#332 — body starting with `@types/node patch bump` triggered this. Fix: wrap the `@types/node` in backticks (`\`@types/node\``).
- **Always wrap package names starting with `@` in backticks** in review body text to avoid this issue.

## Fetching GitHub Actions Logs

### `audit-dry-run` is advisory, not a required status check
- `audit-dry-run` in `lucos_repos` is **not** a required status check — auto-merge does not wait for it. It is purely informational for the reviewer.
- A failing `audit-dry-run` does not block merge and does not warrant a REQUEST_CHANGES review on its own. Investigate the failure, but do not treat it as a hard gate.
- Confirmed: PRs #291 and #292 merged correctly despite `audit-dry-run` failing (rate limit hit during the sweep).

### Always use `gh-as-agent` for job logs — never raw curl
- **Use the job-level logs endpoint** via `gh-as-agent` to read actual log text:
  ```bash
  ~/sandboxes/lucos_agent/gh-as-agent --app lucos-code-reviewer \
    "repos/lucas42/{repo}/actions/jobs/{job_id}/logs"
  ```
  This returns plain text, pipe through `grep` to find the relevant error.
- **Never use raw `curl`** to fetch GitHub Actions logs. `get-app-token` does not exist in this environment. An unauthenticated request may follow redirects to a cached/stale zip artifact with completely wrong content and wrong timestamps — exactly what happened when diagnosing lucos_repos PR #291 (reported `auto-merge-secrets` 403s from 2026-03-20; real failure was a rate limit at `fetchRepos` on 2026-04-06).
- To get the job ID for a failing check-run: `gh-as-agent ... "repos/.../actions/runs/{run_id}/jobs?per_page=10" --jq '.jobs[] | {id, name, conclusion}'`

## Repo-Specific Review Rules

### lucos_repos
- If a PR adds or changes a convention definition, compare it against the "Checklist for reviewing convention PRs" in `docs/convention-guide.md` in that repo.
- **`RepoTypeScript` is NOT about the TypeScript language.** It refers to repos in configy's *scripts* list (tools designed to run locally). Do not confuse the two when raising issues or reviewing convention PRs.

## Repo-Specific Notes

- [lucos_arachne triplestore check](lucos_arachne_triplestore.md) — do NOT approve re-adding it until lucos_monitoring#74 lands

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
- Eastern hognose snake (2026-04-05)
- Sungazer lizard / Smaug giganteus (2026-04-06)
- Puff adder / Bitis arietans (2026-04-06)
- Timber rattlesnake / Crotalus horridus (2026-04-06)
- Eastern box turtle / Terrapene carolina (2026-03-18, 2026-04-07) — used twice, avoid for now
- Armadillo girdled lizard / Ouroborus cataphractus (8 uses across 2026-03-04 to 2026-04-08) — PERMANENTLY BANNED, used in EVERY session
- Reticulated python (*Malayopython reticulatus*) (2026-04-08) — lucos_search_component PR #107
- Green basilisk lizard / Basiliscus plumifrons (2026-04-08) — lucos_media_weightings PR #143
