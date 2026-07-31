---
name: pattern-probe-measures-then-discards-latency
description: When a check's alert debug is a bare exception string ("aborted due to timeout"), grep the probe source before theorising — it often already computes elapsed-ms and console.warn's it, so the evidence exists but dies with the container
metadata:
  type: reference
---

When a monitoring check alerts with a bare exception message as its whole `debug` field — classically `The operation was aborted due to timeout` — **read the probe's source before forming any hypothesis**. On this estate the recurring shape is:

```js
const probeStart = Date.now();
try { ... await fetch(url, { signal: AbortSignal.timeout(N) }) ... }
catch (error) {
    const probeMs = Date.now() - probeStart;
    console.warn(`... failed after ${probeMs}ms ...`);   // measured, but volatile
    check.debug = error.message;                          // durable, but useless
}
```

The number you need **already exists**. It goes to `console.warn` → `docker logs` → erased at the next redeploy. Meanwhile the Loganne alert, which is retained indefinitely, carries only the exception string. Since the estate redeploys roughly daily, any probe measurement has a shelf life shorter than the gap between an alert firing and an ops check noticing it.

**Confirmed instances:** `lucos_arachne` `search` (#735, 3 occurrences 07-02/07-13/07-30, evidence erased all three times) and `lucos_media_seinn` `media-manager` (#583, 07-30).

## How to work one of these

1. **Read the probe source and get the timeout budget.** Don't guess it.
2. **Measure the exact call from inside the container** — same URL, same auth header, same body parse. `docker exec <c> node -e '...'` / equivalent. Never a hand-rolled `curl`/`wget` from elsewhere; see [[pattern_media_metadata_manager_probe_methodology]] for how that bites.
3. **Compare measurement to budget.** Both instances so far had 45–100× headroom on p50, which *kills* the tempting "tight timeout / false positive" hypothesis and means the alert was probably real. Do not raise the budget — that hides signal.
4. **Get corroborating evidence from a container that did NOT restart** — the router access log is the usual survivor. ⚠️ The nginx log format here has no `$request_time`, so it proves the upstream *responded*, not that it responded *quickly*. State that caveat explicitly; a slow-but-successful upstream is not excluded by a wall of 200s.
5. **File for the one-line fix** (elapsed-ms into `debug`, optionally a latency metric), not for a timeout change.

**Why this is worth filing every time despite being a trivial flap:** the fix is one line on a code path that already exists, with no runtime cost and no false-positive triage burden — the impact-vs-effort ratio clears the bar easily even when the outage itself is 40 seconds and harmless. The cost of *not* fixing it is investigating the same undiagnosable alert repeatedly, forever.

Related: [[pattern_container_restart_log_buffer_artifact]], [[feedback_correlation_is_not_confirmed]].
