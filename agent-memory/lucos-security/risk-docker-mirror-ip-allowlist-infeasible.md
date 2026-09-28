---
name: risk-docker-mirror-ip-allowlist-infeasible
description: IP-based allowlisting for lucos_docker_mirror (docker.l42.eu) can't discriminate legit hosts from any internet client, because router-proxied traffic collapses to one shared source IP
metadata:
  type: reference
---

lucas42/lucos#307 (2026-09-28, photos.l42.eu 9h14m outage follow-up): `registry-mirrors: ["https://docker.l42.eu"]` has never actually served any host daemon — `lucos_docker_mirror`'s nginx (`nginx.conf.template`) gates all of `location /` with `auth_basic`, and dockerd sends no credentials to a configured mirror, so every host pull 401s and silently falls back to Docker Hub anonymously. CI authenticates fine (it sends real basic-auth creds) — only host daemons were ever blocked.

SRE proposed exempting host daemons from `auth_basic` via an IP allowlist (`satisfy any`). **This can't work as described, and it's a general pattern worth re-checking anywhere someone proposes IP-based trust in this estate:**

- `registry-mirrors` uses the **public hostname** `docker.l42.eu`, routed through `lucos_router`. Empirically (SRE's access-log analysis, 121 host-daemon requests over 72h), *every* request proxied through the router to a backend arrives with the same collapsed source IP (the router's own bridge address, e.g. `172.16.5.1`) — regardless of the original client. An IP allow-rule at the backend can't distinguish a legitimate estate host from any internet client hitting the same public hostname; there's no discriminating signal at all through that path, not just a spoofing risk.
- The mirror's `web` container also publishes its `${PORT}` directly to the host (`ports: - "${PORT}:${PORT}"` in `docker-compose.yml`) — per [[risk-lucos-firewall-inbound-only-egress-unfiltered]]-adjacent fact (network-topology.md: **no host-level firewall**, any container port is directly internet-reachable), so even a header-based fix (`X-Real-IP` forwarded by the router) is bypassable by connecting directly and setting the header yourself.

**Recommended pattern instead, when this recurs:** credential-based auth reusing whatever already works for the trusted automated client (here: CI's existing `auth_basic` creds) — e.g. `docker login <mirror>` per host with a scoped credential — rather than IP/network-position-based trust. Two things to verify before approving such a fix: (1) whether the client tool (dockerd, in this case) actually supports per-endpoint credentials at all, and (2) whether the credential the proxy/mirror uses *upstream* is scoped (not a personal-account password) — a misconfigured exemption otherwise turns the mirror into an open proxy authenticated as the account owner.

Not yet resolved as of 2026-09-28 — tracked as a to-be-opened separate ticket off lucas42/lucos#307, gated on both open questions above before Ready.
