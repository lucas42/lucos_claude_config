# Audit-Finding Issues

Issues with the `audit-finding` label are created automatically by the `lucos_repos` audit tool when a repository convention fails. These follow a specific lifecycle defined in [ADR-0002](https://github.com/lucas42/lucos_repos/blob/main/docs/adr/0002-audit-issue-lifecycle.md).

## How the audit tool works

The audit tool **only creates issues — it never closes or updates them.** This is by design, not a missing feature. The tool's scope is detection and reporting; issue lifecycle management is the coordinator's responsibility. Do not raise feature requests to change this without consulting the architect first.

## The re-raise rule

**Closing an audit-finding issue does NOT make the problem go away.** If the underlying convention still fails, the next audit sweep will create a brand-new issue for the same finding. The only way to permanently resolve an audit-finding issue is to make the convention pass — either by fixing the repo or by updating the convention's `Check` function.

## When to close an audit-finding issue

An audit-finding issue may ONLY be closed when the convention **currently passes** on the [dashboard](https://repos.l42.eu). Before closing, always verify the dashboard shows `pass` (not `fail`) for that repo+convention combination. If it still fails, the issue must stay open.

## When NOT to close an audit-finding issue

- **Convention still fails on the dashboard**: Keep it open. Fix the underlying problem first.
- **False positive with a pending fix tracked elsewhere**: Mark `agent-approved` + `status:blocked` with a reference to the fix issue. Do NOT close — closing will cause the audit to re-raise a new issue within hours.
- **Convention "doesn't apply" to the repo**: The fix is to update the convention's `Check` function in `lucos_repos` — not to close the issue.

## Other audit-finding actions

- **Triage audit-finding issues normally.** The `audit-finding` label is informational — apply the same triage process as any other issue.
- **False positive due to transient error**: Close the issue (convention should be passing on dashboard), and also raise an issue on `lucas42/lucos_repos` describing the false positive.

## Proposing changes to how the audit tool works

The audit tool (`lucos_repos`) has its own architecture and design constraints. Any proposal to change how it interacts with GitHub (e.g. having it close issues, update issues, or change its write scope) is an **architectural decision** — consult `lucos-architect` before raising issues or making changes.
