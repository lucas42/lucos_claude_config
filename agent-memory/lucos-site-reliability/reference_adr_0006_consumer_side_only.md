---
name: adr-0006-consumer-side-only
description: ADR-0006 (webhook consumer accept-202-enqueue) addresses consumer-side burst absorption only — does NOT remediate producer-side outbound-client saturation like loganne's undici pool/DNS pressure during the 2026-05-20 seinn cache-thrash incident.
metadata:
  type: reference
---

ADR-0006 (`lucas42/lucos#166`, merged 2026-05-20) defines the **consumer-side** burst-absorption pattern: a webhook consumer accepts the POST, returns 202, enqueues to in-process storage, and drains asynchronously. The architectural problem it solves is "consumer can't process work fast enough during a burst".

It does **not** address producer-side outbound-client failures — e.g. loganne's HTTP client (undici) failing to establish connections under burst load due to connection-pool saturation or DNS resolver pressure. Symptom of producer-side failure: `fetch failed` with `error.cause.code` of `UND_ERR_*` / `ENOTFOUND` / `ETIMEDOUT` *before any TCP connection reaches the consumer or its router*. The 2026-05-20 seinn cache-thrash incident hit exactly this pattern (see `lucas42/lucos/docs/incidents/2026-05-19-seinn-cache-thrash-music-outages.md`).

**Why this distinction matters:** future incident threads where webhooks fail under burst load will be tempted to cite ADR-0006 as a remediation. If the failure happens on the producer side (loganne couldn't even open a socket), ADR-0006 doesn't help. The fix would be a separate piece of design work — adjusting undici client config (`connections`, `bodyTimeout`, `keepAliveTimeout`), DNS caching, or producer-side rate-shaping. Different problem class, different ADR if one is warranted.

Flagged by lucos-architect 2026-05-20 in response to the incident report, colleague-to-colleague, "so neither of us cites ADR-0006 as a remediation for outbound-client failures in some future thread".

**Diagnostic step for next occurrence:** check whether the failed POSTs ever reached the consumer's router (nginx access log). If yes and the consumer was slow → ADR-0006 applies. If no (failures before any TCP connection) → producer-side, ADR-0006 does not apply.
