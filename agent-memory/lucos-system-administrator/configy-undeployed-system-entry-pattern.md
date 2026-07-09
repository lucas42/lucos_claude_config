---
name: configy-undeployed-system-entry-pattern
description: How to add a pre-scaffolding repo to lucos_configy without triggering monitoring or CI alerts
metadata:
  type: reference
---

For a brand-new repo whose eventual configy `type` (system/component/script) is already
settled by design (unlike a genuinely ambiguous case — see the `lucas_architecture_models`
precedent where type was unclear and I left it out entirely), it's safe to add it to
`lucos_configy/config/systems.yaml` immediately as a bare `null` entry (e.g. `lucos_foo:`
with nothing following, same as the existing `lucos_deploy_orb` and
`lucos_contacts_googlesync_import` entries) even before any deployment or CI exists.

**Why this is safe, verified from source (2026-07-09, lucas_worlds_atlas / lucos_configy#246):**

- `in-lucos-configy` audit convention (`lucos_repos/conventions/in-lucos-configy.go`) only
  checks presence + type classification, not deployment readiness or scaffolding.
- configy's `/systems/http` endpoint (`api/src/systems.rs::http()`) filters on
  `http_port.is_some()`. No `http_port` set → excluded from that feed.
- `lucos_monitoring`'s HTTP/`_info` fetcher (`fetcher_info.erl`) builds its target list from
  `configy.l42.eu/systems/http` at Docker build time (see monitoring's Dockerfile) and
  additionally skips any entry with no `domain`. So an entry with no domain/http_port is
  invisible to HTTP monitoring — no false "unreachable" alerts.
- `lucos_monitoring`'s CircleCI fetcher (`fetcher_circleci.erl`) reads the FULL `/systems`
  list (not `/systems/http`), so it does poll CircleCI for every configy-listed repo
  regardless of http_port/domain. But `checkCIForSlug/1` treats a 404 (no CircleCI project)
  as an explicit benign no-op (`#{}`, no check emitted) — not an alert. So a repo with no
  `.circleci/config.yml` yet is still safe to list.

**Two other audit checks are independent of configy and will still fire regardless**:
`dependabot-configured` (needs `.github/dependabot.yml`) and `fork-pr-contributor-approval`
(needs a GitHub API PUT). The latter is zero-risk to set immediately via
`repos/{owner}/{repo}/actions/permissions/fork-pr-contributor-approval` even on an empty
repo — no scaffolding dependency. See `new-repo-provisioning-script.md` for the full
standup script; do NOT run its branch-protection step (step 8) on a pre-scaffolding repo —
it requires a `ci/circleci: lucos/build` check that can't exist without
`.circleci/config.yml`, permanently blocking future PRs.
