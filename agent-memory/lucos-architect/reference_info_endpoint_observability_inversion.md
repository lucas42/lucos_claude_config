---
name: info-endpoint-observability-inversion
description: Recurring estate pattern — a service's /_info cost scales with its own workload, so it reports itself unhealthy exactly when busy; four instances, spec rule tracked as lucos#288
metadata:
  type: reference
---

**Pattern: `/_info` generation whose cost is a function of the service's own workload.** The endpoint blows the 1s poll budget for a window, monitoring reports the service degraded, nothing is actually wrong. The signal inverts: the busier the system, the less able it is to say it is fine.

Four confirmed instances (as at 2026-08-09):

- **lucos_monitoring#298** — `/_info` served by the same `gen_server` that ingests every check result from ~100 pollers. Each `updateSystem` cast synchronously renders the full dashboard HTML for all systems *inside the state server's process* (~25ms measured, ≈2.4s per 60s cycle). `/_info` also makes *two* `gen_server:call`s, so it queues twice — and `encodeInfo` uses only `length(Systems)` from that expensive read.
- **lucos_monitoring#299** — same property filed as a latent scaling property; scoped by triage to measurement only.
- **lucos_backups#374** — single-threaded `HTTPServer` blocked ~20s hourly at :07 by `refresh-tracking`. 96 failures over 7 days, 100% at :07. **One-line `ThreadingHTTPServer` fix sat Ready three weeks** — the best argument that per-instance tickets don't stop the pattern recurring.
- **lucos_media_weightings#277** — two `dependsOn` probes at 1.0s timeout each; alerted *weightings* 7 min before the actually-down `lucos_time`.

**Spec rule tracked at lucas42/lucos#288**, deliberately separate from lucos#283 (which only migrates already-agreed orphaned rules — a new rule riding in on a reconciliation ticket gains unearned authority).

## lucos_monitoring facts worth not re-deriving

- **Monitoring polls itself.** `lucos_monitoring` is in configy's `systems/http` list, so its own round-trip lands in `PollTimings` like any system. `poll-max-duration-ms` is already a **max over the latest entry per system**, entries ≤60s old — i.e. an existing rolling max. The self-poll burst is therefore **observable but not attributable** (the max is estate-wide and anonymous). I claimed in #299 that it was unobservable, without checking — a one-command check. Absence claim, unverified, and it justified a whole measure-first gate.
- **No fetcher has any stagger or jitter.** All four spawn one process per target in a tight `lists:foreach` then `sleep(60s)`. A phase-aligned thundering herd at container start which then spreads, since each poller's true period is `60s + its own duration`. Explains a tight burst *and* its decay over hours after a restart.

## Reusable method

- If only *one* service shows a symptom, ask what is structurally unique about it. Monitoring was the only service whose `/_info` latency depended on its own workload.
- **A deploy restarts the container, which re-aligns a poller herd.** So before/after verification of any fix here is confounded by the deploy itself — diffuse-herd baseline vs converged-herd retest, biased against the fix. Low-duty-cycle phenomena need a continuous in-product signal, not a spot check.
- **Sample by the event, not by the request.** A metric sampled when `/_info` is called is sampled at one fixed phase per minute and can miss a 3s-in-60 burst forever. Cheapest robust form: state server records its own `message_queue_len` per message processed.

Related: [[docker-healthy-not-reachability]], [[convention-catalogue]], [[grep-and-conclude-anti-pattern]].
