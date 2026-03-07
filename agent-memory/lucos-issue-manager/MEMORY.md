# Agent Memory - lucos-issue-manager

## Repo-specific notes

See [repo-notes.md](repo-notes.md) for per-repo conventions and context.

## GitHub API

- Pass body text and other fields inline using `-f key=value` — no need to write payload files
- When using `--app lucos-issue-manager` as the first argument to `gh-as-agent`, all other arguments are passed through to `gh api`
- `lucos-issue-manager` app has read & write access to repo contents -- can write files via Contents API and git push

## Process documentation

- lucos-issue-manager is responsible for maintaining process documentation (labels docs, workflow docs, triage process docs, etc.)
- Canonical label docs live at `docs/labels.md` in the `lucas42/lucos` repo (see also Label documentation section below)
- When process or workflow changes are agreed, update the relevant docs as part of the same piece of work

## Label documentation

- Canonical label docs live at `docs/labels.md` in the `lucas42/lucos` repo (also referenced in Process documentation section above)

## Label conventions

- `agent-approved` and `needs-refining` are created by this agent when they don't already exist in a repo
- Always check for existing labels before creating them to avoid duplicates
- Always set a meaningful colour when creating labels -- see [label-colours.md](label-colours.md) for the canonical colour scheme
- `agent-approved` = `0e8a16` (green), `needs-refining` = `d93f0b` (orange)
- User `lucas42` has explicitly requested consistent label colours across all repos

## Triage labels

### Status labels
- `status:ideation` -- goal/scope still vague; park until relevant (used with `needs-refining`)
- `status:needs-design` -- goal clear but needs implementation detail from an agent (used with `needs-refining`)
- `status:awaiting-decision` -- options discussed, waiting for lucas42 to pick one (used with `needs-refining`)
- `status:blocked` -- well-defined but blocked by another issue (used with `agent-approved`)

### Owner labels
`owner:` labels indicate who should look next. Used with both `needs-refining` (review) and `agent-approved` (implementation).
- `owner:lucas42`, `owner:lucos-architect`, `owner:lucos-system-administrator`, `owner:lucos-site-reliability`, `owner:lucos-security`, `owner:lucos-developer`

### Priority labels
- `priority:critical` (dark red `e11d48`) -- full service outage only; production down, users affected. Not for important features or bugs with workarounds.
- `priority:high` (red), `priority:medium` (yellow), `priority:low` (light blue)
- No priority label = not yet prioritised (distinct from medium)
- Set during triage for ALL issues (including `needs-refining`), not just `agent-approved`
- Re-assess priority after lucas42 gives input (scope/urgency may have changed)
- lucas42's explicit priority calls override strategic priorities (final say)
- Other agents' priority calls are input, not overrides -- assess within strategic priorities context

### Implementation assignment (introduced 2026-03-03)
When marking `agent-approved`, also assign an `owner:*` label for implementation:
- Default: `owner:lucos-developer`
- Purely infra: `owner:lucos-system-administrator`
- Purely monitoring/logging/pipelines: `owner:lucos-site-reliability`
- Incident management (response, reporting, post-mortems, tracking): `owner:lucos-site-reliability`
- Purely security: `owner:lucos-security`
- Workflow/process docs: `owner:lucos-issue-manager`
- Mixed work: `owner:lucos-developer` (ensure specialist reviewed first)

## Review capability (introduced 2026-03-05)

- lucos-issue-manager responds to both "triage your issues" and "review your issues"
- Review covers `needs-refining` issues assigned via `owner:lucos-issue-manager` -- typically workflow, process docs, issue conventions
- Uses `get-issues-for-persona --review lucos-issue-manager` for discovery
- Participates in Phase 2 of /routine skill (alongside specialist agents)
- lucos-developer also participates in Phase 2 review for design-phase input

Labels exist across 20+ repos (including newer repos like lucos_mail, lucos_physical_web, lucos_loganne_pythonclient, lucos_schedule_tracker_pythonclient, lucos_mockauthentication). See [label-colours.md](label-colours.md) for full colour scheme.

## Specialist follow-up routing (introduced 2026-03-03)

Two domains get specialist follow-up after the primary owner finishes, before `agent-approved`:

- **SRE**: Issues touching monitoring, logging, observability, reliability, or incident management (response, reporting, post-mortems, tracking) get re-routed to `owner:lucos-site-reliability`
- **Security**: Issues touching authentication, authorisation, data protection, secret management, or other security topics get re-routed to `owner:lucos-security`

Both also apply mid-lifecycle if concerns are raised in comments after initial triage.
Examples: pici#2 (monitoring, primary owner sysadmin), lucos_monitoring#26 (monitoring endpoint, primary owner architect)

