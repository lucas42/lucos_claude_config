---
name: topic-monitoring-mechanics
description: lucos_monitoring poll-interval and post-restart cold-state cascade mechanics (the two facts with no dedicated backing file)
metadata:
  type: reference
---

Consolidated from MEMORY.md 2026-07-03 (index compaction).

## Poll interval = 60s, NOT 10s
Confirmed 2026-05-06 from `lucos_monitoring/src/fetcher_info.erl:32` (`timer:sleep(timer:seconds(60))`). `failThreshold:1`(default)→one failed poll alerts; `:2`→~120s; `:3`→~180s. Right tool for downstream-dependency checks where the upstream's typical outage <60-120s. The calc for whether failThreshold tuning suppresses a flap: `failThreshold × 60s ≥ outage_duration → suppressed`. (I repeatedly mis-said "10s" — don't.)

## Post-restart cold-state window ~2-3 min (not 1)
`lucos_monitoring#87` first-poll-skip covers only the FIRST poll. `#195` (merged 2026-04-26) added `failThreshold:2` to `fetch-info`+`tls-certificate` only, but post-restart estate-wide synchronised bursts ~2min after each `lucos_monitoring` deploy still occur (failures persist 2 consecutive polls). Mechanism: `fetcher_info.erl` has 1s hard timeout for both checks (`timeout 1s openssl s_client`, `httpc {timeout,1s}`); `start/1` spawns ~25 polling procs at the same instant → thundering herd vs cold DNS/TLS. **Telltale**: many services flap the SAME check within 2-5s, all recovering within 1min, across different hosts (avalon+xwing). Check `/events?type=deploySystem` for a `lucos_monitoring` deploy in the preceding ~3min → burst is monitor-side, not real. No public docs of the residual cascade; `#186` was filed by me then closed by me not_planned/duplicate (warm-up already existed via #87) — do NOT cite #186 as team disposition. Confirmed 2026-04-26 (docker_mirror#55: 3 monitoring deploys → 3 estate bursts ~2min later). Replaces the earlier incorrect "1 min warm-up" rule.
