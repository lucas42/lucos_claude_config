---
name: project-mail-linked-creds
description: lucos_mail SMTP creds redesign (lucos_mail#86, 2026-10-02) — linked credentials replace hand-typed $$-escaped DOVECOT_USERS hashes; interacts with #85 blast radius and #83
metadata:
  type: project
---
lucos_mail#86 (filed 2026-10-02, awaiting lucas42): lucos_mail = server side of lucos_creds linked creds per sender (generated 32-char alnum, `CLIENT_KEYS`), committed client→address table is the enforcement + source for `smtpd_sender_login_maps` (unset on main), startup hashes via doveadm (not {PLAIN}); NAS keeps one `{SSHA512}` ($-free) hashed line. lucos-security endorsed; prerequisites #83 (`smtpd_tls_auth_only = no` today) and fresh passwords for all (completes #76).

**Why:** 2026-10-01 outage (lucos#313) — `#` typed next to `$` while hand-escaping; whole-file fail-closed check took down inbound MX.
**How to apply:** "agents have no production read" is FALSE (lucos-agent in docker group, lucos_agent_coding_sandbox#102) — don't use it as a premise. #85 (per-line skip) still needed but smaller. See also [[project-kanka-campaigns]].