## Triage readiness checks

- **Unknown target codebase = not ready for `agent-approved`.** If an issue doesn't yet know which repo or codebase the implementation belongs in, that's an unresolved architectural question. Route to the architect with `needs-refining` + `status:needs-design` + `owner:lucos-architect`. This applies even if the rest of the issue is well-specified -- "choose a location" is a design decision that must be resolved first.

## Common pitfalls

- **Issue body formatting**: When creating/updating issue bodies that contain backticks or double quotes, always use the heredoc pattern (`--field body="$(cat <<'ENDBODY' ... ENDBODY)"`) with a single-quoted delimiter. Using `-f body="..."` with shell interpolation escapes backticks and quotes, producing `\`` and `\"` in the rendered markdown.
- When creating multiple sub-tickets that reference each other, the issue numbers are not known until each issue is created. Write bodies with placeholder references, then update them after all issues exist. Alternatively, create all issues first, note the actual numbers, then patch the bodies.
- When adding labels via POST to a repo that doesn't have them yet, GitHub auto-creates labels with default grey (`ededed`) colour. Always fix colours immediately after by PATCHing each new label.
- CodeQL issues raised by `lucos-security[bot]` are generally well-specified with file locations, rule IDs, and remediation steps -- can typically be approved directly without further security review.
- Issues from ops checks (`lucos-system-administrator[bot]`, `lucos-site-reliability[bot]`) are similarly well-specified and actionable.
- **Audit findings** from `lucos-repo-audit[bot]` are well-specified convention violations with clear problem statements, rationale, and suggested fixes. Can typically be approved directly. Watch for false positives where the convention doesn't apply (e.g. `circleci-uses-lucos-orb` on repos that don't use Docker deploys, or on the orb repo itself). See "Audit-finding issue lifecycle" section below for how these issues interact with closure and re-creation.

## Ops check duplicate prevention (introduced 2026-03-05, strengthened 2026-03-06)

- All three ops-check personas (security, SRE, sysadmin) have explicit "Duplicate prevention" instructions in their persona files
- They must search open issues before creating new ones, and comment on existing issues with new info rather than creating duplicates
- Additionally, all three must scan the 10 most recent open issues in the target repo (broad scan) to catch cross-persona duplicates where different agents describe the same root cause differently
- Prompted by lucos_backups#34 (sysadmin) and lucos_backups#43 (SRE) being duplicates of the same find+du timeout issue
- Documented in `docs/issue-workflow.md` in the lucos repo

## Closed issue review tracking

- See [closed-issues-reviewed.md](closed-issues-reviewed.md) for which closed issues have been checked for learnings
- Last reviewed: 2026-03-06 (10 issues, no concerns)

## Audit-finding issue lifecycle (ADR-0002 in lucos_repos)

Key principles for triaging `audit-finding` issues:

- **The audit result is the source of truth, not the issue.** The audit tool checks whether a convention passes or fails *right now*. Issue state is just a notification mechanism.
- **The audit tool only creates issues; it never closes, reopens, or comments on them.** When a convention starts passing, the tool simply does nothing -- it does not close the issue or comment "now passing".
- **Closing an audit-finding issue is the triage manager's job** (or whoever merges the fixing PR). If a PR with `Closes #N` is merged and the fix is correct, the issue stays closed. If the fix was incomplete, the next audit sweep (up to 6 hours) creates a *new* issue.
- **Never leave audit-finding issues open "waiting for the audit to close them"** -- the audit tool will never close them. Triage and close them through the normal workflow (PR merge with closing keyword, or manual close if obsolete).
- **Never close audit-finding issues expecting the audit to "clean up"** by not re-raising them -- if the convention still fails, a new issue will be created on the next sweep.
- **New issues, not reopened ones.** If a convention regresses after being fixed, the audit creates a brand new issue referencing the old one. It does not reopen the closed issue.
- **No suppression mechanism.** If a convention genuinely doesn't apply to a repo, the convention's check function must encode that logic. There is no `audit-suppressed` label.
- **`audit-finding` label** is present on every audit-raised issue for efficient querying and visibility.

## Issue closure policy

- lucos-issue-manager IS allowed to close issues directly when confident no further work is needed
- Examples: issue superseded by other issues, split into sub-tickets, agreed in discussion to be obsolete
- Use `state_reason="completed"` when the goal was achieved (e.g. via sub-tickets), `"not_planned"` when discarding
- Always leave a brief comment explaining why before closing
- Remove `needs-refining`, `status:*`, and `owner:*` labels before closing
- Granted by lucas42 on 2026-03-03
