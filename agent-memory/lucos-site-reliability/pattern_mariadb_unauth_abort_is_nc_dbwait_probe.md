---
name: pattern-mariadb-unauth-abort-is-nc-dbwait-probe
description: MariaDB "closed normally without authentication" aborted-connection warning from a linuxserver.io app container = the init's nc-based DB-readiness probe — benign
metadata:
  type: project
---

MariaDB log warning `Aborted connection N to db: 'unconnected' user: 'unauthenticated' host: '<app-container-ip>' (This connection closed normally without authentication)` on a service that wraps a **linuxserver.io** image (e.g. lucos_worlds = BookStack via `lscr.io/linuxserver/bookstack`) is **benign, by-design startup noise**.

**Root cause (verified 2026-07-07, lucos_worlds on avalon):** the linuxserver init script `/etc/s6-overlay/s6-rc.d/init-bookstack-config/run` runs a DB-readiness probe: `nc -w1 ${DB_HOST} ${DB_PORT}`. netcat opens the TCP socket, MariaDB sends its handshake greeting, netcat closes without sending an auth response → server logs it as an unauthenticated pre-auth close.

- **~1 warning per app-container start.** Steady-state = zero. So a small handful per deploy/restart, never during normal operation.
- The `host:` in the warning is the **app's own container IP** on the private docker network — `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <web_container>` to confirm it's the app, not an external probe.
- This probe is **independent of** compose's `depends_on: condition: service_healthy` — it's the app image's own belt-and-braces wait.

**Security:** none. Private network, app's own container, no credentials sent, no bypass. `unauthenticated`/`unconnected` are just MariaDB's labels for a socket closed before the auth packet.

**Disposition:** don't raise an issue, don't "fix". Suppression would mean either forking upstream linuxserver's probe or raising MariaDB `log_warnings` globally (hides useful warnings too) — pure maintenance tax for a ~1-per-deploy cosmetic line. Accept the risk.

Related: [[feedback_check_user_agent_first]] (identify the client before theorising), [[pattern_info_endpoint_boundary]].
