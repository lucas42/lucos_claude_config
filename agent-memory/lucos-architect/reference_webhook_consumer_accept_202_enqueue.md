---
name: reference-webhook-consumer-accept-202-enqueue
description: ADR-0006 — webhook consumers absorb burst input via 202+enqueue pattern; loganne stays as-is
metadata:
  type: reference
---

# ADR-0006: Webhook consumer accept-202-enqueue

**Location:** `lucas42/lucos:docs/adr/0006-webhook-consumer-accept-202-enqueue.md`
**Discussion:** lucas42/lucos#165
**Status:** Accepted (2026-05-20)

## Decision shape (one paragraph)

Each webhook consumer receives the POST, validates auth, **immediately responds 202 Accepted** (not 200 — body accepted for processing, processing not yet complete), enqueues the event onto its own queue (in-memory or persistent, consumer's call), and a worker drains the queue at its own pace. Loganne stays fire-and-forget per-event with the existing single 30s retry, no concurrency cap, no per-consumer knowledge.

## What this is NOT

- **Not an estate-wide rollout.** New webhook consumers default to the pattern. Existing consumers retrofit **only on diagnostic evidence** that they're the burst bottleneck. lucos_media_weightings#230 (access-log status code + response time instrumentation) is the canonical first step toward producing such evidence.
- **Not a loganne change.** No producer-side concurrency cap, no per-consumer queue in loganne, no extended retry policy.
- **Not licence to rewrite every webhook handler.** Inline-processing handlers stay until evidence puts them in the bottleneck-suspect bucket.

## Why phrased as "burst absorption" not "concurrency cap"

The pattern doesn't cap concurrency — it smooths bursts via the queue. The receive path runs as fast as parse+enqueue, regardless of worker drain rate. Lucas42's verbatim brief said "consumer-owns-concurrency"; the ADR uses "consumer-owns-burst-absorption" for accuracy, flagged in the starting comment and PR body and explicitly endorsed by lucos-code-reviewer in approval.

## Central trade-off (the load-bearing "Negative")

202 means HTTP response can't signal *processing* failure — only acceptance failure. Per-consumer fix:
- Queue depth + processing-failure rate exposed on `/_info`
- Logs carry enough context per failed event to recover manually
- 2026-05-19 incident: under the pattern, weightings would have accepted the burst with no HTTP failures but with a visibly-growing queue + failure count — strictly better signal than 13 events stranded in loganne.

## Triggers / when to cite this ADR

- When reviewing a new webhook handler PR: inline-processing should be justified in review, not the default.
- When seeing repeated `failure`-state events in loganne for a specific consumer: confirms a candidate for retrofit (with instrumentation first).
- When asked "should loganne add a per-consumer rate limit / DLQ / concurrency cap?": no — that's the alternatives section, four rejected approaches.
