# GitHub Repository Configuration

## CodeQL (`.github/workflows/codeql-analysis.yml`)

Only include languages actually present in the repo. Remove any languages copied from another project that don't apply (e.g. `javascript` in a Python-only project).

Add a top-level `permissions: contents: read` block to all CodeQL workflows (convention tracked in `lucos_repos`; do not raise per-repo issues manually — the audit tool handles it).

CodeQL supported languages (as of `codeql-action/init@v4`): C/C++, C#, Go, Java/Kotlin, JavaScript/TypeScript, Python, Ruby, Swift. **PHP is NOT supported** — attempting to add `php` will fail with `Did not recognize the following languages: php`. PHP static analysis requires a separate tool (PHPStan, Psalm, etc.).

Required status check name patterns:
- Python repos: `Analyze (python)`
- JavaScript repos: `Analyze (javascript)`

These check run names must be added to branch protection rules for `main` to prevent a race condition with auto-merge.

## Dependabot (`.github/dependabot.yml`)

Specify the correct directories for each ecosystem — these must match where the actual files live, not convention from the source project:

- `pip`: one entry per `requirements.txt` / `pyproject.toml` location (e.g. `/api`, `/worker`, `/shared`)
- `docker`: one entry per `Dockerfile` location (e.g. `/api`, `/worker`)
- `github-actions`: always `directory: "/"`

Remove any `ignore` rules that were specific to the source project's framework (e.g. Django's `asgiref`).

Security-critical checks (per lucos_repos convention):
1. `.github/dependabot.yml` must exist
2. At least one `github-actions` entry with `directory: "/"` (supply chain attack mitigation)
3. `dependency-type: "all"` on all entries (keeps dep base current so security patches land on maintained code)

## Dependabot auto-merge (`.github/workflows/auto-merge.yml`)

Standard file, no project-specific changes needed.

## Code reviewer auto-merge (`.github/workflows/code-reviewer-auto-merge.yml`)

This workflow enables auto-merge on PRs approved by `lucos-code-reviewer[bot]`. Currently deployed to `lucos_photos` only; will be rolled out to other repos over time.

**How it works:**

1. **`auto-merge` job** — triggers on `pull_request_review: submitted`. If the review is an approval from `lucos-code-reviewer[bot]` (verified by both login and numeric user ID to prevent impersonation), it runs `gh pr merge --auto --merge`.
2. **`close-linked-issues` job** — triggers on `pull_request: closed`. If the PR was merged by `lucos-code-reviewer[bot]`, it queries GitHub's GraphQL `closingIssuesReferences` field and closes each linked open issue via the API.

The `close-linked-issues` job is necessary because **GitHub does not process closing keywords (e.g. `Closes #N`) when any bot merges a PR** — this is a platform limitation, not specific to `GITHUB_TOKEN` or GitHub Actions. The workaround uses `closingIssuesReferences`, which GitHub parses from the PR body regardless of who merges.

**Prerequisites for each repository:**

1. **Repository secrets** — two secrets must be set:
   - `CODE_REVIEWER_APP_ID` — the lucos-code-reviewer App ID (see `personas.json`)
   - `CODE_REVIEWER_PRIVATE_KEY` — the lucos-code-reviewer RSA private key (from lucos_creds, with newlines restored from the space-flattened format)
2. **GitHub App permissions** — `lucos-code-reviewer` must have these permissions on its installation:
   - `Contents: Read & write` (required to merge PRs)
   - `Pull requests: Read & write` (required to enable auto-merge)
   - `Issues: Read & write` (required to close linked issues)
3. **Repository setting** — "Allow auto-merge" must be enabled in the repo's settings
4. **Required status checks** — the CodeQL check run name(s) must be added to the branch protection rules for `main` as required status checks. This prevents a race condition where CodeQL warnings arrive after the code-reviewer approval but before auto-merge completes.

**Reference implementation:** `lucos_photos/.github/workflows/code-reviewer-auto-merge.yml`

**Note:** `lucos-security[bot]` PRs are NOT auto-merged (decision: lucas42/lucos#26, closed `not_planned`). The intended path is: lucos-security raises PR → lucos-code-reviewer approves → auto-merge triggers.

## GitHub Actions workflow conventions

GitHub Actions workflow conventions that apply across all repos should be defined in `lucos_repos` as convention checks, not raised as individual per-repo issues. The audit tool raises per-repo issues automatically.

## GitHub comment conventions

- **Never use `#N` syntax for Dependabot alerts, CodeQL alerts, or secret-scanning alerts** in GitHub comments or PR descriptions. The `#N` syntax always links to issues/PRs, and alert numbering is separate. Instead, use the CVE or GHSA identifier (e.g. `CVE-2026-0540`, `GHSA-v2wj-7wpq-c8vv`) — GitHub auto-links these.
