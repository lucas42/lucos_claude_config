---
name: feedback_audit_finding_no_autoclose
description: SUPERSEDED 2026-07-10 — audit-finding issues DO auto-close now, per ADR-0004.
metadata:
  type: feedback
---

**Correction (2026-07-10):** this memory previously said the audit tool never auto-closes
`audit-finding` issues. That was true when written (2026-05-24) but is now superseded by
`lucos_repos` ADR-0004 (auto-close on pass) — confirmed directly when
`lucas42/lucos_aithne_jsclient#2/#3/#4` all auto-closed with `state_reason: "completed"`
within minutes of their conventions starting to pass, no manual close needed.
`~/.claude/references/audit-finding-handling.md` already documents ADR-0004 correctly; the
persona file's "Working on Issues — Sysadmin Extensions" section had drifted stale and was
fixed the same day (lucos_claude_config@2cba423).

**Current behaviour:** the audit tool auto-closes an `audit-finding` issue itself on the next
sweep (≤6h, first pass, no consecutive-pass threshold) once its convention passes. Don't
manually close it — but also don't need to ask the coordinator to close it either.

**How to apply now:** when reporting a resolved audit-finding, state the verified fact only —
"convention now passes — closure-ready" or "convention not yet passing — still in progress".
Don't editorialize about *who or what* closes it either way; both over-claiming auto-close
(the 2026-05-24 mistake) and under-claiming it (this memory's original text) are wrong in
different directions — the tool's actual behavior is documented in
`~/.claude/references/audit-finding-handling.md`, so defer to that rather than restating a
mechanism from memory.

**Verification gotcha:** confirming "pass" for a `Type`-gated convention (e.g.
`in-lucos-configy`) requires a full `POST /api/sweep` — `/api/rerun` reuses the last sweep's
cached `RepoContext.Type` and will keep reporting stale fails after a `lucos_configy`
registration change. See [[configy-undeployed-system-entry-pattern]]. Filed as
lucas42/lucos_repos#453.

See also: [[feedback_verify_timeline_before_stating]], `~/.claude/references/audit-finding-handling.md`
