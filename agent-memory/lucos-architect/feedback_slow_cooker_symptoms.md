---
name: Slow-cooker symptoms — treat repeated defensive fixes as a smell
description: Multiple closed issues with local/defensive fixes on the same component are themselves evidence of an untreated upstream cause
type: feedback
---

When a component has a history of issues closed with defensive fixes — timeout bumps, threshold tweaks, "probably transient", "flakiness", client-side workarounds — that pattern is itself a smell. The issues are symptoms of a single slow-accumulating cause, not independent bugs.

**Why:** The 2026-04-20 arachne incident traced user-visible SPARQL timeouts to TDB2 index bloat from the ingestor's DROP+INSERT pattern (93GB of tombstones against 227K live quads, 40 days of accumulation). Two earlier tickets — arachne#321 (SPARQL timeout, closed with client timeout bump) and arachne#343 (healthcheck flapping, closed without root cause) — were downstream of the same cause. Each looked plausibly self-contained at close time. Together they were obviously the same underlying problem accumulating.

**How to apply:** When reviewing a codebase or triaging an architectural concern:
1. Scan recently-closed issues on the component. Look for defensive/local fixes rather than root-cause fixes.
2. Ask: "what was stable before — and for how long?" A component that used to work and has started misbehaving has either (a) been changed (check git log) or (b) crossed a threshold on a slow-growing resource (indexes, queues, logs, disk, memory, connection counts, cache entries, file descriptors).
3. In architectural review writeups, explicitly flag "repeated symptom tickets, no identified root cause" as a concern — it's the kind of pattern that otherwise hides in plain sight because each issue looks individually minor.
4. Watch for the defensive-fix vocabulary in issue titles and PR descriptions: "bump", "increase timeout", "retry", "tolerate", "skip", "filter out", "probably transient". Each one is a load-bearing clue.
