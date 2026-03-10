---
name: next
description: Implement the next issue
disable-model-invocation: true
---

Follow this process. Do not ask for clarification — immediately begin Step 1.

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

## Step 2: Dispatch the correct teammate

Extract the teammate name from the owner label by stripping both the `owner:` and `lucos-` prefixes (e.g. `owner:lucos-developer` becomes teammate `developer`). Send a message to that teammate using SendMessage, passing the **specific issue URL** so they know exactly what to work on. For example:

> "implement issue https://github.com/lucas42/lucos_photos/issues/42"

Wait for the teammate to respond with the result.

## Step 3: Check for a new PR

After the teammate responds, check the output to determine whether a pull request was created. Look for PR URLs (e.g. `https://github.com/lucas42/.../pull/N`) or explicit statements that a PR was opened.

## Step 4: Review loop (if a PR was created)

If no PR was created (e.g. the agent hit a blocker before opening a PR), skip this step.

If a PR was created, follow the **PR Review Loop** defined in [`~/.claude/pr-review-loop.md`](../../pr-review-loop.md). The inputs are:

- **PR URL**: the URL from the agent's output
- **Implementation teammate**: the teammate messaged in Step 2

## Step 5: Post-approval handling

After the PR review loop completes with approval:

1. **Determine the repository name** from the PR URL (e.g. `lucos_photos` from `https://github.com/lucas42/lucos_photos/pull/5`).

2. **Check `~/sandboxes/lucos_configy/config/systems.yaml`** for the entry matching that repository name. Look for the field `unsupervisedAgentCode`.

3. **If `unsupervisedAgentCode` is `true`:**
   - First, check whether any open issues are blocked by the issue this PR closes. Search for open issues that reference the closing issue as a blocker (e.g. issues with `status:blocked` that mention the issue number in their body or comments).
   - **If there ARE dependent issues to unblock:**
     - Wait for the PR to be automatically merged and the corresponding issue to be closed. Poll periodically (e.g. every 30 seconds) for up to 10 minutes.
     - If after 10 minutes the PR has not been merged or the issue has not been closed, flag this as a problem to the user and stop.
     - Once the issue is closed, send a message to the `issue-manager` teammate asking it to update any issues that were blocked by the now-closed issue (i.e. remove the blocking relationship / unblock dependent issues).
   - **If there are NO dependent issues:** skip the waiting entirely — the PR will merge on its own via auto-merge and there is nothing else to do.

4. **If `unsupervisedAgentCode` is missing or `false`:**
   - Tell the user they need to review and merge the pull request themselves. Provide the full PR URL so they can easily navigate to it.
