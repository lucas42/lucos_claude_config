---
name: lucos_worlds
description: lucos_worlds (BookStack wrapper) structure, patch mechanism, test harness, and local dev auth
metadata:
  type: project
---

lucos_worlds is a thin Docker wrapper around `lscr.io/linuxserver/bookstack` (pinned version in `Dockerfile`). Source lives in `~/sandboxes/lucos_worlds`.

**BookStack patch mechanism** (established by the ES256 OIDC patch, ADR-0002, extended for lucas42/lucos_worlds#52): whole-file replacements under `patches/<mirrors-bookstack-app-tree>/`, `COPY`'d over the upstream file at build time in the `Dockerfile` (safe because `/app/www` is NOT the persistent `/config` volume — a plain build-time `COPY` is sufficient, no custom-cont-init runtime copy needed). Each patch gets an explanatory comment block in the Dockerfile (rationale + issue number) plus an in-file docblock comment right above the changed code (see `patches/Entities/Page.php`, `patches/Oidc/*.php`). Framing: "narrow, intentional fork of this file, not general BookStack maintenance."

To get the exact upstream source for a new patch: clone/checkout BookStackApp/BookStack at the exact tag matching the Dockerfile's pinned version (e.g. `git show v26.05.2:app/Entities/Models/Page.php`), don't rely on `development` branch HEAD (usually a few trivial commits ahead, but verify with `git diff <tag> HEAD -- <file>` first).

**Test harness pattern** (`test/unit-*/`): a standalone PHPUnit test with NO Laravel app boot — bare `new SomeModel()` + attribute assignment works fine for Eloquent models outside a booted framework as long as you don't touch relations/DB. `build-and-run.sh` does a two-stage docker build: (1) build the real production `Dockerfile` itself as a base image, (2) a thin `unit.Dockerfile` layer that just COPYs the test file in, then runs it with the image's own vendored `vendor/bin/phpunit`. This must be a build-time COPY, not a docker-compose bind-mount, because CircleCI's `setup_remote_docker` runs the Docker daemon on a separate remote host with no access to the job's checked-out files. Wire new test jobs into `.circleci/config.yml` (job + require it in `deploy-avalon`'s `requires:`).

**Local dev**: `docker compose up -d --build`, port from `.env`'s `PORT` (8040 as of 2026-07). Dev uses BookStack's standard auth (`AUTH_METHOD=standard` in dev creds), NOT OIDC — login is `admin@admin.com` / `password`, auto-seeded on first migration. To create content via curl (no browser needed for server-rendered-HTML verification): login gets a CSRF token from `name="_token" value="..."` in any form page; book create is `POST /books`; page create is a two-step `GET /books/{slug}/create-page` (redirects to a draft URL `/books/{slug}/draft/{id}`) then `POST` to that same draft URL with `name` + `html` fields to publish. Grid vs list view is a server-side **user preference** (`PATCH /preferences/change-view/books`), not a URL query param — a `?view=grid` query string is silently ignored.

**BookStack search gotcha (pre-existing, not a lucos patch issue)**: the advanced/full search page's query param is `?search=`, not `?term=` (that's only the header quick-search suggestion box's input name). Also observed a few individual terms not matching via full-text search that plausibly should have (e.g. "Second"/"Third" in a 3-item list didn't match while "First"/"item" did) — didn't chase root cause since out of scope for [[lucos_worlds_page_excerpt_fix]]; worth a closer look if search completeness is ever the actual task.

Related: [[lucos_worlds_page_excerpt_fix]]
