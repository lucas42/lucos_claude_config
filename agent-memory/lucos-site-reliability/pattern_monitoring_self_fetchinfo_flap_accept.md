---
name: pattern-monitoring-self-fetchinfo-flap-accept
description: monitoring's own fetch-info self-probe flaps (post-deploy + steady-state) — disposition is ACCEPT, don't build; suppression has estate-wide blast radius
metadata:
  type: project
---

`lucos_monitoring`'s own `fetch-info` check (monitoring probing `monitoring.l42.eu/_info`) flaps in two ways:
1. **Post-deploy**: ~2 min after each `monitoringSelfRestart`/`deploySystem lucos_monitoring`, a non-suppressed `monitoringAlert` fires and recovers in 1–3 min (cold + busy startup crosses `failThreshold:2`).
2. **Steady-state**: single self-probe failures all day (seen in container logs as `Not sending alert for fetch-info as there has only been 1 recurring failures so far`), mostly absorbed by `failThreshold:2`; occasionally 2 line up → a brief flap unrelated to any restart (e.g. 2026-06-02 00:04→00:05, 28 min after the 23:36 deploy).

**Root cause (likely):** the self-probe coincides with monitoring's own busy poll cycle (~25 poll procs) and loses the **1-second** httpc timeout at `src/fetcher_info.erl:231`.

**Why I do NOT file a ticket (calibration):**
- Both the 1s timeout AND `failThreshold:2` are **GLOBAL** settings on the synthetic `fetch-info` check — they apply to all ~52 services, not per-system. So any suppression (raise timeout, raise threshold) has **estate-wide blast radius** (makes the whole estate's responsiveness detection more lenient), or requires building **new per-system-override machinery** that doesn't exist.
- Impact is low: ~1–2 mostly-absorbed, obviously-self/deploy-correlated emails/week.
- Prior team disposition: lucos_monitoring#186 ("Defer alerting during monitoring's own startup…") was closed **not_planned** on this exact theme; #195 added the global `failThreshold:2`.
- Per my calibration rule, "internal-only inconvenience vs estate-wide change → accept the risk, don't build."

**How to apply:** On future ops runs, if you see monitoring's own fetch-info flap (post-deploy or brief steady-state), this is the known accepted disposition — note it, don't re-investigate or file, unless the impact materially changes (e.g. monitoring's `/_info` genuinely unavailable for >5 min, or flaps become many-per-day, or a per-check timeout/threshold override mechanism gets built making a cheap fix possible). Related: [[pattern-dependson-deploy-window-only]], the MEMORY.md "post-restart cold-state window ~2-3 min" standing rule.
