---
name: pattern-photos-info-executor-starvation
description: lucos_photos /_info strands asyncio.to_thread workers when postgres stalls; 2 per poll fill the 8-worker pool after 4 polls, then redis-reachable fails too
metadata:
  type: project
---

A frozen or stalled `lucos_photos_postgres` (e.g. the nightly backup `docker pause`) makes `/_info` fail **wider** than the DB: `redis-reachable` times out too, though redis is fine.

**Mechanism (confirmed 2026-11-06, lucas42/lucos_photos#632):** `check_db()` and `get_metrics()` each run a DB query via `asyncio.to_thread` under a 0.5s `wait_for`. The timeout cancels the await, not the thread. The container sees 4 CPUs, so the default executor = 8 workers; 2 stranded per poll ⇒ full after 4 polls, then `redis_conn.ping` queues and times out. `get_metrics()` swallows its timeout, so only half the stranded threads show in the log. The stuck threads clear the moment postgres answers.

**How to apply:** "redis-reachable failing alongside db-reachable" in photos = executor starvation, not a redis problem. Tell: four `db-reachable`-only timeout lines, then both. Any post-unpause tail is a *different* effect (host contention suspected, unconfirmed). Prod has no `wchan`/`syscall` access for lucos-agent and no py-spy; confirm by timing+code, see [[pattern_hung_python_process_no_pyspy_use_faulthandler]]. Related: [[pattern_docker_pause_reports_unhealthy]].
