---
name: Named volume shadows image contents at mount path
description: Docker pattern — moving a build artifact into the image breaks if the same path is mounted as a named volume; the volume one-time-init never refreshes
type: project
---

**Diagnostic pattern: named volume on a path with build-time content.** When a Docker image bakes content into a path (e.g. `RUN python manage.py collectstatic` writing to `/usr/src/app/static`) **and** docker-compose mounts a named volume at that same path, the image's content is only used to seed the volume **the first time the volume is empty**. Every subsequent container start re-attaches the existing volume and silently shadows whatever is in the image at that path — even if the image has been updated.

This is the Docker named-volume init semantics: `docker run -v myvol:/path image` copies image contents into `myvol` only when `myvol` is first created (or empty). After that, the volume is treated as authoritative.

**Surface symptom**: visible content (CSS, JS, static assets, configuration files) frozen on the date of the first deploy after the build-artifact-into-image change. Subsequent image updates appear to deploy fine but users see no change.

**How to confirm in 30 seconds**:
```bash
# What's in the running container's mounted volume:
docker exec <container> stat /path/to/asset

# What's actually in the latest image:
docker run --rm --entrypoint='' <image>:latest stat /path/to/asset
```
If timestamps and file sizes differ, the volume is shadowing the image. Compare with what end-users see (`curl ...` against the public URL) to confirm the volume is what's being served.

**Mitigation (one-off, production)**:
```bash
docker run --rm -v <project>_<volname>:/refresh <image>:latest \
    sh -c 'cp -rT /path/in/image /refresh'
docker restart <web_container>
```
The trick is mounting the volume at a path that is NOT the image's content path, so the volume contents don't shadow what you're trying to copy.

**Permanent fix** (preferred): drop the named volume. Use a multi-stage build to bake the static files into whichever container needs to serve them (e.g. nginx in lucos's app/web split). No shared state, no shadowing.

**Permanent fix** (minimal change): in the Dockerfile, write build artifacts to a path that is NOT the volume mount path (e.g. `_static/`). In `startup.sh`, `cp -rT /path/in/image /volume/path` before the main command. Restores per-start volume refresh at minimal CPU cost (a `cp -r` over a few hundred KB, not a full collectstatic).

**Where this hit**: 2026-03-20 across lucos_contacts (#561, then #668) and lucos_eolas (#98, then #212). Both repos moved Django `collectstatic` from `startup.sh` to the Dockerfile to reduce startup CPU spikes — both repos kept their named `staticfiles` volume mounted at the collectstatic target path. Result: 5+ weeks of stale CSS/JS/lucos_navbar.js served to end users on `contacts.l42.eu` and `eolas.l42.eu`. Discovered when lucos-ux noticed CSS changes from PR #667 didn't appear locally on `docker compose up`.

**How to avoid in code review**: any PR that moves a step from `startup.sh` (or equivalent runtime script) into the `Dockerfile` build steps is suspect if the target path of that step is also listed in `docker-compose.yml`'s `volumes:` section. Ask: "is this path mounted as a named volume in production?" — if yes, the build-time output will be shadowed.

**Removing the volume can EXPOSE a second bug** (not just unmask the first). 2026-04-29 sequel: the eolas/contacts consolidation PRs (`lucos_eolas#213`, `lucos_contacts#669`) introduced a build-time `collectstatic` that was itself broken — `settings_collectstatic.py` only declared `django.contrib.staticfiles` in `INSTALLED_APPS`, so `collectstatic` silently skipped the entire `django.contrib.admin` static tree. The bug shipped fine because the still-mounted `*_staticfiles` named volume from the original 2026-03-20 incident contained a complete admin asset tree from the OLD runtime collectstatic. When the orphaned volumes were removed (per `#214`/`#670`), nginx fell back to the image — which had no admin CSS — and every page rendered unstyled. **6.5 hours of user-visible breakage.**

**Operational rule for "remove the orphan volume" cleanup tickets**: before removing a volume that's been masking a content-path, verify the new image *actually contains* what the volume contains. The cheap check:

```bash
# What's in the volume right now (the masking copy):
docker run --rm -v <project>_<volname>:/in alpine ls -la /in/admin/css 2>/dev/null

# What's in the latest image at the same path:
docker run --rm <image>:latest ls -la /usr/share/nginx/html/resources/admin/css 2>/dev/null
```

If the image-side path is empty or missing files the volume has, do NOT remove the volume — file an issue against whoever owns the build step and wait for the fix. Recorded in incident report `2026-04-29-eolas-contacts-styling-lost.md`.
