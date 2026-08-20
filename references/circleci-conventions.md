# CircleCI Conventions

> **Enforced rules are linked here, never restated.** Any rule with an automated check in `lucos_repos` is defined in `lucos_repos/conventions/*.go` and rendered into the generated [convention catalogue](https://github.com/lucas42/lucos_repos/blob/main/docs/conventions.md). That catalogue is the single source of truth; this page links it. Everything below the enforced-conventions table is hand-written guidance with **no** enforcement counterpart — templates, platform notes, runbooks.
>
> **Editing this page?** If the rule has (or gains) a convention check, link its catalogue entry — do not paraphrase it. If it has no check, write it in the guidance half. Rationale: `lucos_repos` ADR-0007 — a hand-written copy of an enforced rule drifts silently from the check, and agents trust the doc over the source.

**Before concluding any lucos repo "has no test/build CI gate," check `.circleci/config.yml`, not just `.github/workflows/`.** CircleCI is this estate's primary build/test/deploy CI; GitHub Actions in most repos is limited to CodeQL and auto-merge automation, so `.github/workflows/` alone will look test-less even when a real, deploy-gating `test` job exists in CircleCI. Check both before asserting a CI coverage gap.

## Enforced conventions — link, don't restate

| Topic | Catalogue entry |
|---|---|
| A `.circleci/config.yml` exists | [`circleci-config-exists`](https://github.com/lucas42/lucos_repos/blob/main/docs/conventions.md#circleci-config-exists) |
| The lucos deploy orb is declared | [`circleci-uses-lucos-orb`](https://github.com/lucas42/lucos_repos/blob/main/docs/conventions.md#circleci-uses-lucos-orb) |
| `serial-group` on every `lucos/build*` and `lucos/deploy-*` job | [`circleci-deploy-serial-group`](https://github.com/lucas42/lucos_repos/blob/main/docs/conventions.md#circleci-deploy-serial-group) |
| Exactly one `lucos/deploy-<host>` job per host configured in configy | [`circleci-system-deploy-jobs`](https://github.com/lucas42/lucos_repos/blob/main/docs/conventions.md#circleci-system-deploy-jobs) |
| Components publish via a `lucos/release-*` job | [`circleci-has-release-job`](https://github.com/lucas42/lucos_repos/blob/main/docs/conventions.md#circleci-has-release-job) |
| No `release-*`/`deploy-*` jobs on other repo types | [`circleci-no-forbidden-jobs`](https://github.com/lucas42/lucos_repos/blob/main/docs/conventions.md#circleci-no-forbidden-jobs) |
| `test*`/`build*` jobs are required status checks on `main` | [`circleci-jobs-in-required-checks`](https://github.com/lucas42/lucos_repos/blob/main/docs/conventions.md#circleci-jobs-in-required-checks) |

Each entry carries the rule, its rationale and the suggested fix, generated from the check itself. Read the entry — and `lucos_repos/conventions/<id>.go` behind it — before changing a config; the check is what gates the audit, not the templates on this page.

**Before removing a `serial-group` as "non-standard", read [`circleci-deploy-serial-group`](https://github.com/lucas42/lucos_repos/blob/main/docs/conventions.md#circleci-deploy-serial-group) first.** Both the build serial-group and the deploy serial-group are required, and they take different forms; each has previously been dropped by an editor working from a doc rather than the source.

---

The rest of this page is guidance. None of it has an automated check.

## Pipeline trigger behaviour

**Every push to any branch triggers a full pipeline.** CircleCI does not support file-path filtering — there is no equivalent of GitHub Actions' `paths:` filter. Any file change, regardless of type (application code, config files, `dependabot.yml`, documentation), will trigger a full build pipeline on push and a full build + deploy pipeline on merge to main.

When planning estate-wide rollouts or any bulk merge operation, assume that every merge will trigger a CI pipeline. Stagger merges accordingly — see the estate-rollout skill for guidance.

## Platform selection

The `platform` value for `lucos/build` must match the actual deploy targets — do not copy the dual-arch default unless the service genuinely deploys to both avalon and xwing/salvare.

| Deploy target(s) | `platform` value | Notes |
|---|---|---|
| avalon only (`linux/amd64`) | *(omit)* | Orb default: builds amd64-only. No wasted arm64 build. |
| xwing and/or salvare only (`linux/arm64`) | `platform: "linux/arm64"` | Both xwing and salvare are aarch64. |
| avalon + xwing/salvare (both arches) | `platform: "linux/amd64,linux/arm64"` | Dual-arch build only when required. |

If `platform` is omitted, the orb's default builds an amd64-only image (CI runners are x86_64).

## Standard config templates

These are worked examples, not the rule. Where a template shows something the audit enforces — the orb declaration, the `serial-group` values, the set of deploy jobs — the catalogue entry above is authoritative and a template that has fallen behind it is a bug in this page.

When a project has no tests, the standard `.circleci/config.yml` is:

```yaml
version: 2.1
orbs:
  lucos: lucos/deploy@0
workflows:
  version: 2
  build-deploy:
    jobs:
      - lucos/build:
          serial-group: << pipeline.project.slug >>/build/<< pipeline.git.branch >>
      - lucos/deploy-avalon:
          serial-group: deploy-avalon
          requires:
            - lucos/build
          filters:
            branches:
              only:
                - main
```

When a project has tests, add a `test` job running **in parallel** with `lucos/build`; both must pass before deploy. Tests run on all branches (no filter), deploy only on `main`.

**Self-contained tests** (e.g. FastAPI + SQLite in-memory — no real DB or env file needed):

```yaml
jobs:
  test:
    docker:
      - image: cimg/python:3.14
    steps:
      - checkout
      - run:
          name: Install dependencies
          command: pip install -e shared/ -r api/requirements.txt -r api/requirements-test.txt
      - run:
          name: Run tests
          command: cd api && pytest
workflows:
  version: 2
  build-deploy:
    jobs:
      - test
      - lucos/build:
          serial-group: << pipeline.project.slug >>/build/<< pipeline.git.branch >>
      - lucos/deploy-avalon:
          serial-group: deploy-avalon
          requires:
            - test
            - lucos/build
          filters:
            branches:
              only:
                - main
```

**Tests needing a real database** (e.g. Django — see lucos_contacts for full example): use `cimg/base:current` + `setup_remote_docker`, fetch a test `.env` from `creds.l42.eu:<repo>/test/.env`, and run via `docker compose --profile test up test --build --exit-code-from test`.

- The `lucos/build` job builds and pushes Docker images
- The `lucos/deploy-avalon` job deploys to the server, but only on `main`
- The CI build step has access to a dummy `PORT` only — no other env vars are available during build

## Android CI

Android `release-apk` jobs need `cimg/android:2025.01-node` (not the base image) — the `-node` variant includes Node.js for `npx`/`lucos/calc-version`.

## CircleCI API Access

A CircleCI Personal API Token is available in `~/sandboxes/lucos_agent/.env` as `CIRCLECI_API_TOKEN` (pulled from lucos_creds).

Use v2 API with basic auth:
```bash
source ~/sandboxes/lucos_agent/.env && curl -s -u "$CIRCLECI_API_TOKEN:" "https://circleci.com/api/v2/..."
```

Authenticated as `lucas42` (user ID `a1cc5f79-b635-4772-800d-3001f47aa9ee`).

**Important**: `source .env` includes surrounding quotes in variable values. Use this to extract cleanly:
```bash
TOKEN=$(grep CIRCLECI_API_TOKEN ~/sandboxes/lucos_agent/.env | cut -d'"' -f2)
```

### Useful v2 API calls

Check pipeline status:
```bash
curl -s -H "Circle-Token: $TOKEN" "https://circleci.com/api/v2/project/github/lucas42/{repo}/pipeline?branch=main"
```

Retry a failed workflow:
```bash
curl -H "Circle-Token: $TOKEN" -H "Content-Type: application/json" \
  -X POST "https://circleci.com/api/v2/workflow/{workflow_id}/rerun" \
  -d '{"from_failed": true}'
```

Check CI status for public repos (no auth needed):
```bash
curl -s "https://circleci.com/api/v1.1/project/github/lucas42/{repo}?limit=3&filter=completed"
```
