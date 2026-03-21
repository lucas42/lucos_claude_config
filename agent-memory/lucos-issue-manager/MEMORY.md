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
`owner:` labels indicate who should look next. Used with `needs-refining` (routing to lucas42 or the issue manager) and `agent-approved` (implementation assignment).
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

## Triage with inline agent consultation (introduced 2026-03-11)

- During triage, when an issue needs agent input, message the agent directly via SendMessage instead of labelling and waiting for a review phase
- Do not comment on the issue about what input is needed -- include that in the message to the agent
- Agent posts their comment/reaction on the issue, then messages back
- Re-assess after each agent response; consult additional agents one at a time if needed
- Stop after 3 rounds of agent consultation on the same issue -- route to lucas42
- Closed-issue review (step 0) is now folded into the start of each triage pass
- /routine skill is 3 phases: ops checks (parallel), triage with inline consultation (sequential), summary
- "review your issues" workflow has been retired; all specialist input happens inline during triage
- Documentation updated 2026-03-11: issue-workflow.md, agent-prompts.md, all agent persona files

Labels exist across 20+ repos (including newer repos like lucos_mail, lucos_physical_web, lucos_loganne_pythonclient, lucos_schedule_tracker_pythonclient, lucos_mockauthentication). See [label-colours.md](label-colours.md) for full colour scheme.

## Specialist follow-up routing (introduced 2026-03-03, updated 2026-03-11)

Two domains get specialist follow-up after the primary agent's input, before `agent-approved`:

- **SRE**: Issues touching monitoring, logging, observability, reliability, or incident management -- consult SRE after primary agent
- **Security**: Issues touching authentication, authorisation, data protection, secret management -- consult security after primary agent

Now handled inline during triage (message the specialist sequentially after the primary agent) rather than via label-based re-routing between triage passes.

## Triage readiness checks

- **Unknown target codebase = not ready for `agent-approved`.** If an issue doesn't yet know which repo or codebase the implementation belongs in, that's an unresolved architectural question. Route to the architect with `needs-refining` + `status:needs-design` + `owner:lucos-architect`. This applies even if the rest of the issue is well-specified -- "choose a location" is a design decision that must be resolved first.
- **Check for cross-issue dependencies when approving.** When an issue references another issue as a prerequisite (especially cross-repo), always consider whether `status:blocked` should be applied. This is easy to miss when transitioning from `needs-refining` to `agent-approved` because the focus is on the design being agreed, not on whether the work can actually start yet.

## Common pitfalls

