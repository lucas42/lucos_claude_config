---
name: review-docker-healthchecks
description: Three Docker healthcheck pitfalls to check on every PR touching a healthcheck — localhost vs 127.0.0.1, missing tools in minimal base images, and wrong bind port.
metadata:
  type: feedback
---

**1. `localhost` vs `127.0.0.1`.** Always flag `localhost` in healthcheck URLs as blocking. On Alpine-based containers, `localhost` can resolve to `::1` (IPv6) instead of `127.0.0.1` (IPv4); if the service binds only IPv4, the healthcheck fails silently. Correct pattern: `http://127.0.0.1:<port>/_info`. Confirmed real failure via lucos_arachne#91; missed in lucos_contacts PR #533, required follow-up #534.

**2. Tool availability in minimal base images.** Don't assume `wget`/`nc`/`curl` are present — check the base image:
- `golang:N` — minimal Debian, does NOT include `nc` or `wget` (unlike `node:N`, which bundles `buildpack-deps`). Must install explicitly.
- `nginx:N` (Debian) — has `curl` but NOT `wget`. Use `curl --fail -s -o /dev/null <url>`. Confirmed: approved `wget` in lucos_router#22, required fix in #24.
- `openjdk:N-jdk-slim` — no `wget`/`curl` by default. Real production outage: lucos_arachne#277 (Fuseki 6.0.0 dropped `wget` from base image, healthcheck failed, containers stuck Created). Fix in lucos_arachne#278.
- `debian:*` minimal — no `wget`/`nc`/`curl` by default. Confirmed: lucos_creds#88 approved `nc` without verifying install, required fix #89.

**3. Verify the actual bind port.** For services not using `$PORT`, check `startup.sh`/CMD for the real bind port — don't assume from Dockerfile `EXPOSE` or base image name. Example: lucos_eolas `app` binds gunicorn on `:80` per `app/startup.sh`, not port 8000 — approved wrong port in lucos_eolas#80, required fix #84.
