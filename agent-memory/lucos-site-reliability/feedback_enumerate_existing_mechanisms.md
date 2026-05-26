---
name: enumerate-existing-mechanisms-before-new-persistence
description: When proposing any persistence/storage/observability mechanism, enumerate at least one existing surface that could be extended and explain why it's rejected — before defaulting to "build a new thing"
metadata:
  type: feedback
---

When proposing a new persistence, storage, observability, or eventing mechanism, enumerate at least one **existing** surface that could be extended to solve the same problem, and explain why it's rejected — before defaulting to "build a new thing." Don't write a proposal that skips this evaluation.

**Why:** On 2026-05-26 I proposed `lucas42/lucos_monitoring#260` ("rolling log of check failures on a named volume") without considering whether the existing `monitoringAlert` Loganne event payload could be augmented with a structured `failingChecks` field. lucas42 pushed back on the omission as his first critique. He was right — Loganne already persists events with 90-day retention, has a queryable API, and is the system everyone uses for cross-estate records. Extending an event payload was the smaller-blast-radius change all along. The new-file proposal also triggered legitimate cascading concerns: setting a precedent for log-files-on-named-volumes that lucas42 wanted handled holistically, and an honest-cost slip where I framed maintenance tax as "near-zero" while taking a stateless system to a stateful one.

**How to apply:** Before filing or messaging any proposal that introduces a new storage mechanism (file, volume, table, queue, cache, log stream), explicitly list ≥1 existing surface (Loganne events, `/_info` fields, monitoring API state, lucos_configy, container logs, etc.) and either justify why it doesn't fit or — more often — re-shape the proposal as an extension to it. The "enumerate alternatives" step in [[feedback_loganne_scope]] applies in the inverse direction here too: not only "is Loganne the right channel for this?" but also "is Loganne (or another existing surface) the right channel for what I'm proposing to build new?"

Related: [[feedback_loganne_scope]] (the inverse case — when Loganne is *not* the right surface).
