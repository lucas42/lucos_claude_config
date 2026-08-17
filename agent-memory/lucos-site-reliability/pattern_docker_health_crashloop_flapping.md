---
name: pattern-docker-health-crashloop-flapping
description: "lucos_docker_health flaps wildly during a container crash-loop (51 alerts/42 recoveries in one 15h outage) — its stuck-starting guard is keyed to StartedAt, which a restart loop resets faster than the 5min threshold"
metadata:
  type: project
---

**A crash-looping container makes `lucos_docker_health` flap, while the broken service's own checks stay correctly red.** 2026-08-17, one continuous 15h24m `lucos_backups` outage, same window, two observers:

| system | monitoringAlert | monitoringRecovery |
|---|---|---|
| `lucos_backups` (actually broken) | 7 | **0** |
| `lucos_docker_health` (observer) | 51 | **42** |

So flapping here is a property of the **check**, not of the condition. Don't accept "a crash-loop is inherently many little outages" — the service died during module import, never bound its port, and served zero requests for 15h. It is **one** outage. 42 false recoveries are worse than silence: they argue the thing is self-healing, i.e. an argument not to investigate.

**Mechanism (`lucos_docker_health/main.go`, `checkHealth`)** — it flags a container in exactly two cases:
```go
case "unhealthy":  unhealthy = append(...)
case "starting":   if time.Since(startedAt) > stuckStartingThreshold { ... }   // const = 5 * time.Minute
```
- A container restarting every ~4.5s **never** has `StartedAt` older than ~4.5s ⇒ `> 5 minutes` can never be true. **The stuck-starting guard, which exists precisely to catch a container that never comes up, is defeated by the restart loop it should catch** — it measures how long *this incarnation* has been starting, not how long the container has failed to reach healthy. Generalises: [[pattern_guard_keyed_on_symptom_absent_during_incident]].
- That leaves the `unhealthy` branch. With compose `interval:10s retries:3 start_period:30s`, reaching `unhealthy` needs ~30s of continuous uptime a 4.5s loop rarely gives. lucos_backups' health log held **5 entries for the whole 15h**.
- **Amplifier:** the monitoring check asks whether **any** of the *5 most recent* runs succeeded ⇒ one lucky sample in five holds it green, overriding four correct observations. That N is **per-job** (`docker_health/avalon`=5, `backups/tracking`=3, `backups/create-backups`=2), so it may be tunable to 1 without code.

**Diagnostic tell:** the check's `debug` shows the consecutive-error counter resetting — `Last 23 runs of scheduled job errored`, then `Last 19`, `Last 9`, `Last 5`. Runs demonstrably succeeded intermittently.

**Proposed fix (passed to team-lead 2026-08-17, NOT filed by me):** treat a **rising `RestartCount`** as unhealthy, independent of health status. `RestartCount` is *monotonic*, so comparing it between polls is phase-independent — it converts an oscillating sample into a level signal. Needs one map in a loop already polling every 60s. Require the rise across **two consecutive** polls so an ordinary deploy/one-off restart doesn't alert.

**Durable generalisation:** to watch something that oscillates faster than you sample, **compare a monotonic counter across polls; never sample the instantaneous state** — and be suspicious of any "any of the last N succeeded" tolerance applied to a high-frequency probe rather than a scheduled job.

Incident: `lucos/docs/incidents/2026-08-17-backups-python-alpha-charset-normalizer.md` §Stage 5.
