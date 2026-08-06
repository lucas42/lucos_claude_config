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

**Confirmed instances (3, no shared code — 3 separate fixes):** `lucos_arachne` `search` (#735, 3 occurrences 07-02/07-13/07-30, evidence erased all three times); `lucos_media_seinn` `media-manager` (#583, 07-30); `lucos_time` `media` (#348, 07-01 + 08-04).

**A second sub-shape — the discarded `error.cause`.** #348 is not about elapsed-ms: Node/undici raises a bare `TypeError: fetch failed` whose actual reason (`ENOTFOUND` / `ECONNREFUSED` / `UND_ERR_CONNECT_TIMEOUT` / cert errors — *four different owners*) sits in **`error.cause`**, and `debug = error.message` throws it away. So when you see a bare `"fetch failed"`, the fix is `error.cause.code`, not a timer. Useful corollary: a fired `AbortSignal.timeout()` raises a **distinguishable** `TimeoutError`, so `"fetch failed"` positively indicates a network-layer failure rather than a too-tight budget — which both supports "the alert was real" and means **elapsed-ms adds little once `cause` is included** (team-lead scoped it out of #348 on exactly this reasoning, 2026-08-06 — agreed).

**Standing decision on a spec change (2026-08-06):** I flagged, but deliberately did NOT propose, adding guidance to `references/info-endpoint-spec.md` about what belongs in `debug`. Reasoning: a doc line has near-zero cost but genuinely uncertain preventive value (it only helps someone who reads it *while writing a check*) and fixes none of the three existing instances. Team-lead correctly kept it at the confidence I gave it and out of #348's scope. **Trigger to revisit: a fourth independent instance** — at that point the pattern is systemic rather than coincidental and should be raised on its own merits, not as scope on someone else's ticket.

## How to work one of these

1. **Read the probe source and get the timeout budget.** Don't guess it.
2. **Measure the exact call from inside the container** — same URL, same auth header, same body parse. `docker exec <c> node -e '...'` / equivalent. Never a hand-rolled `curl`/`wget` from elsewhere; see [[pattern_media_metadata_manager_probe_methodology]] for how that bites.
3. **Compare measurement to budget.** Both instances so far had 45–100× headroom on p50, which *kills* the tempting "tight timeout / false positive" hypothesis and means the alert was probably real. Do not raise the budget — that hides signal.
4. **Get corroborating evidence from a container that did NOT restart** — the router access log is the usual survivor. ⚠️ The nginx log format here has no `$request_time`, so it proves the upstream *responded*, not that it responded *quickly*. State that caveat explicitly; a slow-but-successful upstream is not excluded by a wall of 200s.
5. **File for the one-line fix** (elapsed-ms into `debug`, optionally a latency metric), not for a timeout change.

**Why this is worth filing every time despite being a trivial flap:** the fix is one line on a code path that already exists, with no runtime cost and no false-positive triage burden — the impact-vs-effort ratio clears the bar easily even when the outage itself is 40 seconds and harmless. The cost of *not* fixing it is investigating the same undiagnosable alert repeatedly, forever.

Related: [[pattern_container_restart_log_buffer_artifact]], [[feedback_correlation_is_not_confirmed]].
