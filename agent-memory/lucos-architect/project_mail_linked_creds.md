---
name: project-mail-linked-creds
description: lucos_mail SMTP creds redesign (lucos_mail#86, 2026-10-02) — linked credentials replace hand-typed $$-escaped DOVECOT_USERS hashes; interacts with #85 blast radius and #83
metadata:
  type: project
---
lucos_mail#86 (filed 2026-10-02, awaiting lucas42): lucos_mail = server side of lucos_creds linked creds per sender (generated 32-char alnum, `CLIENT_KEYS`), committed client→address table is the enforcement + source for `smtpd_sender_login_maps` (unset on main), startup hashes via doveadm (not {PLAIN}); REVISED 2026-10-18 per lucas42: NAS is a pseudo-system linked client (`external_nas`, like contacts' `external_calendar`) — no special case. lucos-security endorsed; prerequisites #83 (`smtpd_tls_auth_only = no` today) and fresh passwords for all (lucos_mail#76 closed not-planned 2026-10-21 — rotation is delivered by #86 itself, not a separate ticket).

**Why:** 2026-10-01 outage (lucos#313) — `#` typed next to `$` while hand-escaping; whole-file fail-closed check took down inbound MX.
**How to apply:** "agents have no production read" is FALSE (lucos-agent in docker group, lucos_agent_coding_sandbox#102) — don't use it as a premise. #85 CLOSED not_planned 2026-10-11 (whole-file fail-closed). Startup: unmapped CLIENT_KEYS entry → refuse; table entry w/o key → log (one direction must be lenient or table/creds non-atomic change + Dependabot deploy kills MX). Lesson: my "NAS plaintext = new exposure" argued about the OLD password; a fresh generated single-purpose key adds nothing. See also [[project-kanka-campaigns]].
