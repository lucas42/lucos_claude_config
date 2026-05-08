# Raising follow-up issues from design or implementation work

When an ADR, review, or implementation surfaces follow-up work that needs to be raised as a GitHub issue, **how you split the work into issues matters**. This reference captures the rules.

## The invariant: never split a `lucos_repos` convention change and its rollout into separate issues

If a follow-up adds or modifies a convention in `lucos_repos` **and** any repos in the estate are expected to fail it (or stop failing it) when it lands, the convention and the rollout are **one piece of work**, not two. Raise them as a **single issue** scoped to the entire estate rollout, with a clear note in the body that says:

> This issue should be routed via `/estate-rollout`, not `/dispatch`. The convention work is implemented as a draft PR by the developer as part of that workflow — do not split it out into a separate issue.

### Why this matters

The `/estate-rollout` skill (`~/.claude/skills/estate-rollout/SKILL.md`) drives the work as an atomic unit:

1. Developer opens a **draft** PR with the convention change.
2. The CI dry-run diff shows which repos would fail.
3. Affected repos are migrated into compliance by the responsible persona.
4. The dry-run is re-run until zero new failures.
5. **Then** the convention PR is marked ready for review and merged.

The convention going live and the affected repos coming into compliance happen atomically from the audit tool's perspective, so the next sweep never raises findings on repos that are about to be migrated anyway.

If you instead split the work into "add the convention" and "do the rollout" as two separate issues, you set up a sequence where the convention PR can merge, the next audit sweep runs, and a batch of fresh audit findings appears on the affected repos before the rollout has had a chance to fix them. The rollout gets to chase the audit tool instead of working with it. This is exactly what happened with `lucas42/lucos_repos#316` + `#317` on 2026-04-10 and is the reason this rule exists.

## Scope of the rule

The rule applies to **any** new or modified `lucos_repos` convention that is expected to produce new audit findings on existing repos, not just ADR follow-ups. Triggering examples:

- A new convention that fails a set of existing repos on day one.
- A tightened rule in an existing convention that causes previously-passing repos to start failing.
- A loosened rule that causes previously-failing repos to stop needing their workarounds — if the workarounds themselves need to be cleaned up estate-wide.

## When the rule does not apply

If a new convention is expected to pass on every existing repo from the moment it lands (e.g. it codifies a pattern every repo already follows, with no migration implied), a plain `/dispatch`-routed implementation issue is fine — there is no rollout to couple to.

If you're unsure, **assume it's a rollout and use one issue**. The coordinator can always reroute a mis-tagged issue at triage, but they cannot un-split work that's already been split.

## Practical checklist when raising convention-related follow-ups

1. Ask: will any existing repo's pass/fail state on this convention change when it lands?
2. **If yes**: one issue, body says "route via `/estate-rollout`, not `/dispatch`", convention scope and migration scope both described in that one body.
3. **If no**: a normal follow-up issue is fine.
4. In both cases, cross-reference the ADR or design discussion that motivated the follow-up.
5. Do not set labels or project-board fields — the coordinator owns triage. See [`references/label-workflow.md`](label-workflow.md).

## See also

- [`references/issue-creation.md`](issue-creation.md) — how to actually create the issue (gh-as-agent patterns, file-backed body for placeholders).
- [`references/audit-finding-handling.md`](audit-finding-handling.md) — what happens after audit findings are raised.
- [`references/lucos-repos-api.md`](lucos-repos-api.md) — the `lucos_repos` API endpoints used during estate rollout (`/api/sweep`, `/api/rerun`).
