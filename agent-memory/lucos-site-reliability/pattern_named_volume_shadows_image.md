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

---

## Variant 2 — image symlinks frozen in shared volume, resolve per-container

A 2026-05-07 sequel showed a different facet of the same root cause. When the path the image owns contains a **symlink** (e.g. `nginx:alpine` ships `/var/log/nginx/access.log -> /dev/stdout` and `error.log -> /dev/stderr`), and a named volume is mounted at the parent directory, those symlinks get copied verbatim into the new volume on first init. They look like real symlinks afterwards, but `/dev/stdout` resolves at `open()` time **in the resolving process's namespace**.

If two containers share the volume — one writer (nginx in `web`) and one reader (a sidecar reading "the log file" via the volume) — the writer gets its own stdout (which is what nginx wants anyway), and the reader gets *its own* stdout, a stream that has no other writers and never reaches EOF. `for line in f:` blocks forever. Worker timeouts, healthcheck cascade.

Hit 2026-05-07 on `lucas42/lucos_docker_mirror#57` (the `_metric_pull_rate()` canary): worker timeout cascade in info sidecar took out `/_info` and tripped `docker.l42.eu` + `schedule-tracker / lucos_docker_health_avalon` for ~33 minutes. Reverted in `lucas42/lucos_docker_mirror#58`. Re-implementation tracked in `lucas42/lucos_docker_mirror#59`. Full incident: `lucas42/lucos/docs/incidents/2026-05-07-docker-mirror-canary-symlink-trap.md`.

**How to confirm in 30 seconds**:
```bash
docker exec <reader_container> ls -la <mounted_path>/
# Look for symlinks-to-/dev/{stdout,stderr,null}
```

**Diagnostic signature in logs**:
- Reader's gunicorn / equivalent logs show `[CRITICAL] WORKER TIMEOUT` followed by traceback ending at the line that iterates the file.
- Mirror traffic / actual service work continues unaffected — only the metric/log-reading code path is dead.

**How to avoid in code review**: any PR that mounts a named volume on top of a path the image controls AND has another container reading from that volume — list the mount path's contents (`docker run --rm <image> ls -la <path>`) and look for symlinks-to-`/dev/...`. If any are present:
1. Either overlay-mount only the specific real files, not the directory, OR
2. Explicitly remove/replace the symlinks in the entrypoint before any reader tries to read (`rm -f /var/log/nginx/access.log` before `exec nginx`)
3. Make the reader code defensive with `stat.S_ISREG()` so a non-file at the path becomes a benign default rather than a hang.

**Common lesson**: volume init is a *snapshot, not a live mirror*. Anything in the snapshot — stale build output, old static files, frozen symlinks — becomes a per-volume liability that outlives any image rebuild. When designing any sidecar/sharing pattern with named volumes, the first question is: **what's at this mount path *in the image at first init*?** Whatever's there is going to be in the volume forever (or until someone explicitly cleans it).
