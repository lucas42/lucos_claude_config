---
name: risk-lucos-mail-credential-hashes-in-repo
description: lucos_mail commits SASL password hashes to its public repo (postfix/users) — deliberate documented pattern, years-unrotated, flagged as lucos_mail#75
metadata:
  type: project
---

`lucas42/lucos_mail`'s `postfix/users` file stores SHA512-CRYPT password hashes for SMTP AUTH accounts, committed directly to git. Documented as the intended workflow in the repo's README ("Adding new users" / "Rotating a user's password") — deliberate, not an oversight or `.gitignore` slip.

Two real accounts as of 2026-08-08: `monitoring@l42.eu` (hash last rotated 2023-01-05, itself prompted by a CircleCI security incident — password changed but storage pattern didn't) and `nas@l42.eu` (unrotated since account creation 2022-06-25). Both hashes have been continuously public for 3.5-4 years.

Flagged as lucas42/lucos_mail#75 (2026-08-08, Medium severity — public issue, not advisory, since exploitation requires offline cracking first, i.e. conditional not immediate). Open Question in the issue: haven't verified whether Dovecot/Postfix can source credentials from a runtime env var (lucos_creds-backed) vs. requiring the current checked-in flat file — needs developer confirmation before remediation approach is locked in.

**Why:** offline-crackable exposure is decoupled entirely from the live server's own rate-limiting/lockout — an exposed hash gives an attacker unlimited, undetectable attempts regardless of how well the server itself defends against online brute-force.

**How to apply:** don't re-raise the "brute-force noise against nonexistent usernames" as a finding — that's confirmed harmless (see [[risk-prompt-injection-and-ci-logs]] sibling pattern of "check what's actually true before treating log noise as a finding"). Do check this issue's status before assuming lucos_mail's credential storage is still unfixed — if #75 closes, re-verify current `postfix/users` state before citing this pattern again. If other repos turn up a similar "secret hash/value committed as documented process" pattern, this is the precedent for how it was routed (public issue + Open Questions gate, not advisory, not private).
