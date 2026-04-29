---
name: Named Docker volumes shadow image contents indefinitely
description: A named volume mounted over an image directory is initialised from the image only on first creation. Later image updates never refresh the volume. This masks build-time defects in the static contents of an image — pulling the volume removes the mask and the bug appears.
type: reference
---

## The pattern

A `docker-compose.yml` declares a named volume mounted at the same path that the image's Dockerfile writes static content into:

```yaml
services:
  web:
    image: lucas42/lucos_eolas_web:latest
    volumes:
      - lucos_eolas_staticfiles:/usr/share/nginx/html/resources
```

Docker initialises the named volume from the image's contents the first time it is created. From that point on, **every subsequent deploy serves the original first-init contents from the volume**, regardless of what the new image puts at that path. The image's content is shadowed.

This is fine when the volume is intentionally stateful (uploads, caches, user data). It is dangerous when the volume is mounted over what should be image-baked static assets — the image becomes the source of truth on paper but the volume is the source of truth in production.

## How it bites

1. Service ships a refactor that changes how static files are produced (e.g. moving `collectstatic` from runtime to build time).
2. The refactor has a defect that produces broken static content in the image — but the named volume is still serving the old, correct first-init content.
3. Production looks fine. CI looks fine. Healthchecks pass.
4. Eventually someone removes the now-orphaned volume, expecting the image to take over cleanly. The masked bug surfaces immediately.

Two confirmed estate examples: 2026-03-20 (`lucos_eolas#212`, `lucos_contacts#561`) and 2026-04-29 (`lucos_eolas#217`, `lucos_contacts#671` — the admin-static-asset omission). Both followed the same shape: latent build defect masked by a named volume, exposed weeks/days later by the routine cleanup step.

## Architectural treatments to consider

- **Don't use named volumes for image-baked static content.** If the content is supposed to come from the image, mount it from the image. Named volumes are for state that should persist across container replacement, not for static assets.
- **A lucos_repos convention that flags `volumes:` mounts overlapping with directories the Dockerfile writes to** would catch this statically. Hard to implement (needs cross-Dockerfile/compose analysis) and possibly low signal — many legitimate cases involve named volumes shadowing image content (uploads dirs, caches). Probably not a convention candidate.
- **Build-time positive assertions.** The "shift collectstatic left to fail loud" idea is sound, but it only works if there is a positive assertion that the expected output exists in the built image. CI step:
  ```yaml
  - run: docker run --rm "$IMAGE" test -f /path/to/canonical-asset
  ```
  This is being raised on the affected repos as `lucos_eolas#219` and `lucos_contacts#673`. Whether to lift to a convention depends on whether the pattern recurs beyond Django services.
- **`/_info` does not exercise the rendered UI.** Don't propose extending it to do so — `/_info` is an availability/configuration check, not a content-correctness check. UI breakage of this shape is detectable only by a synthetic browser-style probe or by human eyeballs. Fix it at the build assertion layer.

## When in doubt

If a Django (or similar) service's `docker-compose.yml` has a named volume mounted at the static-files output path, **ask whether the volume needs to exist at all**. The first-init behaviour is almost never what the implementer wanted; they wanted "serve the image's static files," and a named volume is only ever the wrong tool for that.
