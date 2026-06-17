# CircleCI Conventions

## Pipeline trigger behaviour

**Every push to any branch triggers a full pipeline.** CircleCI does not support file-path filtering — there is no equivalent of GitHub Actions' `paths:` filter. Any file change, regardless of type (application code, config files, `dependabot.yml`, documentation), will trigger a full build pipeline on push and a full build + deploy pipeline on merge to main.

When planning estate-wide rollouts or any bulk merge operation, assume that every merge will trigger a CI pipeline. Stagger merges accordingly — see the estate-rollout skill for guidance.

## Standard configs

## Serial-group requirements (enforced by `circleci-deploy-serial-group` audit convention)

Both `lucos/build*` and `lucos/deploy-*` jobs **must** declare a `serial-group`. The convention source is `lucos_repos/conventions/circleci-deploy-serial-group.go` — it is the authoritative check, not these templates. Before removing either serial-group as "non-standard", verify against that source first.

| Job | Required `serial-group` | Why |
|---|---|---|
| `lucos/build` (and any `lucos/build*`) | `<< pipeline.project.slug >>/build/<< pipeline.git.branch >>` | Prevents concurrent pipelines from computing the same `VERSION` and overwriting each other's Docker images. Branch-scoped form lets PR builds run in parallel without blocking behind `main`. |
| `lucos/deploy-avalon` | `deploy-avalon` | Prevents concurrent deploys to the same host from racing in containerd (blob-lease conflicts observed 2026-04-21). |

Note: the deploy serial-group is the bare form (`deploy-avalon`) — **not** prefixed with `<< pipeline.project.slug >>`.

---

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
          platform: "linux/amd64,linux/arm64"
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
          platform: "linux/amd64,linux/arm64"
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
