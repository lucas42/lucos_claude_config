# Audit-Finding Issues

Issues with the `audit-finding` label are created automatically by the `lucos_repos` audit tool when a repository convention fails. These follow a specific lifecycle defined in [ADR-0002](https://github.com/lucas42/lucos_repos/blob/main/docs/adr/0002-audit-issue-lifecycle.md), **as amended by [ADR-0004](https://github.com/lucas42/lucos_repos/blob/main/docs/adr/0004-auto-close-audit-finding-issues.md)** (auto-close on pass).

## How the audit tool works

The audit tool creates audit-finding issues when a convention fails and — per ADR-0004 — **auto-closes them when the convention passes**, on the next sweep (≤6h; it closes on the first pass, with no consecutive-pass threshold), posting a short "now passing — closing" comment. The **audit result (does the convention pass or fail right now), not issue state, is the source of truth.** Any change to how the tool interacts with GitHub is an architectural decision — consult `lucos-architect` first.

## The re-raise rule

**Closing an audit-finding issue does NOT make the problem go away.** If the underlying convention still fails, the next audit sweep will create a brand-new issue for the same finding. The only way to permanently resolve an audit-finding issue is to make the convention pass — either by fixing the repo or by updating the convention's `Check` function.

## Closing audit-finding issues — the tool does it automatically

You do **not** need to manually close an audit-finding issue when its convention starts passing: the audit tool auto-closes it itself within one sweep (≤6h), per ADR-0004. Manually closing early is an optional board-cleanliness convenience, **harmless only when the convention already passes** on the [dashboard](https://repos.l42.eu) — verify it shows `pass` first if you do. Never manually close a **still-failing** finding: the next sweep just re-raises a new one (see the re-raise rule above).

## When NOT to close an audit-finding issue

- **Convention still fails on the dashboard**: Keep it open. Fix the underlying problem first.
- **False positive with a pending fix tracked elsewhere**: Set Status = Blocked on the project board with a reference to the fix issue. Do NOT close — closing will cause the audit to re-raise a new issue within hours.
- **Convention "doesn't apply" to the repo**: The fix is to update the convention's `Check` function in `lucos_repos` — not to close the issue.

## Other audit-finding actions

- **Triage audit-finding issues normally.** The `audit-finding` label is informational — apply the same triage process as any other issue.
- **False positive due to transient error**: Close the issue (convention should be passing on dashboard), and also raise an issue on `lucas42/lucos_repos` describing the false positive.

## Proposing changes to how the audit tool works

The audit tool (`lucos_repos`) has its own architecture and design constraints. Any proposal to change how it interacts with GitHub (e.g. having it close issues, update issues, or change its write scope) is an **architectural decision** — consult `lucos-architect` before raising issues or making changes.
