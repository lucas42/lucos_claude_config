---
name: pattern-new-system-configy-consumer-latency
description: When a new system lands in configy, which consumers pick it up when — creds PORT/APP_ORIGIN lag (hourly :53) fails the first deploy; router + monitoring need manual action
metadata:
  type: reference
---

When a new system lands in configy, each consumer picks it up on its own schedule. Everything below was checked live for lucos_campaigns on 2026-09-29.

- **lucos_creds configy_sync: hourly at :53.** It writes `PORT` and `APP_ORIGIN` for both environments. A deploy that runs before the next :53 gets an empty `${PORT}` and fails, which is what happened to lucos_campaigns' first deploy. Fix: wait for :53, or have lucas42 set the values by hand, then re-run the deploy. To check whether they're set, look in loganne for `Credential PORT updated in <system> (production)`.
- **Timing starts when configy is live, not at the merge.** Configy's own deploy restarts it a few minutes after the merge; check its `StartedAt`.
- **lucos_dns sync: every 15 minutes** (`*/15`). New records come out as a CNAME to `<host>.s.l42.eu`.
- **lucos_router: only at startup or the 22:16Z cron.** `docker exec lucos_router update-domains.sh` does the same with just an nginx reload, no restart. Run it after DNS resolves. It took about 90s for 32 domains.
- **lucos_backups: `/refresh-config` hourly at :03.** The `volume-host` check goes red until the app has created its volumes.
- **lucos_monitoring: needs a rebuild** — [[pattern-surfacing-new-service-monitoring-vs-root]]. **lucos_root:** picks it up at runtime within 5 minutes. **Auto-merge workflow:** reads configy on each PR.
- **lucos_repos:** reads configy every 6 hours and at startup.
- After a monitoring rebuild, lucos_monitoring briefly shows its own status as `buffering`; it cleared within about 5 minutes.
