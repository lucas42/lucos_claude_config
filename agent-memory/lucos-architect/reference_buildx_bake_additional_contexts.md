---
name: docker buildx bake additional_contexts pattern
description: Robust mechanism for inter-image build dependencies in lucos multi-container repos — avoids :latest race conditions
type: reference
---

# `docker buildx bake` + `additional_contexts` for inter-image build dependencies

When a multi-container lucos repo needs one image to consume build artefacts from another (e.g. nginx image needs static files from app image), do **not** use `FROM lucas42/lucos_<repo>_<service>:latest` in the dependent Dockerfile. That resolves to whatever `:latest` is currently published on Docker Hub at fetch time — i.e. the *previous* deploy's image. This is exactly the "stale image layer" failure mode that caused lucos_contacts#668 / lucos_eolas#212.

**Use bake's named build contexts instead.** This is a build-graph dependency, not a registry pull.

## Mechanism

The lucos deploy orb's `publish-docker.yml` invokes:

```
docker buildx bake -f docker-compose.yml <all-targets-with-build-block>
```

…in a single call. Bake reads inter-target dependencies from `docker-compose.yml`'s `build.additional_contexts` field and orders the build graph automatically.

## Compose syntax

```yaml
services:
  app:
    build: ./app
    image: lucas42/lucos_<repo>_app:${VERSION:-latest}
  web:
    build:
      context: ./web
      additional_contexts:
        - "app=target:app"   # array form, widely supported
    image: lucas42/lucos_<repo>_web:${VERSION:-latest}
```

## Dockerfile syntax

```dockerfile
FROM nginx:alpine
COPY --from=app /usr/src/app/static /usr/share/nginx/html/resources
```

`app` here is the **named local context** (the target being built in this bake run), not a Docker Hub tag. No registry round-trip.

## Why this is robust

- Bake holds the `app` target's filesystem locally and feeds it into `web`'s `COPY --from=` — no push needed first.
- No `:latest` resolution anywhere in the build graph. No race between concurrent CI runs.
- Other targets (e.g. `test`) without dependencies on `app` still parallelise.
- Multi-platform builds (`platform: linux/amd64,linux/arm64`) are unaffected.

## Caveat

`additional_contexts` requires **Compose v2.17+** for compose to honour it (bake itself supported `target:` contexts earlier). The CircleCI `cimg/node:current` image ships a recent enough buildx/compose, so this works in CI today. Still worth a `docker compose version` sanity-check in any PR introducing it.

## Related

Came up resolving lucos_contacts#668 / lucos_eolas#212 (named volume shadowing build-time `collectstatic` output). The architectural fix was to drop the volume and have nginx COPY static files from the app image at build time — and `additional_contexts` is the correct way to wire that up.
