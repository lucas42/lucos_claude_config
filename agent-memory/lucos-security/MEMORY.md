# lucos-security Agent Memory

## Infrastructure: Repo Visibility

All lucos repos on github.com/lucas42 are **public**. This is critical context for every security review:
- Documentation committed to repos (including `docs/reviews/`, ADRs, CLAUDE.md) is publicly readable
- GitHub issue trackers, including closed issues, are publicly readable
- Git history (including PR commit history) is permanent and publicly searchable

## Policy: Security Advisory Decision Rule (Agreed 2026-03-04)

**Default path:** Security findings go as normal public GitHub issues. This keeps them in the normal triage/routing/implementation pipeline.

**Advisory path (narrow exception):** A finding goes to a private GitHub Security Advisory ONLY if BOTH of these are true:
1. An attacker with network access could exploit it **immediately**, without needing any other pre-existing access or insider knowledge
2. The finding is not yet fixed

Everything else — conditional exploitability, defence-in-depth gaps, theoretical attack chains, things requiring existing access to exploit further — goes as a normal public issue.

**Do not over-classify.** Examples of things that do NOT need advisories:
- Credentials that might appear in internal logs under specific error conditions
- Attack chains that require existing privileged access to trigger
- Things behind network controls (even imperfect ones)

See lucas42/lucos#25 for the full discussion. The original (too-cautious) advisory criteria from the initial proposal were revised after feedback from lucas42 and lucos-issue-manager.

**PROCESS NOTE:** When conducting a security audit, apply the routing decision to EACH FINDING BEFORE WRITING ANYTHING in public. Do not write findings to public comments and sort routing afterwards.

## Risk Pattern: Prompt Injection via External Data Sources

AI agents that consume external text (CI build logs, issue bodies, PR descriptions, log files) are vulnerable to prompt injection. This is a recurring risk class across lucos because:
- All lucas42 repos are public, so anyone can open PRs and trigger CI builds
- Lucos agents have access to infrastructure credentials, expanding blast radius
- Agents are increasingly being given read access to third-party systems (CircleCI, etc.)

Key principle: treat external text content (build logs, user-supplied strings, web page content) as **untrusted data**, not as trusted instructions. Mitigations:
- Prefer structured API responses (status codes, timestamps, job names) over raw freeform text
- When freeform text must be included in agent context, wrap it in clear delimiters with explicit framing that content is untrusted
- Limit raw log/text access to only what is necessary; prefer human-in-the-loop for full log reads

Flagged on: lucas42/lucos_deploy_orb#8 (CircleCI token for SRE agent)

## Risk Pattern: CI Build Logs May Contain Secrets

CircleCI secret masking in build logs is imperfect. Partial values, base64-encoded variants, secrets in error stack traces, and commands echoing their argument lists can slip through. A read token scoped to CircleCI also grants access to log output, not just pass/fail status.

The `remote-build.yml` command in `lucos_deploy_orb` passes `DOCKERHUB_USERNAME` and `DOCKERHUB_ACCESS_TOKEN` as env vars to a remote SSH command -- these could appear in build logs.

Prefer v2 API structured status responses over raw log output wherever possible.

## Risk Pattern: CircleCI Token in Query Parameter (lucos_monitoring)

`src/fetcher.erl` appends `CIRCLECI_API_TOKEN` as a query param to CircleCI v1.1 API URLs. This exposes the token in logs, browser history, and HTTP intermediaries. The v1.1 API is also deprecated. Both problems are fixed by migrating to the v2 API with header-based auth. Flagged in lucos_monitoring#23 audit.

## Risk Pattern: OS Command Injection via `os:cmd` with Unvalidated Input

Erlang's `os:cmd/1` is equivalent to a shell `system()` call — any unsanitised input concatenated into the command string is injectable. Found in `lucos_monitoring/src/fetcher.erl` in `checkTlsExpiry/1`, where the `Host` value from `service-list` is concatenated directly. Mitigation: always use Erlang's native libraries or `open_port` with an explicit argument list rather than a shell string. Current exploitability is low (service-list is baked in at build time from internal configy), but the pattern is inherently fragile.

## Risk Pattern: Unauthenticated State-Mutation Endpoints in Internal Services

`lucos_monitoring/src/server.erl` exposes `/suppress/*` endpoints (PUT/DELETE/POST) with no authentication. These allow any network-reachable caller to open/close alert suppression windows. Pattern to watch for in other lucos services: internal services that have write/action endpoints often lack auth because they're assumed to be unreachable — but network_mode:host and firewall rules are not a substitute for endpoint auth.

## Risk Pattern: XSS via Unescaped External Data in Erlang HTML Rendering

`lucos_monitoring/src/server.erl` renders `techDetail` and `debug` fields from remote `/_info` endpoints directly into HTML without encoding. No Erlang HTML-escaping library is currently used. Any lucos service doing manual string concatenation into HTML should be checked for this. Fix: escape `<`, `>`, `&`, `"` before interpolation; run URL-linkification regex on already-escaped content.

## Policy: lucos-security PRs Are NOT Auto-Merged (Decision: 2026-03-03)

