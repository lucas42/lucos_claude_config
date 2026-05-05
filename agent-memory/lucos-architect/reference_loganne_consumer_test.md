---
name: Loganne is the cross-estate async event bus — name the consumer test
description: Loganne is for inter-service async communication, not just observability. Before recommending a new event, name at least one consumer that needs it asynchronously.
type: reference
---

**What Loganne actually is:** the cross-estate async event bus for inter-service communication. Events fan out via webhooks defined in `webhooks-config.json`. Some events are pure observability (consumed only by aggregators / monitoring); many others drive downstream behaviour in subscribed services.

**Estate examples that drive behaviour, not just observation:**
- `trackUpdated` / `trackDeleted` — emitted by lucos_media_metadata_api; drive state updates in lucos_media_manager and lucos_media_weightings.
- `monitoringAlert` / `monitoringRecovery` — drive email alerting in lucos_monitoring.
- `collectionSwitch` (lucos_media_manager#238) — primarily observability-shaped but available for any client that wants to react to collection state changes.

**Estate examples that look like observability:**
- `fetchTracks` — emitted by lucos_media_manager's playlist topup; mostly used as a debug signal.

**The test for "should X be a Loganne event?"** Name at least one consumer that needs this asynchronously, OR a concrete external use case (audit log, dashboard, automation trigger). If the answer is "no current consumer, but it'd be nice to have a record" — that's a service log, not Loganne. The "is this an interesting cross-estate happening?" framing is too permissive and lets observability-only events drift in.

**Counter-example that failed the test:** `sceneActivated` (lucos_scenes#51, closed 2026-05-05). Recommended on lucos_media_seinn#425 → lucos#126 triage as a cross-estate signal of user-initiated action. Failed the consumer test in retrospect:
- No estate service needed to know "user pressed scene button X" asynchronously.
- The originating use case (lucos#126's T1 hop) was already covered by an existing scenes service log line.
- The downstream effect was already in Loganne via `collectionSwitch` and `deviceSwitch`.

**Negative-space framing to avoid:** "Loganne is for high-level cross-estate state changes." Partially true but lets observability-only events drift in. Use the consumer-named test instead.

**How to apply:**
- Before recommending a new Loganne event in any consultation: name the consumer (or future-but-concrete use case). If you can't, recommend a service log or `/_info` field instead.
- A property of an *existing* event (descriptive metadata) is fair game on Loganne — not subject to the same test, because the event's existence is already justified.
- For one-off diagnostics, lean toward service logs even when the timestamp would be cross-estate-interesting. A diagnostic that runs three times and gets binned doesn't justify expanding the event surface.
