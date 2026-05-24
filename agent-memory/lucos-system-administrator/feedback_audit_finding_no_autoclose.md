---
name: feedback_audit_finding_no_autoclose
description: Audit-finding issues are never auto-closed by the audit tool — closure is the coordinator's responsibility.
metadata:
  type: feedback
---

The audit tool only **creates** issues; it never closes or updates them. Closing `audit-finding` issues is the coordinator's responsibility, once the convention passes on the repos dashboard.

**Why:** Confirmed in `~/.claude/references/audit-finding-handling.md` and by team-lead correction on 2026-05-24. The mistake was writing "The audit tool should auto-close this issue on the next sweep" in a completion comment and in a coordinator message.

**How to apply:** Never write "auto-close" or "the audit tool will close this" in any completion comment or status message for `audit-finding` issues. Instead: "the coordinator should close this once the dashboard shows pass."

See also: [[feedback_verify_timeline_before_stating]], `~/.claude/references/audit-finding-handling.md`
