---
name: feedback-detector-inverse-failure-mode
description: When designing or reviewing in-process anomaly detectors, pressure-test for the inverse failure mode — happy-path success counters with swallowing catches above the counted operation are structurally blind
metadata:
  type: feedback
---

When reviewing or designing an in-process anomaly detector (counter-thresholded, sliding-window, etc.), apply this check:

**Rule:** A detector whose signal is a happy-path success counter, with a swallowing `.catch` above the operation being counted, is structurally blind to the inverse failure mode. The operation throwing means the counter never increments, which means the threshold is never crossed, which means the detector never fires — exactly when it most needs to.

**Why:** This pattern caused the 2026-05-22 seinn cache-eviction incident. The `cache-thrash` banner from `lucos_media_seinn#457` counted only successful evictions; on 2026-05-22 eviction itself threw 18 times in a row (vs 2 successes), the `.catch(err => console.error(…))` swallowed each one, and the user got no in-page signal during ~6h of silent playback failure. Same user-visible symptom as the 2026-05-19 thrash incident, inverse mechanism. SRE flagged the general design lesson; I scanned the estate and the pattern was a singleton at the time, so no ADR — but I want to recognise the shape next time it shows up. See incident report `lucos/docs/incidents/2026-05-22-seinn-eviction-failure-webhook-burst.md` and follow-up comment on `lucos_media_seinn#470`.

**How to apply:** When you see a counter/threshold/sliding-window detector during design review or codebase scan, immediately ask: "what happens if the operation feeding this counter throws?" If the answer is "the catch swallows it and the counter never moves," that's the smell. Two ways to fix:

1. Add a parallel failure-path counter (preferred — co-locates the two signals, makes symmetry explicit to future readers).
2. Make the catch propagate or re-record the error into the detector's input rather than terminating at `console.error`.

**When to re-evaluate ADR question:** If a second instance of this pattern appears anywhere in the estate, the cost/benefit shifts toward codifying it as a convention. Right now it's one-off so the convention text would be longer than the live code it describes. Worth filing an ADR the moment a second instance turns up.

**Related observability gap (separate concern):** seinn has two failure-side counters (`erroringTracks` in `preload.js`, `sessionErrorCount` in `web-player.js:11`) that no detector reads. Symmetric gap to the eviction one — instrument failure but don't act on it. Out of scope for `#470`; flagged as a separate conversation but not yet a ticket.

---

**Sibling detector-design failure — a signal that can't discriminate (non-discriminating positive).** Before proposing any audit/detector keyed on signal X, verify X actually *differs* between the good state and the bad state it's meant to catch. If X is also present in the normal/expected state, the detector is 100% false positives and useless.

- **2026-06-07 — ADR-0002 #362.** I proposed a periodic audit flagging test-env credentials whose **key name** matches a production key name, as a signal that a prod secret was copied into test. lucas42 caught it: environment variables reuse the *same* key names across environments **by design** (code reads a fixed set of names; only values differ), so a name collision is the expected state for *every* key — the "signal" is the norm. The only true discriminator (the value) is encrypted, so nothing in the store can detect the bad state. Audit closed `not_planned`; the bright-line rule it was meant to harden is policy-only (write-time discipline), which the ADR now states honestly.
- **How to apply:** when designing a detector, ask not just "does the bad state produce signal X?" but "does the *good* state also produce X?" If yes, X can't discriminate. Especially watch for this when the signal is a structural property (a key name, a path shape, a status code) that the system produces uniformly regardless of the condition you care about. Pairs with [[feedback_verify_ci_mechanism_before_relying_on_it]] (read what the signal means in the target system).
