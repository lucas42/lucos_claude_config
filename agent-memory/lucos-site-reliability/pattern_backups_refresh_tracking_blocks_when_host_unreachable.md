---
name: pattern-backups-refresh-tracking-blocks-when-host-unreachable
description: Hourly :11-:14 backups fetch-info + docker_health "avalon" flaps while a home host is down = lucos_backups single-threaded server blocked ~127s per unreachable host by :07 refresh-tracking (lucos_backups#374)
metadata:
  type: project
---

During any xwing/salvare/aurora outage, `lucos_backups` `fetch-info` and `lucos_docker_health` `avalon` both go red at about :11–:12 and clear by about :14–:15, every hour. Both come from one cause: the :07 cron `POST /refresh-tracking` runs inside the single-threaded `HTTPServer`, and fabric SSH has no connect_timeout, so each blackholed host costs ~127s (tcp_syn_retries=6). With 3 hosts down that is ~6m48s blocked, which fails the docker healthcheck, so the container shows unhealthy and docker_health's avalon check goes red.

**Why:** 2026-11-03, lucas42's 33h broadband outage produced 137 alerts on these two systems and looked like "flapping during a hard-down network". The fix is the one-line ThreadingHTTPServer swap in lucos_backups#374. docker_health is correct and needs no change.

**How to apply:** if this hourly signature appears, check `docker logs lucos_docker_health_app | grep unhealthy` for "lucos_backups" and the backups access log for a `POST /refresh-tracking` 303 at ~:13:48. Don't file a new issue; #374 covers it (unless it has closed, in which case the fix regressed).
