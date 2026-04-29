---
name: Inter-image build dependencies in lucos multi-container repos
description: Use a single multi-target Dockerfile + build.target in compose; avoid :latest chaining and the bake-only target: scheme
type: reference
---

# Inter-image build dependencies in lucos multi-container repos

When a multi-container lucos repo needs one image to consume build artefacts from another (e.g. nginx image needs static files from app image), there are three plausible mechanisms. Only one works reliably across both `docker buildx bake` (CI) and `docker compose build` (local dev).

## ❌ Don't: `FROM lucas42/lucos_<repo>_<service>:latest`

Resolves to whatever `:latest` is currently published on Docker Hub at fetch time — i.e. the *previous* deploy's image. Reproduces the staleness bug at the image-layer level. This is the failure mode that caused lucos_contacts#668 / lucos_eolas#212.

## ❌ Don't: `additional_contexts: { app: "target:app" }`

The `target:` scheme is **bake-only**. `docker buildx bake` understands it (means "another target in the same bake invocation"), but plain `docker compose build` doesn't — Compose has no notion of a unified build graph and falls back to treating `target:app` as a filesystem path:

```
failed to get build context app: stat .../target:app: no such file or directory
```

So this works in CI but breaks `docker compose up --build` locally. Don't use it for cross-tool repos.

## ✅ Do: single multi-target Dockerfile + `build.target` in compose

Consolidate per-service Dockerfiles (`./app/Dockerfile`, `./web/Dockerfile`) into a single root `Dockerfile` with named target stages, and reference them via `build.target` in compose. `COPY --from=<stage>` between stages in the same Dockerfile is **standard multi-stage syntax** and supported identically by bake, buildx, and compose.

```dockerfile
# Dockerfile (at repo root)
FROM node:25-alpine AS ui-builder
# ...

FROM python:3.13-alpine AS app
WORKDIR /usr/src/app
COPY app/ .
RUN python manage.py collectstatic --noinput
CMD ["./startup.sh"]

FROM nginx:alpine AS web
COPY web/routing.conf /etc/nginx/conf.d/
COPY --from=app /usr/src/app/static /usr/share/nginx/html/resources
CMD ["nginx", "-g", "daemon off;"]
```

```yaml
# docker-compose.yml
services:
  app:
    build:
      context: .
      target: app
    image: lucas42/lucos_<repo>_app:${VERSION:-latest}
  web:
    build:
      context: .
      target: web
    image: lucas42/lucos_<repo>_web:${VERSION:-latest}
```

## Why this works for both tools

- `build.target` is a long-standing, universally-supported compose feature.
- `COPY --from=<stage>` is intra-Dockerfile — no cross-image, cross-tool, or cross-context coordination.
- BuildKit's stage cache is content-hashed: bake builds both targets in one run sharing the `app` stage; compose builds them sequentially and `web` finds `app`'s layers in the local cache from moments earlier.
- No `:latest` resolution, no registry round-trip, no `target:` scheme.

## Cost

Build context expands to the repo root, so a `.dockerignore` (excluding `.git`, `.github`, `.circleci`, `node_modules`, etc.) becomes important. Path-relative `COPY` lines need updating (`COPY .` → `COPY app/`). Two Dockerfiles → one. Sizeable refactor on existing repos but durable.

## Pragmatic fallback

If the consolidation refactor isn't worth the churn for a particular fix (e.g. the original issue is a small bug-fix), Option B from lucos_contacts#668 — keep the volume, collectstatic to a non-mount path at build time, `cp -rT` in `startup.sh` — is acceptable. The architectural objection (volume serves no real purpose) stands but is small.

## Related

- lucos_contacts#668 / lucos_eolas#212 (named volume shadowing build-time `collectstatic` output).
- I twice posted weaker recommendations on these issues before landing here: first `FROM <image>:latest` (caught by lucas42), then `additional_contexts: target:app` (caught by lucos-developer when the PR broke under `docker compose build`). The lesson: when proposing a build-graph fix, mentally execute it under both `docker buildx bake` AND `docker compose build` before posting. CI-only fixes break local dev silently.
