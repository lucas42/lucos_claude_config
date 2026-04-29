---
name: Read library READMEs before reverse-engineering APIs from source
description: When using a shared lucos library, read the repo's README/API reference first rather than inferring semantics from the function signature and the consuming server's code
type: feedback
---

When working with a shared lucos library (e.g. `lucos_schedule_tracker_pythonclient`, `lucos_loganne_pythonclient`, etc.), **read the repo's README first** to understand the API. Don't just infer semantics from the function signature in the source file plus the consuming server's code.

**Why:** lucas42 pointed out 2026-04-29 (during arachne#419 fix) that I'd worked out `frequency`'s meaning by reading the pythonclient's source plus the schedule-tracker Ruby server. The README in the pythonclient repo would have been faster and more authoritative — and not reading it meant I missed that the README itself was incomplete (it didn't document the × 3 server multiplier, which is the most consequential thing about `frequency`). Reading the README first surfaces both the answer and any documentation gaps worth fixing.

**How to apply:** Whenever I touch code that calls a `lucos_*_pythonclient` (or any other lucos shared library) and I'm uncertain about parameter semantics, default values, or behavior, read `~/sandboxes/<library>/README.md` before reading the library source. If the README is missing or incomplete, that's a finding worth a follow-up doc PR — file it before moving on.
