---
name: feedback-estate-dns-ci-pattern
description: When GitHub Actions + CircleCI both fail *.l42.eu DNS simultaneously, it's an authoritative DNS outage, not a PR-specific CI issue — don't flag as a PR defect
metadata:
  type: feedback
---

**When reviewing CI failures**: if GitHub Actions and CircleCI runners both fail DNS resolution for `*.l42.eu` at the same time while `github.com` resolves fine, this is an authoritative DNS source failure, not a test regression or a PR defect.

**Why:** Both CI systems use public DNS resolvers (8.8.8.8, 1.1.1.1) and resolve via the same BIND primary. If that primary's zone is broken, all public resolvers SERVFAIL on `*.l42.eu` simultaneously. Confirmed during the 2026-06-07 estate-wide DNS outage: convention-check on lucos_dns#103 failed at 23:38:00–23:38:04 (GitHub Actions) and CircleCI build #669 failed (`getaddrinfo creds.l42.eu`) — both symptoms of the same BIND apex failure.

**How to apply:** When two independent CI vantage points fail DNS for `*.l42.eu` within seconds of each other, do NOT block the PR. Note the estate outage in your review and verify the failure clears on CI re-run once DNS is restored. The `code-reviewer-auto-merge.yml` workflow also fails closed-and-silent in this scenario (tracked as `lucas42/.github#68`).

**Secondary pattern:** "configy endpoint flap" (auto-merge skips because it can't read supervision status) is another symptom of the same DNS outage — configy itself is resolvable only via the broken apex.
