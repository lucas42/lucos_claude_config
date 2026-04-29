---
name: Don't game API contracts to work around design issues
description: When a system's behavior seems wrong, address it at the source rather than passing dishonest values through an API to manipulate downstream behavior
type: feedback
---

When an API parameter has a designed meaning, **pass the truth and accept the consequences** — even if those consequences are unhelpful. If the consequences are wrong, fix the system at the source. Don't pass dishonest values through the API to manipulate downstream behavior.

**Why:** lucas42 caught this on 2026-04-29 (arachne#419 / arachne#420 / pythonclient#36). I'd "fixed" a too-narrow alert threshold by lying about a job's `frequency` to schedule-tracker (passing 3 days for a job that runs weekly, to game the server-side `frequency × 3` rule into a 9-day threshold). Then I made it worse by writing README guidance teaching others to do the same. lucas42's response: "the architecture here is that the script calling updateScheduleTracker says how often it runs, and the schedule tracker calculates its alerting threshold. Don't write a document telling people to reverse engineer the process."

The mistake had two layers:
1. **The fix itself was dishonest** — passing fake values to chase a desired side-effect, instead of passing real values and addressing any problematic side-effect at its source.
2. **The documentation codified the dishonesty** — turning a one-off workaround into systemic guidance for future callers.

**How to apply:** Whenever a fix involves passing a value that doesn't reflect the truth ("the job runs every 7 days but I'll claim 3 to manipulate the alert"), stop. Either:
- Pass the truth and live with the resulting behavior; or
- Address the system whose behavior you're trying to fix.

If you find yourself reaching for "I'll just pass X here to get Y to happen", verify that's the API's documented intent. If it isn't, you're gaming an implementation detail, and a future change to that detail will silently break your callers.

When in doubt, the architectural question is: "would this still be the right value if the downstream system's logic changed?" If the answer is no, the value is wrong.
