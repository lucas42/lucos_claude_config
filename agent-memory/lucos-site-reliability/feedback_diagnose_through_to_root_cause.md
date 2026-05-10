---
name: Diagnose through to root cause when next step is diagnostics, not developer action
description: When investigating an incident handed off to a developer, keep going if the next step is more diagnostics you're better placed to do; only park if the next step is genuinely developer-side action (write code, run tests, decide product call).
type: feedback
---

When investigating an incident that ultimately gets handed off to the developer, choose between "park and hand off" vs "keep diagnosing" based on **what the next step actually is**, not on how much I've already done:

- **Keep going if** the next step is more diagnostics — query the producer endpoint directly, read logs, decode IRIs against the store, sample the actual response bytes, cross-reference what the merged PR's diff actually contains. These are things I'm better placed to do (have host access, auth tokens, knowledge of the production layout) and a developer would have to re-derive most of them from scratch to reach root cause.
- **Park and hand off if** the next step is genuinely developer-side — writing code, running tests, choosing a product trade-off, making a design call between two valid options.

**Why:** team-lead 2026-05-10 on `lucos_arachne#479` (mmm:trackLanguage namespace mismatch). After the first round of diagnosis I'd handed back "is phase 1 emitting or is the ingestor not picking up?" as a question for the developer. team-lead pushed me to finish it — I was three queries away from root cause (fetch live export, count predicate occurrences, decode the IRI host mismatch against searchindex.py source), and parking at the verbal hand-off would have made me the bottleneck for a second round of context-loading and re-derivation by the developer. The actual answer was a one-line consumer fix, not a debugging exercise.

**How to apply:** before parking, ask "what's the literal next action on the developer's plate if I hand off now?" If the answer is "answer the same question I just asked them" or "go through the same investigation I'm halfway through", keep going. If it's "make a code change" or "decide between options A and B", park.

This is *not* a licence to drift into code changes — the existing rule (write the issue, let the developer implement) stands. The principle is about how far to push the *investigation*, not about who writes the fix.
