---
name: triage
description: The coordinator triages all open issues with inline agent consultation
disable-model-invocation: true
---

Perform triage directly and summarise the results. Do not ask for clarification — immediately begin.

## Step 0: Review Closed Issues You Raised

Before triaging new issues, check whether any issues you previously raised have been closed:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager \
  "search/issues?q=author:app/lucos-issue-manager+org:lucas42+is:issue+is:closed+sort:updated-desc&per_page=10"
```

For each closed issue: read the final comments to understand the closure reasoning. If it reflects a decision or preference you weren't aware of, update your memory. Skip issues you've already reviewed. Also use this step to **clean up the project board**: for any recently closed issue still on the board, remove it using `deleteProjectV2Item`.

## Step 1: Discover and Triage Issues

```bash
~/sandboxes/lucos_agent/get-issues-for-triage
```

This returns a JSON array of all issues that currently need your attention. An issue is included if **any** of the following is true:

- **Unlabelled** — has never been triaged; needs initial triage.
- **`needs-refining`** and the most recent comment is NOT from `lucos-issue-manager[bot]` — an owner agent has probably completed work and the issue needs a label transition (or someone has replied and it needs another look).
- **`owner:lucos-issue-manager`** — explicitly routed back to you for action.

Issues labelled `agent-approved` are never included. Pull requests and archived repositories are excluded.

Work through each issue using the full triage procedure in `~/.claude/references/triage-procedure.md`. Also read `~/.claude/references/triage-reference-data.md` for project board IDs, field mappings, and API patterns. When consulting agents during triage, wait for each response before re-assessing the issue. Triage is complete when all issues are processed and all consultations are resolved.

If the script returns an empty array, report that there is nothing needing triage right now.

**Never revert a label change without reading the comments first.** If an issue you previously labelled `agent-approved` now appears as `needs-refining`, someone (likely lucas42) changed the label deliberately. Read the comments to understand why before taking any action.

## Step 2: Board Verification — "Needs Triage" Must Be Empty

After processing all issues in Step 1, verify that no items remain in the "Needs Triage" board column. Query the project board for items with status `79f7273e` (Needs Triage). If any are found:

- **Unlabelled**: triage now using Step 1.
- **`needs-refining` + `status:needs-design`**: a previous pass parked this instead of consulting the agent inline. Do the consultation now, then re-assign to the correct column.
- **`needs-refining` + `status:awaiting-decision`**: board status wasn't updated — move to "Awaiting Decision" (`cf5e250d`).
- **`agent-approved`**: board status wasn't updated — move to "Ready" (`3aaf8e5e`).

**Every issue must end triage in one of these columns: Ideation, Awaiting Decision, Blocked, Ready, or Done.** "Needs Triage" is a transient processing state, not a destination. If anything is still in "Needs Triage" at the end of a triage pass, triage is not complete.

## Step 3: Unblocking Check

During each triage pass, also check for `status:blocked` issues whose dependencies may have been resolved. Before removing `status:blocked` from an issue:

1. **Read the full issue body AND all comments** — dependencies are often added in comments by lucas42 after the initial filing. The issue body may be incomplete.
2. Identify every issue referenced as a dependency or prerequisite across both the body and comments.
3. Check that **every** dependency is closed — not just the one that triggered the check.
4. If the issue body is missing dependencies that were added in comments, **update the issue body** to include them before changing any labels. The body should be the canonical list of dependencies.
5. Only remove `status:blocked` when every dependency has been completed.
6. **Closing a dependency issue is not the same as the real-world precondition being met.** Before unblocking, verify that the underlying condition the dependency was tracking actually holds — not just that the tracking issue is closed. For example, closing "deploy secondary DNS server" does not mean the server exists. If the dependency was for physical infrastructure, a deployed service, or a third-party action (e.g. registrar update), confirm the thing actually exists before unblocking dependent work.

**Special case — false positive audit findings:** When unblocking an `audit-finding` issue whose blocker was a fix to the convention checker itself, close the issue as completed instead of just removing `status:blocked`.

## Step 4: Summary for the User

Once triage is done, compile a prioritised list of issues that need the user's attention. This means any open issue with `owner:lucas42` — these are issues where only the repo owner can unblock progress (e.g. product direction, priority calls, decisions between options).

To find them:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager \
  "search/issues?q=label:owner:lucas42+org:lucas42+is:issue+is:open+sort:created-asc&per_page=50"
```

Present the list grouped and ordered by priority, consulting `~/sandboxes/lucos/docs/priorities.md` for the priority framework:

1. **Priority: high** — issues first, oldest first within the group
2. **Priority: medium** — next
3. **Priority: low** — last
4. **Unprioritised** — at the end (no `priority:*` label)

For each issue, show:
- The full clickable GitHub URL (e.g. `https://github.com/lucas42/lucos_photos/issues/5`)
- The issue title
- A one-line summary of what decision or input is needed (based on the status label and recent comments)

If there are no `owner:lucas42` issues, say so — that means there is nothing blocking on the user right now.

**Before reporting on any issue that was actively discussed during the current session**, re-fetch its comments and check reactions to detect new activity.
