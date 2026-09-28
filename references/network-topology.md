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

**Key consequence:** the router is the intended entry point for HTTP/HTTPS traffic, and — since ADR-0007 (`lucas42/lucos/docs/adr/0007-estate-wide-default-deny-port-policy.md`) — it is also enforced as such. `avalon`, `xwing` and `salvare` each run `lucos_firewall`, a default-deny inbound firewall (`firewall_enforce: true` in `lucos_configy` `config/hosts.yaml` for all three) whose allow-list is generated from `lucos_configy`: **a port is reachable from the internet if and only if it's declared as a `public_ports` entry** for a service whose `hosts:` list includes that host. `lucos_router`'s own 80/443 are declared this way, like any other service — they are not special-cased. Everything else defaults closed.

**Concretely:** a service's `http_port` (the port the router proxies to internally) is *not* reachable directly unless it's separately declared in `public_ports` — most services don't declare it, so most backend ports are closed to direct internet traffic. Confirmed 2026-09-28: `http://178.32.218.44:8019/_info` (loganne's backend port, no `public_ports` entry) times out; `https://loganne.l42.eu/_info` (via the router) returns 200. A handful of services declare a non-HTTP port directly as `public_ports` for a specific reason — e.g. `lucos_mail` (25/SMTP), `lucos_dns` (53), `lucos_creds` (2202/SSH), `lucos_locations` (8883/MQTT) — those are reachable by design, not by omission.

The router still provides TLS and domain routing, not application-level access control — that's still `CLIENT_KEYS`/equivalent auth's job. But it's no longer the *only* control: the firewall is a genuine second layer, and non-public backend ports are actually closed now, not just conventionally avoided.

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

As of ADR-0007, `network_mode: host` is prohibited by default — it bypasses Docker's per-container port publishing, so the firewall's `public_ports` allow-list can't scope it, and a host-mode container binding to `0.0.0.0` is internet-reachable regardless of configy. `lucos_monitoring` and `lucos_time` previously used it (for host IPv6 access, before Docker Compose supported per-network IPv6) and have since migrated to bridge networking. A new service adding `network_mode: host` needs written justification in its `docker-compose.yml` and an architect review.

Whether or not a service uses host networking, the same rule applies: reachability doesn't imply trust. Anything a container can reach — over the bridge, over `localhost`, or over the public internet — still requires its normal auth.

---

## Security Implications: What This Means for Security Claims

### ❌ Claims that are FALSE

- "This endpoint is only accessible from the internal network" — there is no internal network between services; see [Inter-Service Communication](#inter-service-communication) above.
- "The blast radius is limited because it's behind the internal network" — same reason.
- "No authentication is needed here since it's an internal service" — same reason; the firewall (below) restricts *inbound internet* reachability, it does not create a trusted zone between services.
- "Services on the same host can't be reached from outside" — each service's own public endpoint (router-routed domain, or an explicit `public_ports` entry) is independently internet-reachable regardless of what else shares the host.
- "This port isn't declared `public_ports`, so it's safe to skip auth on it" — the firewall is a second layer, not a replacement for Layer 1. Treat every endpoint as if the firewall didn't exist: `public_ports` scoping can drift, and the firewall itself fails safe to dry-run (log-only, not enforcing) if it can't reach `lucos_configy`.

**None of the first four are true.** There is no internal network between services, regardless of the host-level firewall described below.

### ✅ What isolation actually exists

| Isolation boundary | Where it applies | What it protects |
|---|---|---|
| Docker Compose internal network | Within a single multi-container stack | Unexposed containers (Postgres, Redis, etc.) |
| Host-level default-deny firewall (ADR-0007, `lucos_firewall`) | Inbound internet traffic to `avalon`/`xwing`/`salvare` | Any port not declared `public_ports` in `lucos_configy` for that host — most backend `http_port`s are closed to direct access |
| TLS + `CLIENT_KEYS` auth | Each service's public endpoint | All authenticated endpoints on that service |
| Let's Encrypt TLS on the router | Inbound traffic | Data in transit from clients |

### What every service must assume

Any endpoint reachable via the router, or via an explicit `public_ports` declaration, is reachable by any internet client. **Authentication must still be enforced at the application layer for every endpoint that should not be public** — the firewall reduces the *number* of ports an attacker can reach directly, but it is not a substitute for Layer 1 auth on the ports that remain open (router 80/443 foremost), and "it's internal" is still not a valid alternative for anything served there. Do not assume a backend `http_port` is closed just because it usually is — check `lucos_configy`'s `public_ports` for that service, or verify directly, rather than assuming from this doc's general description.

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
