# Docker `Healthy` ≠ end-to-end working

Docker's `Healthy` container status proves only that the specific command the `healthcheck:` runs returned exit 0. It says nothing about whether the service is reachable, whether its dependencies are up, or whether its network plane is intact. When the failure mode is in a plane the healthcheck doesn't traverse, `Healthy` survives while the service is broken.

This pattern has been the load-bearing misclassification in two lucos incidents within three weeks:

- **2026-05-28 xwing network flush** — five of six containers reported `Healthy` while every one was orphaned from its Docker network and externally unreachable. Their healthchecks were loopback-internal (`wget http://127.0.0.1:PORT/_info`) and didn't traverse the broken network plane. See [`docs/incidents/2026-05-28-xwing-network-flush-orphaned-containers.md`](https://github.com/lucas42/lucos/blob/main/docs/incidents/2026-05-28-xwing-network-flush-orphaned-containers.md).
- **2026-05-09 lucos_creds CRLF** — `lucos_creds_configy_sync` reported `Healthy` for ~2 hours while its SSH key was being rejected by `libcrypto`. The healthcheck was `test -p /var/log/cron.log` — it verified the cron daemon's named pipe existed and nothing more. See [`docs/incidents/2026-05-09-creds-ssh-key-crlf.md`](https://github.com/lucas42/lucos/blob/main/docs/incidents/2026-05-09-creds-ssh-key-crlf.md).

---

## Two distinct failure modes

Understanding which failure mode you're dealing with determines which side of this rule applies.

### Failure Mode A — Service-level dependency failure

The container is running and connected to its network, but an upstream dependency (database, cache, volume mount, auth backend) is broken. The container is alive; the service isn't functional.

**Who can catch it:** The healthcheck author, by probing the actual dependency rather than just the HTTP server. The `curl /_info` verifier probe also catches this if `/_info` exercises a DB query or similar.

**Author-side fix:** Design the healthcheck to exercise the dependency most likely to fail invisibly.

### Failure Mode B — Network-plane corruption

The container's own network stack is intact (loopback works), but the Docker bridge network it's attached to is corrupted, orphaned, or missing. From inside the container everything looks fine; from outside, the container is unreachable.

**Who can catch it:** External verification only. No container-internal healthcheck command can detect this — loopback is in the container's own network namespace and works regardless of the Docker bridge state.

**Verifier-side fix:** External `curl` from outside the host.

---

## Author-side guidance (Failure Mode A)

A healthcheck that only tests the HTTP server's loopback (`wget http://127.0.0.1:PORT/_info`) is necessary but not sufficient for services with hard external dependencies.

**If your service has a hard dependency that, if broken, would leave the service silently non-functional — add an explicit probe of that dependency to your healthcheck.**

### Good examples from the lucos estate

**`lucos_photos` — Redis ping:**
```yaml
healthcheck:
  test: ["CMD-SHELL", "python -c \"import redis, os; r = redis.from_url(os.environ['REDIS_URL']); r.ping()\""]
  interval: 30s
  timeout: 5s
  retries: 3
```
Explicitly probes the cache dependency rather than just the HTTP server. If Redis is down, `Healthy` correctly flips to `(unhealthy)`.

**`lucos_media_metadata_api` — RDF freshness:**
```yaml
healthcheck:
  test: ["CMD-SHELL", "find \"$$RDF_OUTPUT_PATH\" -mmin -120 | grep -q ."]
  interval: 60s
  timeout: 10s
  retries: 3
```
Probes mounted-volume access and pipeline freshness (file modified within last 2 hours). Catches a stale or missing output file — the invisible failure mode for this service.

### What a loopback-only check misses

```yaml
# Catches: HTTP server not started, port wrong, application crash at startup
# Misses: database unreachable, Redis down, volume unmounted, SSH key rejected, network-plane broken
healthcheck:
  test: ["CMD-SHELL", "wget -qO- http://127.0.0.1:${PORT}/_info"]
```

A loopback-only healthcheck is correct for genuinely stateless HTTP services with no hard external dependencies. For everything else, add an explicit dependency probe alongside it.

**Note on accidental DNS detection:** `lucos_static_media`'s healthcheck happened to catch the 2026-05-28 network-plane failure because its HTTP probe triggered outbound DNS (which requires the Docker embedded DNS, which depends on the network bridge). This was coincidence, not design. Do not deliberately design healthchecks to rely on DNS resolution as a proxy for network-plane health — it creates spurious `(unhealthy)` transitions on any transient DNS blip.

### Convention check

`lucos_repos` convention `docker-healthcheck-on-built-services` catches services with **no healthcheck at all** (fail). The companion `loopback-only-healthcheck` convention (see [lucas42/lucos_repos#404](https://github.com/lucas42/lucos_repos/issues/404)) warns on healthchecks that are purely loopback — automated coverage for the most mechanical case of Mode A.

---

## Verifier-side guidance (Failure Mode B)

When verifying that a docker-daemon change, network-state change, or `docker0` operation succeeded, **always** supplement `docker ps` status with external probes:

| Check | What it proves |
|---|---|
| `curl https://<domain>/_info` from outside the host | Functional end-to-end reachability through the full stack |
| `sudo iptables -L DOCKER -n` (one DNAT per published port) | docker-proxy wiring is in place (structural proof) |
| `ps aux \| grep docker-proxy` (when sudo unavailable) | Port-publishing processes exist (fallback structural check) |
| `docker network ls` shows `bridge`/`host`/`none` + declared networks | Docker's network DB is intact — built-ins always present on a working daemon |

`docker ps` Status, healthcheck conclusions, and `ip route` checks are necessary-but-not-sufficient — they can all pass while the service is completely unreachable.

**`docker network ls` returning empty is never benign.** The default `bridge`, `host`, and `none` networks are always present on a working daemon. Their absence means the network database is corrupted, and any containers that reference user-defined networks are orphaned (`NetworkID` populated, `EndpointID` empty, no docker-proxy publishing ports).

For HTTP services, the external `curl /_info` probe is the authoritative end-to-end check. `monitoring.l42.eu/api/status` is also authoritative — consult it before declaring any host-change issue closure-ready.
