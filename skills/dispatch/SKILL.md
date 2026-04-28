---
name: dispatch
description: Guardrailed dispatch of a single GitHub issue to the correct implementation teammate
disable-model-invocation: false
---

Follow this process. The issue URL is provided as the first argument (e.g. `/dispatch https://github.com/lucas42/lucos_photos/issues/42`). An optional `owner:{name}` argument may follow (e.g. `/dispatch https://github.com/lucas42/lucos_photos/issues/42 owner:lucos-developer`). If provided, use that owner for dispatch in Step 5 without querying labels or the project board. Do not ask for clarification -- immediately begin.

## Step 1: Parse the issue URL and fetch issue data

Extract the repository (`{owner}/{repo}`) and issue number from the URL. Fetch the issue:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/{owner}/{repo}/issues/{number}
```

Read the full issue body and note the current labels.

## Step 2: Pre-dispatch dependency check

Look for references to other issues described as dependencies, prerequisites, or blockers -- including cross-repo references (e.g. `lucas42/other_repo#N`). Check task-list items in a `## Dependencies` section, prose mentions like "depends on", "blocked by", "requires", or any other phrasing that indicates a prerequisite.

For every issue referenced as a dependency, check whether it is closed:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues/{number} --jq '.state'
```

If **any** dependency is still open, **do not dispatch the issue.** Instead, warn the user:

> Issue {url} has unresolved dependencies: {list of open dependency URLs}. It should not be implemented yet.

Then stop. Do not proceed further.

If all dependencies are closed (or no dependencies are mentioned), continue.

## Step 3: Check for existing PRs

Check whether a pull request already exists that would close this issue:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues/{number}/timeline --jq '[.[] | select(.event == "cross-referenced" and .source.issue.pull_request != null) | {pr_number: .source.issue.number, pr_title: .source.issue.title, pr_state: .source.issue.state, pr_url: .source.issue.html_url}]'
```

If a PR exists that references the issue and is still **open**, the work has likely already been done -- the PR just hasn't been merged yet. In that case:

1. **Determine the repository name** from the issue URL.
2. **Check whether the repository has unsupervised agent code enabled** by running `~/sandboxes/lucos_agent/check-unsupervised <repo-name>`.
3. **If unsupervised (exit code 0):** the PR should auto-merge on its own. Tell the user the work is already done and the PR is awaiting auto-merge, then stop.
4. **If not unsupervised (exit code 1) or error (exit code 2):** tell the user they need to review and approve the existing PR — once approved, it will auto-merge. Provide the PR URL. Then stop -- do not dispatch a teammate.

If no open PR exists for the issue, continue.

## Step 4: Check for estate-wide convention changes

If the issue is on the `lucos_repos` repository and involves **creating or modifying a convention** (i.e. the work will change which repos pass or fail an audit convention), this requires the estate-rollout workflow instead of a normal implementation dispatch. Convention changes need to be verified against all repos via the dry-run diff before merging, and affected repos may need migrating.

Read the issue body. If it describes adding a new convention, modifying an existing convention's check logic, or changing what a convention considers passing/failing, **use the `/estate-rollout` skill** instead of continuing. Pass the issue context to the skill so it knows what change to make. Then stop -- the estate-rollout skill handles the rest.

More broadly, any issue whose resolution requires the same change to be applied across many repos (enabling a GitHub setting, updating a workflow file, etc.) is an estate rollout, regardless of which repo the issue lives on. Route these to `/estate-rollout`.

