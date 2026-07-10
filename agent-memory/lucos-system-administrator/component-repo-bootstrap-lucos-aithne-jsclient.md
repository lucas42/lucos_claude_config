---
name: component-repo-bootstrap-lucos-aithne-jsclient
description: Bootstrapping a JS/library Component repo — configy list, first-release gotcha, provisioning script fix
metadata:
  type: reference
---

Confirmed while bootstrapping `lucos_aithne_jsclient` (2026-07-10, lucas42/lucos#264):

**Libraries go in `config/components.yaml`, never `systems.yaml`.** `systems.yaml` entries feed
`lucos_monitoring`'s HTTP checks and the CircleCI-fetcher's project-existence check — both
assume a deploy target. A library has none. Precedent already in `components.yaml`:
`lucos_loganne_pythonclient`, `lucos_navbar`, `lucos_pubsub`, `lucos_search_component`,
`lucos_time_component`. See [[configy-undeployed-system-entry-pattern]] for why sequencing
matters (scaffold fully *before* adding to configy, regardless of which list).

**Best precedent for a pure JS library component (no Docker, no test job yet):**
`lucos_pubsub` — `.circleci/config.yml` has only `lucos/release-npm` (no `lucos/build`, no
`test` job), branch protection requires only `Analyze (javascript)` (no `ci/circleci: test`
context, since there's no PR-triggered CircleCI job at all). 0 open audit findings at time of
check — safe to copy verbatim. `lucos_navbar` is NOT a clean precedent for a pure library —
it also builds a Docker image (`release-npm-and-docker`), so its required-checks list
includes `ci/circleci: test` for a job pubsub doesn't have.

**Gotcha: a Component repo's very first CircleCI release always publishes**, even if the
triggering commit is pure scaffolding (CI config, package.json skeleton, no real code).
`check-npm-release-needed` (lucos_deploy_orb ADR-0003) only skips a release when a prior
`v*` tag exists to diff against — "no previous tag → first release, proceeding with publish"
is unconditional. Net effect: scaffolding a Component repo pushes a real `v1.0.0` (or
whatever calc-version computes) to npmjs.org containing whatever placeholder code exists at
that commit — in this case just `export {}`. Low-risk (nothing depends on a brand-new
package yet) but worth flagging explicitly to whoever drives the next real-content PR: they
are NOT publishing v1.0.0, that version is already taken by the placeholder.

**`fetch-publish-creds` (the `scp ... docker-deploy@creds.l42.eu:lucos_deploy_orb/publish/.env`
step in `release-npm`/`release-pip`) worked with zero extra provisioning** — no CircleCI
project-level SSH key setup was needed for this brand-new repo. Contradicts my prior
assumption (carried over from deploy-avalon's Docker SSH key convention) that a human-held
CircleCI SSH key step is required per new repo. Either this key is org/context-scoped in
CircleCI rather than per-project, or `fetch-publish-creds` doesn't need the "SSH Keys" UI
step at all. Unverified which — but empirically, for a Component using only
`release-npm`/`release-pip`, no lucas42 action was needed here. Re-verify if a future
release-npm job fails on this step before assuming it needs the same manual key add as
deploy-avalon.

**`~/.claude/scripts/provision-repo-ci-secrets.sh` fixed 2026-07-10**: step 8 (branch
protection) hardcoded `ci/circleci: lucos/build` as the required check, which is wrong for
any Component repo (release-only, no build/deploy job). Script now accepts optional extra
CLI args to override the required-check list, e.g.:
`provision-repo-ci-secrets.sh lucos_aithne_jsclient "Analyze (javascript)"`. Use this for
every future release-npm/release-pip-only Component bootstrap — don't let branch protection
land requiring a check name that will never fire.

**My app's `permissions` field on `GET /repos/{owner}/{repo}` showed all-`false`
(admin/push/pull) for a repo I could in fact merge into** (confirmed by successfully calling
`PUT .../pulls/1/merge`). Don't trust that field to predict write access — test the actual
operation (or check org/app installation permissions directly) rather than pre-emptively
flagging a permissions blocker to the coordinator. Ties to
[[feedback_verify_permission_claims]].
