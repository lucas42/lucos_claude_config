---
name: lucos-claude-config-131-loganne-events
description: lucos_claude_config#131 shipped (PR #136) — persistent-dirt/sync-failure detector now emits Loganne events instead of an unread log; key gotchas for anyone touching return-to-main.sh's detector again
metadata:
  type: reference
---

**Shipped 2026-08-20**, PR #136 (`725fd5e`). `return-to-main.sh` emits four edge-triggered Loganne events (`source=lucos_agent`, via `~/sandboxes/lucos_agent/loganne-event`): `persistentDirtDetected`/`persistentDirtCleared` (redefined *stalled*-dirt: dirty + untouched >300s + persisting >20min) and `syncFailurePersisted`/`syncFailureRecovered` (sync-failure tracked as its own condition, since a failing sync against a clean tree produces no porcelain diff at all). Reader half (SRE Check 2 filter widened for `source=lucos_agent`) landed separately in `29b0886` ahead of the emitter — deliberate ordering, see the issue thread, to avoid a window where events fire unread.

**Gotchas worth remembering:**
- `"${arr[*]}"` with a multi-char `IFS` (e.g. `', '`) only joins on the FIRST character — drops the space. Had to hand-join in `cap_paths`.
- Deliberately used distinct type names (`persistentDirtDetected`, not `monitoringAlert`) — Check 3's incident-coverage script pairs `monitoringAlert`/`monitoringRecovery` by type alone, regardless of `source`, so reusing those names would silently feed `lucos_agent` events into an unrelated incident-report sweep.
- `materialize_pr_content` (#134) already auto-heals almost all "present upstream, missing on disk" (`" D"`) cases before `check_persistent_dirt` runs — the only reachable case for the detector's own "no mtime = immediately stalled" fallback is now a **deleted symlink** (materialize skips symlinks deliberately).
- Known non-blocking follow-up filed: [[lucos-claude-config-138-drift-attribution-timing]] — the "drift" message's `syncFailurePersisted` cross-reference can be premature (independent clocks, shared window).
- `settings.json` is NOT excluded from this detector (that criterion was withdrawn once #129 measured it restart-stable) — don't reintroduce an exclusion without re-checking that measurement still holds.

See also [[pr-merge-never-reaches-working-tree]] (#134, the sibling fix this one builds on).
