---
name: /_info endpoint boundary — availability/configuration only
description: When proposing monitoring checks, /_info is for availability/configuration only — content-rendering correctness belongs elsewhere
type: project
---

**The `/_info` endpoint is an availability/configuration check by design, not a content-rendering correctness check.** This is an architectural boundary, not a soft preference: lucos-architect's explicit verdict (2026-04-29, on `lucas42/lucos_monitoring#207`) was that conflating the two is a category error.

**Why:** content-rendering correctness (does the rendered HTML actually pull in the expected CSS, do static assets return 200, does JS load) sits at a different layer from "is the service alive and what tier of health check should you run on it." If `/_info` advertised which static URLs to probe, every consumer of `/_info` would suddenly carry coupling to render-side concerns that have nothing to do with availability.

**How to apply:** when proposing a new monitoring check, decide first which side of the boundary it sits on:

- **Availability / configuration / health-tier metadata** → `/_info` is appropriate. New `/_info` fields are reasonable here.
- **Content rendering / page integrity / asset reachability** → NOT `/_info`. Pick one of:
  1. Build-time positive assertion in CI (cheapest, fails loudly, no runtime burden) — preferred unless there's a runtime-only failure mode
  2. Synthetic probe that's clearly distinct from `/_info` (separate URL list, separate check type, separate response model)

**Where this came from:** the 2026-04-29 eolas/contacts styling incident. After lucos-ux raised the "should `/_info` advertise UI integrity URLs" question, lucos-architect's verdict was an explicit "no — don't be tempted to fold UI content checks into the `/_info` schema." Resolved on `lucas42/lucos_monitoring#207`. The lean is now toward letting build-time CI (`lucas42/lucos_eolas#219`, `lucas42/lucos_contacts#673`) catch this incident class, with the monitoring-side option held in reserve only if a runtime-only failure mode surfaces.

**Telltale that you're drifting toward a category error:** if your proposed `/_info` field is helping monitoring decide what to probe at the *content* layer, you're on the wrong side of the boundary. `/_info` should answer "is the service up and how do you check it" — not "which URLs render which assets."

**The dependency-inversion argument** (architect, on the same `lucos_monitoring#207` thread, sharpening the category-error point): a service advertising its own monitoring directives via `/_info` is a dependency inversion that monitoring should be free of — a partially-failed service could claim "no UI checks needed" and silence the monitor. This is a stronger argument than just "category error": it's that service-side opt-in for *what gets monitored* creates a class of failures where the broken service is the one telling monitoring not to look. If a future need arises to expand the monitoring contract, that's an ADR conversation about the contract — not a quiet `/_info` schema extension.

**CI-vs-runtime is not an either/or** (architect, same thread): build-time CI checks see *the artefact*; runtime monitoring sees *the system*. They catch different failure modes — runtime catches things CI is blind to (volume shadowing recurrence, wrong image deployed, nginx/router path rewrites between service and edge, future `STATIC_URL` refactors that ship a working artefact via a broken serving path). When deciding which detection layer is appropriate for a class of failure, ask "is the failure visible in the artefact alone, or only when the artefact runs in the system?" — they aren't redundant.
