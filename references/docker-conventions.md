# Docker & Docker Compose Conventions

## Container naming

- `container_name` must be set on every container
- Names must follow the pattern `lucos_<project>_<role>` (e.g. `lucos_photos_api`, `lucos_photos_postgres`)
- Single-container services typically use `_app` as the role

## Image naming (built containers only)

- Set `image:` on any container built from a Dockerfile
- Pattern: `lucas42/lucos_<project>_<role>` (e.g. `lucas42/lucos_photos_api`)

## Environment variables in compose

**Do not use `env_file`** — it breaks the CI build step.

Instead, declare every environment variable explicitly in the `environment` section using **array syntax**. This makes it clear which containers use which variables, and allows pass-through vars (sourced from the host environment / `.env` file) without specifying their values:

```yaml
environment:
  - SYSTEM                          # pass-through from host env
  - POSTGRES_PASSWORD               # pass-through from host env
  - POSTGRES_USER=photos            # hardcoded value
  - REDIS_URL=redis://redis:6379    # hardcoded value
```

Dictionary syntax cannot express pass-through vars without a value, so always use array syntax in `environment`.

Note: Docker Compose still reads `.env` for **compose-level** variable substitution (e.g. `${PORT}` in `ports:`) even without `env_file` — this is a separate mechanism and is fine to use.

## Build context

When multiple services share code (e.g. a shared Python package), set the build context to the repo root and specify the Dockerfile path explicitly:

```yaml
build:
  context: .
  dockerfile: api/Dockerfile
```

The Dockerfile can then `COPY shared/ /shared/` from the repo root.

## Volumes

Always declare every volume explicitly — both in the service's `volumes:` mount and in the top-level `volumes:` section. Never rely on anonymous volumes created implicitly by a Docker image's `VOLUME` directive.

Anonymous volumes don't receive Docker Compose project labels, which breaks `lucos_backups` monitoring.

```yaml
services:
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data        # explicit mount — never omit this

volumes:
  redis_data:                   # always declare at top level
```

Every named volume must also be added to **`lucos_configy/config/volumes.yaml`** with a description and `recreate_effort`. Docker Compose names volumes as `<project>_<volume_name>` (e.g. `lucos_photos_redis_data`). Valid `recreate_effort` values:

| Value | Meaning |
|---|---|
| `automatic` | Can be fully regenerated automatically |
| `small` | Small technical effort to recreate |
| `tolerable` | Loss would be tolerable |
| `considerable` | Considerable effort to recreate |
| `huge` | Huge effort / primary source data |
| `remote` | Remote mount from elsewhere — set `skip_backup: true` |

## Networking

- HTTP traffic is proxied through a shared Nginx reverse proxy; TLS is terminated externally
- Services are exposed on `${PORT}`, configured per-environment via lucos_creds
- Containers on the same Docker Compose network communicate via service name as hostname

## Restart policy

Always set `restart: always` on persistent service containers. Without it, containers stay down after a host reboot or `docker compose stop`. One-shot/batch containers (e.g. ingestors that run to completion) should use `restart: no`.

## Healthchecks

- Every service with a `build:` key in `docker-compose.yml` should have a `healthcheck:` defined (the `lucos_repos` convention check enforces this)
- **Always use `CMD-SHELL`** for healthchecks that need env var expansion (e.g. `${PORT}`). `CMD` array form skips the shell — `${PORT}` stays as a literal string.
- **Always use `127.0.0.1` not `localhost`** in Alpine-based containers. Alpine's musl libc resolves `localhost` to `::1` (IPv6) first. If the service only binds IPv4 (`0.0.0.0`), the healthcheck gets "Connection refused" and reports unhealthy even though the service is fine.
- Correct form: `test: ["CMD-SHELL", "wget -qO- http://127.0.0.1:${PORT}/_info"]`

## Alpine DNS gotcha

Docker service names with underscores may fail DNS resolution in Alpine containers (musl libc — RFC non-compliant hostname rejection). Workaround: set `hostname:` with a hyphenated name in docker-compose and map it in SSH config / application config.
