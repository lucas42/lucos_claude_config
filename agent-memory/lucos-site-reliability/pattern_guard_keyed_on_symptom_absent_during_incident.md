---
name: pattern-guard-keyed-on-symptom-absent-during-incident
description: A safety guard gated on a symptom the incident itself produces will be reliably absent during incidents; check the correlation between the guard's trigger and the failure it guards
metadata:
  type: project
---

When a recovery mechanism is gated behind a threshold, always ask: **does the failure it recovers from also produce the signal that trips the gate?** If yes, the guard isn't "sometimes unhelpful" — it is *reliably absent exactly when needed*. That is a structural property, not bad luck in a sample, and it is easy to miss because each half looks reasonable in isolation.

**Confirmed instance:** lucos_photos, 2026-07-19 (lucas42/lucos_photos#478, #479). `sweep_pending_photos` re-enqueues stuck items but skips entirely when `queue_depth > SWEEP_QUEUE_DEPTH_LIMIT` (default **0**, so any depth ≥1 skips). The worker is a *single sequential RQ worker, one replica* — so any hung job blocks the only worker and the queue necessarily backs up behind it. Logs showed 3 of 4 observed skips falling inside the 4-minute window of a hung job: hang → queue grows → breaker trips → stuck-item sweep suppressed for the duration of the hang.

**The diagnostic move that found it:** correlating the guard's trigger timestamps against the incident window, rather than reading either in isolation. Both the breaker and the sweep were individually sensible; only the overlap revealed the anti-correlation. Worth doing routinely when a guard and an incident coexist.

**Why the evidence existed at all:** the skip warning logged the depth, the limit, and the timestamp — enough to reconstruct the whole incident timeline from four lines that had sat unread for months. Carry this into any review of a change that removes or quiets a "noisy" log line: you cannot know in advance which unread line becomes the evidence. Argue for keeping the *why* and the values, not just the fact that something happened.

**Topology is load-bearing here** — verify concurrency before claiming it: `SCARD rq:workers:<queue>`, container replica count, and whether the worker forks one horse at a time. Single-worker sequential execution is what *guarantees* the backup; with N workers the property weakens.

**Generalisation worth carrying:** absolute-threshold guards can't distinguish "busy and draining" from "runaway and growing". Prefer triggering on the pathology's actual signature (e.g. per-item retry counts — the flood is the *same items* looping) over a global proxy like total depth. A parameter-free trigger is a real advantage, not an aesthetic one, when the absolute number can't be measured in advance.

**Estimation discipline that came out of the same analysis:** a thin sample can still be decisive if the conclusion is robust across wide error bars — say so explicitly rather than either over-claiming precision or refusing to answer. Here n=5 job durations bounded throughput to ~94-200/hour, enough to conclude a bulk import suppresses the sweep for days. Conversely, when a quantity genuinely can't be measured (the cost of days of unclustered faces), decline to estimate and say so — a declined estimate is worth more than one that needs caveating downstream. See [[feedback_no_attribution_overclaim]].

Related: [[pattern_rq_scheduler_disabled_silently_drops_retries]] (same investigation — the sweep was the backstop masking that bug for four months).
