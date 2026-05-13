---
name: feedback-breaking-change-when-callers-must-change-anyway
description: When all callers of a library are about to change their code anyway, a backwards-compatible library adds maintenance surface without saving anyone work — prefer a breaking change with a major version bump
metadata:
  type: feedback
---

When designing a library API change, **a backwards-compatible extension is only worth its complexity if it actually saves callers from a code change.** If every caller has to touch their code anyway, backwards compat in the library just adds branching logic (two endpoints, two code paths, conditional behaviour on optional params) without saving anyone any work — and now the library has to carry that maintenance surface forever.

**Why:** Default instinct on lucas42/lucos_schedule_tracker_pythonclient#40 was to extend `updateScheduleTracker(...)` with an optional `job_name` parameter and conditionally post to v1 or v2 depending on whether it was provided. lucas42 reversed: every caller in the estate had to split its synthetic `system="lucos_backups_prune"` into `system="lucos_backups", job_name="prune"` anyway — so a backwards-compat library couldn't save them from the code change. Breaking change + major version bump was simpler and let the library carry less state. The recommendation was wrong because I anchored on "library backwards compat is safer" without checking whether it was buying anything.

**How to apply:** Before recommending a backwards-compatible library design, run this check: *can existing callers keep their existing call sites unchanged after the library upgrade?* If the answer is no — because the shape of the data they pass has to change — then a breaking change with a major version bump is the cleaner choice. State the answer in the ADR/ticket body so it's reviewable.

Same logic applies to any layered API where the call shape has to change at the caller. Examples: protocol buffer schema changes, REST API contract changes, RPC interface changes, shared config-loading helpers. The question is "does backwards compat in the middle layer save the outer callers from changing?" If no, ship the break.