If the issue is not an estate rollout (e.g. it's a bug fix, API change, dashboard change, or infrastructure work), continue.

## Step 5: Dispatch to the correct teammate

If an `owner:{name}` argument was provided (see top of this file), use that directly — skip the lookup below.

Otherwise, look up the owner from the **project board** (the source of truth for issue ownership). Query the issue's project board item to find the Owner field. If the issue is not on the project board, fall back to checking issue labels for `owner:*` labels:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues/{number} --jq '[.labels[].name | select(startswith("owner:"))] | first'
```

Extract the teammate name by stripping the `owner:` prefix (e.g. `owner:lucos-developer` becomes teammate `lucos-developer`). Send a message to that teammate using SendMessage, passing the **specific issue URL** so they know exactly what to work on. For example:

> "implement issue https://github.com/lucas42/lucos_photos/issues/42"

**CRITICAL: use SendMessage only — do NOT spawn a new agent with the Agent tool.** Teammates persist across sessions. Using the Agent tool instead of SendMessage creates a duplicate agent running in parallel with the existing one, causing duplicated work and duplicate messages. If SendMessage fails because the teammate is not running, spawn them once using the Agent tool, then use SendMessage for all subsequent communication.

Wait for the teammate to respond with the result. The teammate is responsible for driving the PR review loop (see [`~/.claude/pr-review-loop.md`](../../pr-review-loop.md)) before reporting back.

## Step 6: Post-completion handling

After the teammate reports back, check whether a PR was created and approved. Look for PR URLs (e.g. `https://github.com/lucas42/.../pull/N`) and approval confirmation in the teammate's response. If no PR was created (e.g. the teammate hit a blocker), report this to the user and stop.

If a PR was created and approved:

1. **Determine the repository name** from the PR URL (e.g. `lucos_photos` from `https://github.com/lucas42/lucos_photos/pull/5`).

2. **Check whether the repository has unsupervised agent code enabled** by running:
   ```bash
   ~/sandboxes/lucos_agent/check-unsupervised <system-name>
   ```
   where `<system-name>` is the repository name (e.g. `lucos_photos`). Exit code 0 means yes (unsupervised), exit code 1 means no, exit code 2 means error.

3. **Check for issues to unblock (always — regardless of supervised/unsupervised).** Search the **entire org** for open issues with `status:blocked` that reference the closing issue number in their body **or comments**. Dependencies can be cross-repo (e.g. an issue on `lucos_media_metadata_api` blocked by an issue on `lucos_media_metadata_manager`), and a blocking dependency is often added in a comment after the issue was originally raised — so searching only `in:body` will miss real dependents.
   ```bash
   ~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager "search/issues?q=org:lucas42+is:open+label:status:blocked+{issue_number}+in:body,comments"
   ```
   For each result, read the full issue body **and all comments** to confirm it actually references the closing issue as a dependency (not just a casual mention). For confirmed dependents, verify that **all** their dependencies are resolved before removing `status:blocked` — not just the one that was just closed.

   **When unblocking an issue, you MUST do both of the following — removing the label without updating the board is incomplete:**
   1. Remove the `status:blocked` label from the issue.
   2. Update the project board Status field from Blocked → Ready (option ID `3aaf8e5e`).

   Read `~/.claude/references/triage-reference-data.md` for the full board API patterns.

4. **If unsupervised (exit code 0):**
   - **If there are dependent issues to unblock (from step 3):** wait for the PR to be automatically merged and the corresponding issue to be closed. Poll periodically (e.g. every 30 seconds) for up to 10 minutes. If after 10 minutes the PR has not been merged or the issue has not been closed, flag this as a problem to the user and stop. Once the issue is closed, perform the unblocking from step 3.
   - **If there are NO dependent issues:** verify that CI checks have started on the PR before moving on. Check the PR's status checks:
     ```bash
     ~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/commits/{head_sha}/check-runs --jq '{total_count: .total_count, checks: [.check_runs[] | {name: .name, status: .status, conclusion: .conclusion}]}'
     ```
     Get the head SHA from the PR details (`head.sha`).
     - If `total_count` is 0 (no checks created at all) or any check has `conclusion: "failure"`: send the PR back to the **developer who created it** for investigation. The developer has the most context on the code and likely failure modes -- do not investigate yourself or escalate to SRE. Only if the developer identifies the failure as a pipeline/infrastructure problem (not a code/test issue) should SRE be looped in.
     - Otherwise, CI is running or has passed. Now check whether the PR branch is behind main, which prevents auto-merge when strict branch protection is enabled:
       ```bash
       ~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/pulls/{pr_number} --jq '{mergeable_state: .mergeable_state, mergeable: .mergeable}'
       ```
       If `mergeable_state` is `"behind"`, the branch needs rebasing before auto-merge can fire. Send the PR back to the **developer who created it** and ask them to rebase onto main and force-push. Wait for the developer to confirm the rebase is done before declaring the task complete.
     - If CI is green and the branch is up to date, the PR will auto-merge on its own and there is nothing else to do.

5. **If not unsupervised (exit code 1) or error (exit code 2):**
   - Tell the user the PR needs their review and approval. Once approved, it will auto-merge. Provide the full PR URL so they can easily navigate to it.
   - If there are dependent issues to unblock (from step 3), mention them — the user should know that merging this PR will unblock further work.
