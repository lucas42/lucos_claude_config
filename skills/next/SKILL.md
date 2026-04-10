---
name: next
description: Implement the next issue
disable-model-invocation: true
---

Follow this process. Do not ask for clarification -- immediately begin Step 1.

## Ad-hoc dispatch

If the user gives a specific issue URL to implement (rather than asking for the next issue from the queue), skip Step 1 and go straight to Step 2 with that issue. In parallel with dispatching via `/dispatch` in Step 2, update the issue yourself: set it to `priority:high`, ensure it's on the project board, and move it to the top of the Ready column. Read `~/.claude/references/triage-reference-data.md` for field IDs and API patterns. If the user is explicitly asking for an issue to be picked up, it's clearly high priority to them.

### Triage untriaged issues as part of ad-hoc dispatch

**If an ad-hoc dispatched issue has never been triaged** (e.g. no `agent-approved` label, no `owner:*` label, no priority label — often the case for issues raised moments before the user asks for them to be picked up), **do the triage inline as part of the dispatch** rather than refusing or waiting for a separate triage pass. Specifically:

1. Read the issue body and assess it against the normal triage criteria (clarity of outcome, clarity of approach, dependencies, architectural questions). If it is clearly specified and implementable, proceed. If not, stop and triage it through the normal refinement process instead — dispatching an un-implementable issue wastes the teammate's time.
2. Apply the full triage label set: `agent-approved`, `priority:high` (per ad-hoc rule above), and the appropriate `owner:*` label. If the user explicitly named an owner in their request, use that. Otherwise follow the normal implementation-assignment rules.
3. Add the issue to the project board and set Status=Ready, Priority=High, Owner=(matching the label). Position at the top of the Ready column. See `~/.claude/references/triage-reference-data.md` for field IDs.
4. Then proceed with `/dispatch` as normal.

Rationale: ad-hoc dispatch implies the user wants the work done *now*, and the untriaged state is usually just "this was raised minutes ago and hasn't hit a triage pass yet." Blocking on triage would be friction without benefit. But do not dispatch an issue that is genuinely unclear or un-implementable just because the user asked — if it needs refinement, say so and refine it instead.

## Step 1: Find the next issue

Run the global prioritisation script:

```bash
~/sandboxes/lucos_agent/get-next-implementation-issue
```

This searches across **all** repositories and **all** personas for the single highest-priority `agent-approved`, non-blocked issue. It prints three lines:

1. The owner label (e.g. `owner:lucos-developer`)
2. The issue number and title (e.g. `#42 Fix the thing`)
3. The issue URL

If the script reports no implementable issues, tell the user there is nothing ready to implement right now and stop.

## Step 2: Dispatch the issue

Use the `/dispatch` skill with the issue URL and the owner from Step 1:

```
/dispatch {issue_url} owner:{owner}
```

For example: `/dispatch https://github.com/lucas42/lucos_photos/issues/42 owner:lucos-developer`

For ad-hoc dispatch (where the user gives you a URL directly), omit the owner -- `/dispatch` will look it up from the project board.

The `/dispatch` skill handles all pre-dispatch validation (dependency checks, existing PR checks, convention/estate-rollout detection), dispatches to the correct teammate based on the owner, and handles post-completion (CI verification, auto-merge, unblocking dependents).

Wait for `/dispatch` to complete and report its outcome.
