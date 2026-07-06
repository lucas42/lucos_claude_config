---
name: lesson-issue-body-open-questions
description: unverified remediation values must be a hard gate ("Open Questions" section) in issue bodies, not a soft hedge, or triage approves anyway
metadata:
  type: feedback
---

# Infrastructure issue bodies must block triage when scope is unverified (2026-03-21)

When raising a security issue that proposes a specific remediation value (a permissions
block, a config flag) for an infrastructure-touching change, if the exact value hasn't
been verified, **make the unresolved question a hard gate in the issue body**. A hedging
sentence ("exact scopes should be confirmed") isn't enough — triage will treat it as a
minor caveat and approve anyway.

Instead:

> **Prerequisite: confirm the correct permissions value before approving this issue for
> implementation. See the "Scope Question" section below.**

Or structure the body with a clear "Open Questions" section stating the issue should not
be `agent-approved` until answered.

Especially important for:
- GitHub Actions workflow permission changes (can break the workflow that merges the PR itself)
- Estate-wide convention changes via lucos_repos (50 simultaneous CI deployments if wrong)
- Any remediation where the exact value determines whether the fix works at all

**Root cause:** lucas42/lucos_repos#177 was approved before lucas42 confirmed the
correct `permissions` value, because the original hedge was too soft. The resulting
rollout with `permissions: {}` broke auto-merge across all ~45 repos. See incident
report: `docs/incidents/2026-03-21-permissions-block-rollout-without-smoke-tests.md`.
