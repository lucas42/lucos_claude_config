---
name: snapshot-before-retry
description: When retrying stranded loganne webhook deliveries (or any other "retry to clear stuck state" remediation), snapshot the diagnostic fields first — retry overwrites them and the diagnostic data is then unrecoverable
metadata:
  type: feedback
---

Before triggering `POST /events/retry-webhooks` (or any equivalent state-clearing retry), snapshot the per-failure diagnostic fields. Retry overwrites the webhook delivery record with the success result, so any failure-side fields (`errorMessage`, `errorPhase`, the original failed-attempt `durationMs`) are gone afterward and cannot be recovered from the event store.

**Why:** On 2026-05-22 I ran `POST /events/retry-webhooks` to clear 19 stranded events from the seinn cache-eviction-TypeError incident. The retry succeeded operationally (19/19, `monitoringRecovery` fired), but it overwrote each event's `webhooks.all[url]` block — so when I went to use the `errorPhase` field that had shipped the day before (`lucos_loganne#480`, distinguishing connect-phase from response-phase ETIMEDOUT), it was gone. We lost the diagnostic step that would have told us whether the cascade is loganne-pool-exhaustion (connect-phase) or downstream-slowness (response-phase). lucas42 flagged it; this is an extension of the existing "sample errorMessage distribution before retry" rule but with sharper teeth now that more diagnostic fields exist.

**How to apply:**

1. Before any retry, query the failure set and persist the diagnostic fields to disk. Minimum: `errorMessage`, `errorPhase`, original `durationMs`, the event date, the target URL.
2. Especially relevant for loganne webhook retries via `POST /events/retry-webhooks`. The standing memory at the top of MEMORY.md ("Loganne — Webhook Retry API") should be read alongside this one.
3. The diagnostic data is most valuable for the *current* incident — sampling for distribution analysis is fine, but a full snapshot is cheap and lets the next investigation hour use the data even if the alert clears.

Related: see [[feedback_sample_webhook_errors_first]] (the pre-existing version of this rule, weaker on snapshot persistence).
