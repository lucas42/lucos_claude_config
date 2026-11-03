---
name: pattern-monitoring-circleci-loops-stay-in-step
description: lucos_monitoring's per-repo circleci loops do NOT drift apart; with a real token, 9–21 of 52 repos get CircleCI 429s every cycle (lucos_monitoring#322). My "startup-only burst" prediction was wrong.
metadata:
  type: project
---

On 2026-11-03 I gave a GO to redeploy lucos_monitoring with a CircleCI key, reasoning that the 56 `ciRepoLoop`s (spawned together, `sleep 60` after their work) would desync within a few cycles. The data proved it wrong. From +3 to +10 min, 9–21 of 52 repos got `HTTP 429` on CircleCI's `/pipeline/:id/workflow` route (50 req/s) in every cycle, with no decay. Nothing alerted, because the longest per-repo run was 3 against the UnknownsGate's 5. But at ~26% per cycle, an occasional alert/recovery pair per hour is expected. The fix is the fixed-slot stagger in lucas42/lucos_monitoring#322.

**Why:** a plausible drift argument stood in for a measurement, and the startup burst turned out to be the steady state. Also: monitoring never logs a non-200 (it only goes into the check's `debug`), and its gate-notice log timestamps reflect the state server's once-a-minute burst, not fetch time. Neither the logs nor the notices can show you the fetch phases.

**How to apply:** for any "N in-process pollers will spread out" claim, measure the per-cycle error rate after deploy rather than predicting it. For CircleCI 429s, read `/api/status` `circleci.debug` for `HTTP 429`, not the logs.