**lucas42 explicitly rejected auto-merging lucos-security[bot] PRs** (see lucas42/lucos#26, closed as "not planned").

Rationale: Dependabot PRs are deterministic; LLM-generated PRs are non-deterministic and need human/reviewer approval before merging.

The intended path is: lucos-security raises PR -> lucos-code-reviewer approves it -> auto-merge triggers. This is tracked in lucas42/lucos_photos#42.

**Do not raise issues or PRs asking for lucos-security[bot] to be added to auto-merge conditions.**

## Accepted Risk: ReDoS in vue 2 (vue-leaflet-antimeridian)

vue-leaflet-antimeridian uses Vue 2 (via vue2-leaflet peerDep). Vue 2 is EOL and contains an unfixed ReDoS in `parseHTML`. **lucas42 has consciously accepted this risk** (see lucas42/vue-leaflet-antimeridian#4, 2026-03-03). No fix available without a full Vue 3 migration.

Do not raise this alert again. If the alert resurfaces, reference the accepted risk decision in #4.

## Fixed: DOMPurify XSS in lucos_arachne (Merged 2026-03-05)

DOMPurify 3.3.2 released 2026-03-05 fixes raw-text/jsdom parsing bypass (GHSA-v2wj-7wpq-c8vv). Added `dompurify >= 3.3.2` override to `explore/package.json` and regenerated `explore/package-lock.json`. PR lucas42/lucos_arachne#52 merged. DOMPurify 3.3.2 confirmed in lock file. Dependabot alert #15 remained technically open on 2026-03-05 (likely GitHub lag). No further action needed unless it persists beyond a few days.

## Issue Filing: One Finding Per Issue

lucos-issue-manager prefers individual focused issues, not omnibus tickets. When a security scan reveals multiple findings in one repo, raise **one issue per finding** so each can be triaged, labelled, and implemented independently. Confirmed by lucos_notes#149 (omnibus CodeQL issue) being split into #150, #151, #152 before it could proceed.

## Convention: CodeQL Top-Level Permissions Block Goes via lucos_repos (2026-03-06)

When I raised lucas42/lucos#36 (add top-level `permissions: contents: read` to CodeQL workflow template), lucas42 directed this to be implemented as a convention definition in `lucos_repos` so per-repo issues can be raised automatically. **Do not raise per-repo issues for this manually** — it will be handled systematically via lucos_repos#51.

General principle: GitHub Actions workflow conventions that apply across all repos should be defined in `lucos_repos`, not raised as individual per-repo issues.

## CodeQL: `safe_path` Pattern is a False Positive for py/url-redirection

`lucos_photos` uses a `safe_path()` wrapper that strips scheme and netloc before using user-supplied input in a redirect URL. CodeQL flags this as `py/url-redirection` but it is a false positive — the mitigation is in place. If this alert resurfaces, it should be dismissed with the note that `safe_path` provides the necessary guarantee. See lucos_photos#96 (closed as "not planned", 2026-03-06).

## Convention: Dependabot Config Checks (Design 2026-03-07)

For the `lucos_repos` Dependabot convention (lucos_repos#65), the security-critical checks are:
1. `.github/dependabot.yml` exists
2. At least one `github-actions` entry with `directory: "/"` is present (supply chain attack mitigation)
3. `dependency-type: "all"` on all entries (keeps dep base current so security patches land on maintained code)

Do NOT check for specific ecosystems (npm/pip/docker) per-repo — these vary legitimately and the convention framework doesn't know what ecosystems a repo uses.

## Accepted Risk: Clear-text Logging in lucos_contacts_fb_import (2026-03-12)

CodeQL `py/clear-text-logging-sensitive-data` alerts #1 and #2 in `lucos_contacts_fb_import` have been closed as not_planned (lucas42/lucos_contacts_fb_import#17). Rationale: the script runs locally on the user's own laptop, the logged data belongs to that user, and the log output serves a legitimate UX purpose during Facebook import. The CodeQL threat model (logs shipped to shared infrastructure) does not apply.

Do not re-raise these alerts.

## Design: lucos_creds Scoped Key Permissions (lucos_creds#87, approved 2026-03-13)

`CLIENT_KEYS` format extended with `|` delimiter for optional scopes:
```
clientsystem:clientenv=key|scope1,scope2
```
Unscoped entries unchanged. Scopes only set after server is migrated (deploy first, set scopes second — env vars pulled at deployment time is the natural safety checkpoint).

Key security decisions accepted:
- **No scope = no permissions** (fail-closed by default on migrated systems)
- Scope enforcement is server-side only; client never knows its own scopes
- Scopes opaque to lucos_creds; each service defines its own vocabulary (`{resource}:{action}` convention)
- Loganne audit trail for scope changes to be included
- Scope-aware flag rejected — migration risk accepted given deployment-time env var pull

Do not re-raise the scope-aware flag concern.

## Ops Checks Schedule

See `ops-checks.md` for tracking when periodic checks (e.g. monthly CodeQL coverage scan) were last run.

## Key People/Agents

See `relationships.md` for notes on working with other lucos agents.
