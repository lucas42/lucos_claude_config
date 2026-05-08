---
name: Implementation surface claims must be code-trace-backed, not data-flow-extrapolated
description: When naming repos that need code changes in a triage assessment, cite the specific file/function — don't extrapolate from the conceptual data flow
type: feedback
---

When a triage assessment names an "implementation surface" (the list of repos that need code changes to ship a feature), each repo claim must be backed by code-trace evidence — cite the specific file/function that would need to change. Do not extrapolate from the conceptual data flow.

**Why:** On lucos_media_weightings#212 (2026-05-08), I named four repos in the implementation surface based on the conceptual flow (media_manager → metadata API → loganne → weightings). Three of them (metadata API, loganne config) actually needed no changes — the generic v3 tag write path, per-predicate `updateNeeded` detection, automatic `trackUpdated` emission, and the existing loganne fan-out config all handle the new tags without modification. lucas42 corrected me; the actual surface was 2 repos. Reasoning from the diagram added phantom work and risked misrouting effort.

**How to apply:** When writing a triage assessment that names repos for implementation:

1. Open each named repo's actual code, not just its README or your mental model.
2. For each repo claim, point to a specific file/function that would change (e.g. "`Playlist.completeTrack()` needs to call the metadata API"). If you can't, the repo probably doesn't need touching — its current generic paths likely cover the new case.
3. Be especially suspicious for fan-out / proxy / config-driven services (loganne, configy, repos with predicate registries, RDF emitters): they often handle new cases generically and the data-flow diagram makes them look like touch-points when they aren't.
4. Same shape as the "name the consumer" Loganne test (`reference_loganne_consumer_test.md`): a sharp falsifiable check at design time, not a reviewer-pushback fix.
