---
name: project-schedule-tracker-v2-gating
description: Gating sequence before lucos_schedule_tracker v2 API implementation (from ADR-0004) can begin
metadata: 
  node_type: memory
  type: project
  originSessionId: 4baabbd0-6778-4cfa-b190-0f9fb337f4cf
---

Before any v2 implementation work from ADR-0004 (lucos PR #143) begins on lucos_schedule_tracker, three things must happen in order (2026-05-13):

1. SRE completes a test-suite review of lucos_schedule_tracker and files recommendations.
2. Those test-suite recommendations are implemented.
3. `unsupervisedAgentCode` flag is flipped to `true` for lucos_schedule_tracker.

**Why:** lucas42 wants the test suite at a quality bar that justifies unsupervised agent code on the repo *before* v2 (a non-trivial change spanning ~20 cron callers) is shipped through it.

**How to apply:**
- The three v2 implementation tickets the architect plans to raise (v2 `/report-status`, `GET /jobs`, `fetcher_scheduled_jobs` in lucos_monitoring) must be raised as Status = Blocked, referencing the SRE test-suite tracking issue as the explicit blocker.
- Do NOT dispatch any of those three until the gating sequence is complete.
- The `fetcher_scheduled_jobs` ticket lives on lucos_monitoring, not lucos_schedule_tracker — but it's still gated on the same flow because the consumer side needs the v2 producer to exist.
- See [[project-v3-migration]] for the related pattern of holding v-bump implementation behind a quality gate.
