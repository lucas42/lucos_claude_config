---
name: configy-undeployed-system-entry-pattern
description: Adding a pre-scaffolding repo to lucos_configy as type=system triggers a cascade of NEW failing audit conventions — don't do it
metadata:
  type: reference
---

**CORRECTED 2026-07-09 — my first pass on this (same day) was wrong. Do not repeat it.**

The monitoring-safety half of the original note still holds: a configy `system` entry with
no `domain`/`http_port`/`hosts` is genuinely invisible to `lucos_monitoring`'s HTTP checks
(`/systems/http` filters on `http_port.is_some()` — `api/src/systems.rs::http()`), and its
CircleCI fetcher treats a 404 (no CircleCI project) as a benign no-op, not an alert
(`fetcher_circleci.erl::checkCIForSlug/1`).

**But the lucos_repos audit-tool half was wrong.** `in-lucos-configy` is not the only
convention gated by configy presence. Every `lucos_repos` convention has an `AppliesTo
[]RepoType` field (`conventions/conventions.go`), and `RepoTypeUnconfigured` (a repo not in
configy at all) is NOT in the `AppliesTo` list for ~20 System/Component-scoped conventions —
so they simply don't run yet. The moment a repo is added to `config/systems.yaml` (even a
bare-null entry with no domain/http_port/hosts), its `Type` flips to `RepoTypeSystem` and
**all** of those conventions start running against it.

Most of them gracefully no-op when scaffolding (docker-compose.yml, .circleci/config.yml,
.github/workflows/*) is absent — `container-naming`, `dockerfile-*`, `env-var-passthrough`,
`standard-env-vars`, `docker-healthcheck-on-built-services`, `circleci-uses-lucos-orb`,
`circleci-deploy-serial-group`, `circleci-system-deploy-jobs`, `circleci-jobs-in-required-checks`,
`reusable-workflow-pinned`, `required-status-checks-coherent`,
`no-stale-codeql-requirement-on-infra-repos`, `auto-merge-secrets`, `codeql-workflow` (both,
skip when no CodeQL-supported language is detected) all return `Pass: true` with a "convention
does not apply" detail when the relevant file/setting is missing.

**Six do NOT have that escape hatch and hard-fail on a bare new repo:**
`circleci-config-exists`, `branch-protection-enabled`, `allow-auto-merge`,
`delete-branch-on-merge`, `code-reviewer-auto-merge-workflow`,
`dependabot-auto-merge-workflow`. Confirmed by reading each `Check` function directly
(not the dashboard) — GitHub repo settings (`allow_auto_merge`, `delete_branch_on_merge`)
default `false` on a new repo, and none of `.circleci/config.yml`,
`.github/workflows/code-reviewer-auto-merge.yml`, `.github/workflows/dependabot-auto-merge.yml`
exist pre-scaffolding.

**Net effect of adding a README-only repo to configy as `system`: -1 finding
(`in-lucos-configy` clears) +6 new findings.** That's a net increase, not a reduction — the
exact opposite of the intended effect, and exactly the "load of audit issues" a "not
planning to work on this soon" repo owner is trying to avoid.

**Corrected guidance:** for a genuinely pre-scaffolding repo, leave it OUT of configy
entirely (matches the `lucas_architecture_models` precedent) regardless of whether its
eventual `type` is already settled by design. Type-ambiguity was never the real
disqualifier — the `AppliesTo` cascade is. Re-add only once real scaffolding (CircleCI
config + the two standard `.github/workflows/*` files + branch protection + repo settings)
exists, at which point those six conventions will pass on arrival instead of firing fresh
findings.

`dependabot-configured` and `fork-pr-contributor-approval` are NOT configy-gated (no
`AppliesTo` restriction — they run on every repo type including `Unconfigured`) and will
keep failing regardless of the configy decision. `fork-pr-contributor-approval` is still
safe/zero-risk to fix immediately via a direct GitHub API PUT to
`repos/{owner}/{repo}/actions/permissions/fork-pr-contributor-approval` — that part of the
original note was correct. See `new-repo-provisioning-script.md` for the full standup
script; still do NOT run its branch-protection step (step 8) on a pre-scaffolding repo.

Before recommending *any* configy addition as a fix for a single failing convention, check
whether the type change activates other conventions via their `AppliesTo` list — grep
`conventions/*.go` for `AppliesTo.*RepoTypeSystem` (or whatever type is being assigned) and
read each hit's `Check` function for what it fails on, not just the one convention that
prompted the question.
