# Network Topology

This document describes the actual network topology of the lucos production environment. It exists to correct a common misconception: **there is no trusted internal network between services.** Agents must not use "internal network" as a security mitigation.

---

## Production Hosts

There are two active internet-facing hosts (source: `lucos_configy/config/hosts.yaml`):

| Host | IP | Role |
|---|---|---|
| `avalon` | 178.32.218.44 | Primary — runs the vast majority of services |
| `xwing` | 152.37.104.10 | Secondary — static media, media players, private |

`salvare` is also active (IPv6/NAT only) and runs `lucos_media_linuxplayer` and `lucos_docker_health`. `virgon-express` is inactive (physically disconnected).

---

## How Inbound Traffic Reaches Services

Each host runs `lucos_router` — a Dockerised Nginx reverse proxy that:

1. Listens on ports 80 and 443 (TLS termination via Let's Encrypt)
2. Fetches domain→port mappings from `configy.l42.eu`
3. Proxies requests to `http://172.17.0.1:<PORT>` — the Docker bridge gateway IP, which reaches the host's own network stack

Each service binds its `$PORT` to the host's network interfaces. The router container reaches those services via the Docker bridge gateway.

**Key consequence:** the router is the intended entry point for all HTTP/HTTPS traffic, but **there is no host-level firewall**. Service ports are directly reachable from the public internet. For example, `http://178.32.218.44:8019/_info` (loganne) returns a 200 response — any internet client can reach it directly without going through nginx. The router provides TLS and domain routing, not access control. **Application-level auth (`CLIENT_KEYS`) is the only real protection for any service endpoint.**

---

## Inter-Service Communication

**Services communicate with each other via their public HTTPS URLs — always.**

This applies even when two services run on the same host. For example, `lucos_arachne_ingestor` calls `https://contacts.l42.eu`, not `http://localhost:8013`. There is no shortcut, no private channel, and no special routing for same-host calls.

Example from `lucos_arachne/docker-compose.yml`:
```yaml
environment:
  - KEY_LUCOS_CONTACTS
  # uses https://contacts.l42.eu — not a local address
```

Example from `lucos_media_manager/docker-compose.yml`:
```yaml
environment:
  - MEDIA_API=https://media-api.l42.eu
```

**There is no VPN, private LAN, or internal routing between services.** Traffic between services travels via the public internet, through the other service's TLS endpoint and auth layer.

---

## Intra-Service Container Networking (Docker Compose stacks)

Some services are multi-container Compose stacks (e.g. `lucos_arachne`, `lucos_photos`, `lucos_creds`). Within a stack:

- Containers share a Docker Compose default bridge network
- They communicate by **service name** as hostname (e.g. `redis://redis:6379`, `http://triplestore:3030`)
- **Only the "front door" container has a `ports:` mapping** to the host — internal containers (Postgres, Redis, Fuseki, Typesense) are not directly reachable from outside the stack

This **is** a meaningful isolation boundary — but it only applies within a single Compose stack. It does not extend between stacks or between services.

| Service | Exposed to host | Not exposed (internal only) |
|---|---|---|
| `lucos_arachne` | `web` (port $PORT) | `triplestore`, `search`, `ingestor`, `explore`, `mcp` |
| `lucos_photos` | `api` (port $PORT) | `postgres`, `redis`, `worker` |
| `lucos_creds` | `lucos_creds_ui` (port $PORT), `lucos_creds` (port 2202) | — |

---

## Special Case: `network_mode: host`

`lucos_monitoring` uses `network_mode: host`, giving it direct access to the host's full network stack. This means it can reach other services via `localhost:<PORT>` without going through the Docker bridge. This is an intentional design choice that lets monitoring poll local services directly — it does not imply those services are "internal" or trusted; they still require their normal auth.

---

## Security Implications: What This Means for Security Claims

### ❌ Claims that are FALSE

- "This endpoint is only accessible from the internal network"
- "The blast radius is limited because it's behind the internal network"
- "No authentication is needed here since it's an internal service"
- "Services on the same host can't be reached from outside"

**None of these are true.** There is no internal network between services.

### ✅ What isolation actually exists

| Isolation boundary | Where it applies | What it protects |
|---|---|---|
| Docker Compose internal network | Within a single multi-container stack | Unexposed containers (Postgres, Redis, etc.) |
| TLS + `CLIENT_KEYS` auth | Each service's public endpoint | All authenticated endpoints on that service |
| Let's Encrypt TLS on the router | Inbound traffic | Data in transit from clients |

### What every service must assume

Every HTTP endpoint is potentially reachable by any internet client. **Authentication must be enforced at the application layer for every endpoint that should not be public.** "It's internal" is not a valid alternative.

---

## Quick Reference: Service-to-Host Mapping

Most services run on `avalon`. Notable exceptions:

| Service | Host |
|---|---|
| `lucos_static_media` | xwing |
| `lucos_private` | xwing |
| `lucos_media_import` | xwing |
| `lucos_media_linuxplayer` | xwing + salvare |
| `lucos_docker_health` | avalon + xwing + salvare |
| `lucos_router` | avalon + xwing |
| Everything else | avalon |
