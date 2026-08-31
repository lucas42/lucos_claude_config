---
name: lucos-agent-79-triage-ready-exclusion
description: get-issues-for-triage no longer resurfaces coordinator-owned Ready issues on every pass
metadata:
  type: project
---

`lucos_agent`#79: RESOLVED 2026-08-31, PR #83 merged. `get-issues-for-triage`'s criterion 3 (`Owner == ISSUE_MANAGER_OWNER`) now requires `and status != READY_STATUS`. A coordinator-owned Ready issue falls through to criterion 5 (`should_include_ready`, the fresh-`lucas42`-comment check) instead of being surfaced unconditionally every pass. Refinement-stage coordinator-owned issues (Ideation/Needs Analysis/Awaiting Decision) still hit criterion 3 unconditionally, unaffected.

**Why the premise held rather than "the resurfacing is the feature":** `get-next-implementation-issue` already scans the same board for Status=Ready across *all* owners, position-ordered, with no owner exclusion — coordinator-owned Ready work already has a correct discovery path, so `get-issues-for-triage`'s version was a worse duplicate, not a needed backstop.

**Verification pattern:** no test harness exists for this script (it only operates against the live board) — verified with a live read-only before/after diff of actual output instead of a synthetic fixture. Confirmed one example (`lucos_claude_config`#152) via a direct GraphQL field query rather than trusting the script's own classification, per [[feedback_verify_before_propagating]].
