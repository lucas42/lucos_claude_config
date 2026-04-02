---
name: next
description: Implement the next issue
disable-model-invocation: true
---

Follow this process. Do not ask for clarification — immediately begin Step 1.

## Ad-hoc dispatch

If the user gives a specific issue URL to implement (rather than asking for the next issue from the queue), skip Step 1 and go straight to Step 1a with that issue. In parallel with dispatching the developer in Step 2, update the issue yourself: set it to `priority:high`, ensure it's on the project board, and move it to the top of the Ready column. Read `~/.claude/references/triage-reference-data.md` for field IDs and API patterns. If the user is explicitly asking for an issue to be picked up, it's clearly high priority to them.

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

## Step 1a: Pre-dispatch dependency check

Before dispatching the issue, read the full issue body. Look for references to other issues described as dependencies, prerequisites, or blockers — including cross-repo references (e.g. `lucas42/other_repo#N`). Check task-list items in a `## Dependencies` section, prose mentions like "depends on", "blocked by", "requires", or any other phrasing that indicates a prerequisite.

For every issue referenced as a dependency, check whether it is closed:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues/{number} --jq '.state'
```

If **any** dependency is still open, **do not dispatch the issue.** Instead, warn the user:

> Issue {url} has unresolved dependencies: {list of open dependency URLs}. It should not be implemented yet.

Then stop. Do not proceed to Step 2.

If all dependencies are closed (or no dependencies are mentioned), continue to Step 1b.

## Step 1b: Check for existing PRs

Before dispatching the issue, check whether a pull request already exists that would close it:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues/{number}/timeline --jq '[.[] | select(.event == "cross-referenced" and .source.issue.pull_request != null) | {pr_number: .source.issue.number, pr_title: .source.issue.title, pr_state: .source.issue.state, pr_url: .source.issue.html_url}]'
```

If a PR exists that references the issue and is still **open**, the work has likely already been done — the PR just hasn't been merged yet. In that case:

1. **Determine the repository name** from the issue URL.
2. **Check whether the repository has unsupervised agent code enabled** by running `~/sandboxes/lucos_agent/check-unsupervised <repo-name>`.
3. **If unsupervised (exit code 0):** the PR should auto-merge on its own. Tell the user the work is already done and the PR is awaiting auto-merge, then stop.
4. **If not unsupervised (exit code 1) or error (exit code 2):** tell the user they need to merge the existing PR before this issue can be closed. Provide the PR URL. Then stop — do not dispatch a teammate.

If no open PR exists for the issue, continue to Step 1c.

## Step 1c: Check for estate-wide convention changes

If the issue is on the `lucos_repos` repository and involves **creating or modifying a convention** (i.e. the work will change which repos pass or fail an audit convention), this requires the estate-rollout workflow instead of a normal implementation dispatch. Convention changes need to be verified against all repos via the dry-run diff before merging, and affected repos may need migrating.

Read the issue body. If it describes adding a new convention, modifying an existing convention's check logic, or changing what a convention considers passing/failing, **use the `/estate-rollout` skill** instead of continuing to Step 2. Pass the issue context to the skill so it knows what change to make.

If the issue is not a convention change (e.g. it's a bug fix, API change, dashboard change, or infrastructure work — even if it's on lucos_repos), continue to Step 2 as normal.

## Step 2: Dispatch the correct teammate

Extract the teammate name from the owner label by stripping the `owner:` prefix (e.g. `owner:lucos-developer` becomes teammate `lucos-developer`). Send a message to that teammate using SendMessage, passing the **specific issue URL** so they know exactly what to work on. For example:

> "implement issue https://github.com/lucas42/lucos_photos/issues/42"

Wait for the teammate to respond with the result. The teammate is responsible for driving the PR review loop (see [`~/.claude/pr-review-loop.md`](../../pr-review-loop.md)) before reporting back.

## Step 3: Post-completion handling

After the teammate reports back, check whether a PR was created and approved. Look for PR URLs (e.g. `https://github.com/lucas42/.../pull/N`) and approval confirmation in the teammate's response. If no PR was created (e.g. the teammate hit a blocker), report this to the user and stop.

If a PR was created and approved:

1. **Determine the repository name** from the PR URL (e.g. `lucos_photos` from `https://github.com/lucas42/lucos_photos/pull/5`).

2. **Check whether the repository has unsupervised agent code enabled** by running:
   ```bash
   ~/sandboxes/lucos_agent/check-unsupervised <system-name>
   ```
   where `<system-name>` is the repository name (e.g. `lucos_photos`). Exit code 0 means yes (unsupervised), exit code 1 means no, exit code 2 means error.

3. **If unsupervised (exit code 0):**
   - First, check whether any open issues are blocked by the issue this PR closes. Search in the **issue's repo** (from the original issue URL dispatched in Step 2), not the PR's repo — these may differ when a PR in one repo closes an issue in another. Look for open issues with `status:blocked` that reference the closing issue number in their body or comments.
   - **If there ARE dependent issues to unblock:**
     - Wait for the PR to be automatically merged and the corresponding issue to be closed. Poll periodically (e.g. every 30 seconds) for up to 10 minutes.
     - If after 10 minutes the PR has not been merged or the issue has not been closed, flag this as a problem to the user and stop.
     - Once the issue is closed, check the blocked issues yourself. Read `~/.claude/references/triage-reference-data.md` for API patterns. For each blocked issue, verify that **all** dependencies are resolved before removing `status:blocked` — not just the one that was just closed.
   - **If there are NO dependent issues:** verify that CI checks have started on the PR before moving on. Check the PR's status checks:
     ```bash
     ~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/commits/{head_sha}/check-runs --jq '{total_count: .total_count, checks: [.check_runs[] | {name: .name, status: .status, conclusion: .conclusion}]}'
     ```
     Get the head SHA from the PR details (`head.sha`).
     - If `total_count` is 0 (no checks created at all) or any check has `conclusion: "failure"`: send the PR back to the **developer who created it** for investigation. The developer has the most context on the code and likely failure modes — do not investigate yourself or escalate to SRE. Only if the developer identifies the failure as a pipeline/infrastructure problem (not a code/test issue) should SRE be looped in.
     - Otherwise, CI is running or has passed. Now check whether the PR branch is behind main, which prevents auto-merge when strict branch protection is enabled:
       ```bash
       ~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/pulls/{pr_number} --jq '{mergeable_state: .mergeable_state, mergeable: .mergeable}'
       ```
       If `mergeable_state` is `"behind"`, the branch needs rebasing before auto-merge can fire. Send the PR back to the **developer who created it** and ask them to rebase onto main and force-push. Wait for the developer to confirm the rebase is done before declaring the task complete.
     - If CI is green and the branch is up to date, the PR will auto-merge on its own and there is nothing else to do.

4. **If not unsupervised (exit code 1) or error (exit code 2):**
   - Tell the user they need to review and merge the pull request themselves. Provide the full PR URL so they can easily navigate to it.
