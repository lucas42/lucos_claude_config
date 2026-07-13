---
name: feedback_audit_finding_no_autoclose
description: SUPERSEDED AGAIN 2026-07-13 — close verified-passing audit-findings myself promptly; don't wait for the tool's auto-close.
metadata:
  type: feedback
---

**History of this memory (kept so the reversals don't repeat):**
- Written 2026-05-24: audit tool never auto-closes `audit-finding` issues. True at the time.
- Corrected 2026-07-10: `lucos_repos` ADR-0004 added auto-close on pass — confirmed via
  `lucas42/lucos_aithne_jsclient#2/#3/#4` auto-closing within minutes. That correction then
  over-rotated into "so don't manually close them, and don't editorialize about the mechanism"
  — which got written into both this memory and the persona file's "Working on Issues —
  Sysadmin Extensions" section.
- **Corrected again 2026-07-13:** that "don't manually close" reading was itself wrong.
  `~/.claude/references/audit-finding-handling.md` (also updated 2026-07-10, but the update
  hadn't fully propagated into the persona file until today) is explicit: auto-close is a
  **backstop, not the plan** — lucas42 does not want completed findings sitting open for
  hours. Found this as a live contradiction between the persona file and its own linked
  reference during the 2026-07-13 ops-checks run; fixed the persona text in place
  (lucos_claude_config@280f30c) rather than leaving both versions live.

**Current behaviour (as of 2026-07-13) — this is the one to trust:** once you've verified a
convention now passes (`/api/rerun` for non-Type-gated conventions, full `/api/sweep` for
Type-gated ones), **close the audit-finding issue yourself immediately** with a comment citing
the verification evidence, and set its board item to Done. Don't wait for the tool's own ≤6h
sweep. Only exceptions: still failing (leave open), false positive with a fix tracked
elsewhere (Blocked + reference, don't close), or convention doesn't apply (fix the `Check`
function, don't close the issue). Full lifecycle in
`~/.claude/references/audit-finding-handling.md` — treat that file, not this one, as the
source of truth on the *mechanism*; this memory just tracks that the mechanism has flipped
twice so I don't reintroduce either wrong reading.

**Verification gotcha (still true):** confirming "pass" for a `Type`-gated convention (e.g.
`in-lucos-configy`) requires a full `POST /api/sweep` — `/api/rerun` reuses the last sweep's
cached `RepoContext.Type` and will keep reporting stale fails after a `lucos_configy`
registration change. See [[configy-undeployed-system-entry-pattern]]. Filed as
lucas42/lucos_repos#453.

See also: [[feedback_verify_timeline_before_stating]], `~/.claude/references/audit-finding-handling.md`
