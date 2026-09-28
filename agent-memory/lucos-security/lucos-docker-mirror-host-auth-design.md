---
name: lucos-docker-mirror-host-auth-design
description: lucos_docker_mirror (docker.l42.eu) host-daemon auth design notes — IP-based via X-Real-IP is viable (port confirmed firewalled), credential-based still preferred for simplicity
metadata:
  type: reference
---

lucas42/lucos#307 (2026-09-28, photos.l42.eu 9h14m outage follow-up): `registry-mirrors: ["https://docker.l42.eu"]` has never served any host daemon — `lucos_docker_mirror`'s nginx (`nginx.conf.template`) gates all of `location /` with `auth_basic`; dockerd sends no credentials to a configured mirror, so every host pull 401s and silently falls back to Docker Hub anonymously. CI authenticates fine (sends real basic-auth creds).

SRE proposed exempting host daemons from `auth_basic` via an IP allowlist (`satisfy any`). My first-pass review (posted then corrected on lucas42/lucos#307) initially said this couldn't work at all — that was **wrong on one premise** and worth remembering precisely because it was an easy mistake to make:

**The mistake:** I cited `references/network-topology.md` ("no host-level firewall... ports directly reachable") without checking its date. That doc is from 2026-04-09 and predates ADR-0007 (2026-05-22) — the estate-wide default-deny firewall, which has been enforcing on all three hosts since 2026-06-08. **`network-topology.md` is now stale on this specific point and should be corrected** (flagged to team-lead 2026-09-28, not yet fixed as of this writing).

**Corrected facts, verified directly (not from the stale doc):**
- `lucos_configy` `hosts.yaml`: avalon has `firewall_enforce: true`.
- `lucos_configy` `systems.yaml`: `lucos_docker_mirror` has **no `public_ports` entry** — its port (8038) is not in the firewall's allow-list.
- Empirically confirmed: `curl http://178.32.218.44:8038/v2/` times out (dropped); `https://docker.l42.eu/v2/` (via `lucos_router`, port 443) returns 401 as expected. The router is genuinely the only path in — direct-port bypass does **not** exist for this service.

**Why that matters for the IP-allowlist design:** since the mirror's port is unreachable except via the router, and `lucos_router`'s template (`templates/https.conf`) does `proxy_set_header X-Real-IP $remote_addr;` (nginx **overwrites**, not appends — router's own `$remote_addr` is the genuine client IP, unforgeable by the client), an IP-allowlist keyed on **`X-Real-IP`** at the mirror (not `$remote_addr`, which SRE correctly showed collapses to the router's own bridge IP for every proxied client) would actually be sound. One granularity caveat: `salvare` and `xwing` share the same NAT'd public IPv4 (`152.37.104.10` in `hosts.yaml`), so IP-based trust can't distinguish between those two hosts specifically — not a hole, just coarse.

**Net recommendation unchanged in substance:** still prefer credential-based (`docker login` per host with a mirror-scoped `.htpasswd` entry, reusing what already works for CI) over IP-based, but now as a simplicity preference, not because IP-based is broken. Two open questions gate either path: whether dockerd supports per-mirror registry credentials at all, and whether `REGISTRY_PROXY_PASSWORD` (the mirror's upstream Docker Hub credential) is a scoped token vs. lucas42's account password.

**General lesson — check reference-doc staleness before citing an architectural absolute.** `network-topology.md`'s "no firewall" framing was true when written and is exactly the kind of claim that goes stale silently once a new control (ADR-0007) supersedes it, yet reads as permanently authoritative. Before citing "no host firewall" / "everything is internet-reachable" from that doc again, check `git log -1 -- references/network-topology.md` against ADR-0007's date, or better, check the live facts directly (configy `hosts.yaml` `firewall_enforce`, `systems.yaml` `public_ports`) rather than the doc's prose.
