---
name: pattern-access-log-first-for-webhook-bursts
description: For loganne webhook-error-rate bursts, default to pulling the receiver host's nginx access log before forming hypotheses
metadata:
  type: feedback
---

When investigating any `lucos_loganne / webhook-error-rate` burst, the **first** diagnostic move should be to pull the avalon (or relevant host's) `lucos_router` nginx access log for the burst window. Loganne's event record alone hides the most important piece of evidence.

**Why:** Loganne records each fan-out as `success` or `failure` with an error code, but it does NOT show whether the request reached the receiver at all. On 2026-05-21:
- Loganne's record said: 7 events `fetch failed (ETIMEDOUT)`, 7 events succeeded.
- nginx access log on avalon said: ZERO loganne POSTs reached the host for the entire 87-second burst window, then 21 POSTs landed in a 23-second backlog drain at 14:45:31+.
- Interpretation that's only possible from the nginx side: loganne's outbound stalled; receivers never had a chance to be slow or refuse.

Without the access log, the natural reading of the loganne data alone would be "downstream receivers were slow" — which it wasn't.

**How to apply:**

```bash
ssh avalon.s.l42.eu 'docker logs lucos_router 2>&1 --since 90m' > /tmp/avalon_nginx.log
# Then filter by relevant user-agent + paths:
grep "lucos_loganne" /tmp/avalon_nginx.log | grep -E "(webhook|weight-track|trackUpdated)"
# Per-second total activity (proves whether the HOST was processing anything at all):
grep "21/May/2026:14:4[3-6]" /tmp/avalon_nginx.log | awk '{print $4}' | sed 's/\[//' | cut -d: -f1-4 | sort | uniq -c
# Per-second by source (identifies the burst's actual originator — caught the linuxplayer culprit):
grep "ceol.l42.eu" /tmp/avalon_nginx.log | grep "linuxplayer" | grep "?action=error" | awk -F'[][]' '{print $2}' | sort | uniq -c
```

Three distinct nginx-side measurements to pull every time, in order:
1. **Was the host alive?** Per-second total request count throughout the burst window. If non-zero, the host was fine; rule out host-level pressure.
2. **Did the suspected sender's traffic reach the host?** Filter by sender user-agent. If gone for some window, the sender's outbound stalled (not the receivers).
3. **What's the actual originating traffic causing the burst?** Filter by receiver hostname + the action that's spiking. Often reveals the true upstream trigger.

Saves about 45 minutes of hypothesis-thrashing per webhook-error-rate burst.

Related: [[feedback-avoid-coincidence-default]] (today's lesson on framing), [[loganne-webhook-retry-api]] (cleanup after diagnosis).
