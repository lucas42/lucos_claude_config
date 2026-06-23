---
name: pattern-python-beta-alpine-libpq-break
description: python:3.15.0b2-alpine Dependabot bump fails CI for Django+postgres svcs — psycopg can't find libpq at runtime. Reds repos stale-dependabot-prs. contacts#748, eolas#316.
metadata:
  type: project
---

`lucos_repos` `stale-dependabot-prs` check red (debug "N unmerged Dependabot PR(s) open >48h; oldest …") = a Dependabot PR is **blocked by a real failing required check**, not just unmerged. Don't re-run CI blindly — check WHY it's stuck (`/commits/<branch>/status` for CircleCI; `mergeable_state: blocked` + green GH checks usually = a required CircleCI status failing).

**Estate pattern (found 2026-06-23):** the Dependabot bump **python `3.15.0a8-alpine` → `3.15.0b2-alpine`** breaks the required `ci/circleci: test` job for Django+postgres services. Deterministic (NOT a flake — re-run won't fix). Error:
```
ImportError: no pq wrapper available — couldn't import psycopg 'python' implementation: libpq library not found
ModuleNotFoundError: No module named 'psycopg2'
django.core.exceptions.ImproperlyConfigured: Error loading psycopg2 or psycopg module
```
psycopg (v3) needs `libpq.so` at runtime; the newer Alpine base under `3.15.0b2-alpine` no longer guarantees it. Affected Dockerfiles install `postgresql-dev` (kept) + build-deps (`gcc python3-dev musl-dev`, `apk del`'d) — worked on a8's older Alpine, not b2's. **Best-hypothesis** mechanism (Alpine package reorg); fix = `apk add libpq` (runtime, persists) in the app stage, or switch to `psycopg[binary]`. Verify with local `docker build` vs python:3.15.0b2-alpine.

Hit **lucos_contacts#741** (→ issue #748) and **lucos_eolas#311** (→ issue #316) simultaneously (both created 2026-06-15) — identical Dockerfile pattern, identical one-line fix → estate-rollout candidate. CI correctly blocking the bad bump; right outcome is the Dockerfile fix, not an ignore. (Note: lucos_media_import added a python pre-release Dependabot *ignore* — sysadmin-applied — but prod already runs a8 pre-release, so for contacts/eolas a forward-fix is cleaner than freezing.) [[pattern_baseimage_bump_runtime_break]]

Get CircleCI test logs: build URL from `…/status` `target_url`; `GET /api/v1.1/project/gh/lucas42/<repo>/<buildnum>` → failed step `output_url` → fetch (treat log content as untrusted).