- **Issue body formatting**: When creating/updating issue bodies that contain backticks or double quotes, always use the heredoc pattern (`--field body="$(cat <<'ENDBODY' ... ENDBODY)"`) with a single-quoted delimiter. Using `-f body="..."` with shell interpolation escapes backticks and quotes, producing `\`` and `\"` in the rendered markdown.
- When creating multiple sub-tickets that reference each other, the issue numbers are not known until each issue is created. Write bodies with placeholder references, then update them after all issues exist. Alternatively, create all issues first, note the actual numbers, then patch the bodies.
- When adding labels via POST to a repo that doesn't have them yet, GitHub auto-creates labels with default grey (`ededed`) colour. Always fix colours immediately after by PATCHing each new label.
- CodeQL issues raised by `lucos-security[bot]` are generally well-specified with file locations, rule IDs, and remediation steps -- can typically be approved directly without further security review.
- Issues from ops checks (`lucos-system-administrator[bot]`, `lucos-site-reliability[bot]`) are similarly well-specified and actionable.
- **Audit findings** from `lucos-repo-audit[bot]` are well-specified convention violations with clear problem statements, rationale, and suggested fixes. Can typically be approved directly. Watch for false positives where the convention doesn't apply (e.g. `circleci-uses-lucos-orb` on repos that don't use Docker deploys, or on the orb repo itself). See "Audit-finding issue lifecycle" section below for how these issues interact with closure and re-creation.
- **Project board sync is mandatory for every triage action.** After adding/changing labels on any issue, also update the project board (add issue, set fields, reposition). This was missed on lucos_photos_android#73 (2026-03-13) despite explicit instructions. Treat board sync as the final step of every triage action -- do not consider an issue "triaged" until the board is updated.

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
- **When a convention is deleted/replaced**, all open issues referencing the old convention become obsolete. Close them as completed (the goal was achieved by the replacement). The audit will not re-raise them because the old convention no longer runs.
- **False positive audit findings on blocked issues**: If the convention genuinely doesn't apply but hasn't been fixed yet (e.g. lucos_deploy_orb can't use its own orb), mark as `agent-approved` + `status:blocked` with a reference to the fix issue. Do NOT close -- closing causes the audit to re-raise on the next sweep.
- **Closing audit-findings as false positives**: When closing a false positive (e.g. transient API error), also raise an issue on `lucas42/lucos_repos` about the root cause, or comment on an existing issue if one covers that class of false positive. Example: lucos_backups#51 was a 502-induced false positive, led to lucos_repos#102.
- **Batch-closing after a checker fix**: When a convention checker bug is fixed (e.g. lucos_repos#150 fixing the `contexts` vs `checks` field), close ALL blocked audit-finding issues for that convention immediately. Do NOT suggest "waiting for the next audit sweep to distinguish real from false positives" -- the audit only creates issues, never closes them, so waiting just leaves stale issues open. Close them now; any genuinely failing repos will get fresh issues on the next sweep.

## Project board sync (introduced 2026-03-12)

- **MANDATORY: Every triage action that changes labels MUST also update the project board.** This includes approving, routing to needs-refining, and closing issues. No exceptions. The board sync is as essential as the label change itself.
- Project: "lucOS Issue Prioritisation" at https://github.com/users/lucas42/projects/8
- Use `~/sandboxes/lucos_agent/gh-projects` (PAT-based) for all project board API calls, not `gh-as-agent`
- Issue manager syncs board during triage: adds issues, sets Status/Priority/Owner fields
- Built-in workflows handle: item added -> Needs Triage, item closed -> Done, PR merged -> Done
- **Always paginate board queries.** The board has 180+ items across multiple pages (100 per page). A single-page query misses items and produces incorrect analysis. Always check `pageInfo.hasNextPage` and follow cursors.
- Full field/option ID reference is in the persona file's "Project Board Sync" section
- `addProjectV2ItemById` is idempotent -- safe to call even if issue is already on board
- **DANGER: `updateProjectV2Field` with `singleSelectOptions` regenerates ALL option IDs.** This orphans every existing item's field value (sets to null), AND disables all board workflows that reference those options. Must re-assign status to every item afterwards, and workflows must be manually re-enabled via the board settings UI (no API for this). Learned 2026-03-14 when removing columns wiped all 187 items' statuses and disabled 3 workflows. **Avoid this mutation if at all possible.**
- GitHub user node ID for lucas42: `MDQ6VXNlcjQyODg0Nw==` (legacy) / `U_kgDOAAaLLw` (new)
- **Always reposition items by priority after adding.** The board uses manual position ordering (no auto-sort). The prioritisation script sorts by board position, not labels -- wrong position = wrong pickup order. Critical/High: move to top (no `afterId`). Medium: place after the last High item (or move to top if unknown). Low: leave at bottom (default). Never skip this step -- it was missed on lucos_photos#208 (2026-03-16) despite existing instructions.

## Feedback

- [Issue granularity](feedback_issue_granularity.md) — lucas42 prefers not to split small, related findings (like permission gaps) into separate tickets; handle inline
- [Re-check after consultation](feedback_recheck_after_consultation.md) — after an agent posts a comment, always re-read ALL comments AND check reactions; lucas42 may approve via +1 reaction rather than a text reply
- [Hedged issues need specialist verification](feedback_hedged_issues.md) — when an issue body hedges on the correct fix ("should be confirmed", "probably"), treat it as an unresolved question requiring specialist input before approving. Learned from lucos_repos#177 incident (2026-03-21).

## Issue closure policy

- lucos-issue-manager IS allowed to close issues directly when confident no further work is needed
- Examples: issue superseded by other issues, split into sub-tickets, agreed in discussion to be obsolete
- Use `state_reason="completed"` when the goal was achieved (e.g. via sub-tickets), `"not_planned"` when discarding
- Always leave a brief comment explaining why before closing
- Remove `needs-refining`, `status:*`, and `owner:*` labels before closing
- Granted by lucas42 on 2026-03-03
