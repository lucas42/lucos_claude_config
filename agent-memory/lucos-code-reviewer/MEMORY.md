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

### `pull_request_target` is required — `pull_request` is insufficient
- Dependabot PRs are treated as fork PRs by GitHub, so `pull_request` issues a read-only token that cannot be elevated even with job-level `permissions`. The `startup_failure` persists after moving permissions to job level.
- **`pull_request_target` is the correct trigger** for Dependabot auto-merge caller workflows. It runs in the base-branch context with a write token.
- The security guard is in the **reusable workflow** (`github.event.pull_request.user.login == 'dependabot[bot]'`) — this checks the PR *author*, not the run actor, so it is stable against maintainer re-runs. The caller's `github.actor` check is a weaker redundant layer.
- Safety relies on **no checkout of PR code** — the elevated token never touches untrusted content.
- Confirmed via lucos-security review of lucos_repos PR #144.

### Permissions belong in the reusable workflow, not the callers
- The `permissions` block (`pull-requests: write, contents: write`) stays in the reusable workflow at job level (`lucas42/.github`). Callers should not repeat it.
- Caller template: `if:` guard + `uses:` call only, no `permissions` block.

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
