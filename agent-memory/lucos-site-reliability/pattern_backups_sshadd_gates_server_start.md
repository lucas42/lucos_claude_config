---
name: pattern-backups-localhost-ipv6-publish
description: lucos_backups local "127.0.0.1 works but localhost doesn't" = enable_ipv6 publishes a non-functional IPv6 port; server binds IPv4-only
metadata:
  type: project
---

# lucos_backups: `localhost:8027` dead but `127.0.0.1:8027` works = dual-stack publish mismatch

**Symptom (lucas42's real issue, 2026-06-27):** local `curl 127.0.0.1:8027/_info` → 200, but `curl localhost:8027` → connection **reset**. Nothing crash-looping.

**Root cause:** `enable_ipv6: true` (#307, for the outbound salvare path) makes Docker publish the port on BOTH `0.0.0.0:8027` AND `[::]:8027`. But the Python `HTTPServer(('', port))` binds **IPv4-only** (`AF_INET` default). So IPv6 connections are accepted by docker-proxy, forwarded to the container, find nothing on the container's IPv6, and get **RESET**. `localhost` resolves to `::1` first → hits the broken IPv6 publish. A TCP **reset** (vs a clean **refusal**) does NOT trigger client fallback to `127.0.0.1`, so `localhost` fails outright. Old `network_mode: host` had nothing on `::1:8027` → clean refusal → fallback worked.

**Verified fix (#355):** publish IPv4-only — `ports: - "0.0.0.0:$PORT:$PORT"`. Then `::1:8027` is cleanly REFUSED (curl code 7) and `localhost` falls back to IPv4 → 200. Keeps `enable_ipv6` for outbound. Production unaffected (router hairpins via `172.17.0.1` IPv4).

**How to apply / methodology lessons:**
- **When a "no HTTP" report mentions a specific address, test EVERY address form: `127.0.0.1`, `localhost`, AND `[::1]`.** My first pass curled only `127.0.0.1` (the address that *works*) and wrongly cleared the network. Curling the address the user *can't* reach is the whole point.
- Dual-stack tell: `127.0.0.1` ok + `localhost`/`[::1]` reset = app binds IPv4 but Docker publishes `[::]` too. Check `docker ps` Ports for `[::]:` and `netstat -ltn` inside the container.
- **reset ≠ refused for fallback:** accepted-then-reset stops Happy-Eyeballs fallback; refused (nothing listening) allows it.
- **Don't conflate sandbox artifacts with the user's issue.** My earlier WRONG diagnosis (#354, closed not_planned) blamed an ssh-add startup crash-loop — that was MY sandbox only: stale local `.env` mangled key (`error in libcrypto`) + qemu arm64→amd64 ssh-agent flake (`communication with agent failed`). A healthy checkout doesn't crash-loop. lucas42: a broken SSH key SHOULD stay fatal (fail fast = easier to spot); do NOT propose making ssh init non-fatal.
- Reinforces [[pattern_dev_cross_service_wiring]] stale-local-.env trap (diff local `.env` vs fresh creds before blaming a key).
