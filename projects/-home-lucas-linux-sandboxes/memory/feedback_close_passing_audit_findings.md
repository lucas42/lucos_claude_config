---
name: feedback_close_passing_audit_findings
description: "Close audit-finding issues promptly once their convention is verified passing — don't leave completed findings open waiting for the ≤6h auto-close sweep"
metadata:
  type: feedback
  originSessionId: c2a277ac-c41c-46d8-a202-07f86f739f5e
---

Once an audit-finding issue's convention is **verified passing** (e.g. `/api/rerun` after a fix, or the dashboard), close the issue immediately and set its board item Done. The audit tool's ≤6h auto-close (ADR-0004) is a **backstop, not the plan**.

**Why:** 2026-07-10, I left `lucos_aithne_jsclient#9` open after sysadmin verified the fix, citing the auto-close sweep. lucas42: "I don't want to wait 4 hours for another sweep. Please don't leave completed issues open."

**How to apply:** verify pass first — never close a still-failing finding (it just re-raises). Instruction home: `references/audit-finding-handling.md` "Closing audit-finding issues" section. Sibling issue-lifecycle guidance: [[feedback_report_followups_filed_not_deferred]].
