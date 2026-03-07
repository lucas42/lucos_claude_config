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

## Step 2: Dispatch the correct persona

Extract the persona name from the owner label (strip the `owner:` prefix) and launch that persona via the Task tool. Pass the **specific issue URL** so the persona knows exactly what to work on. For example:

> "implement issue https://github.com/lucas42/lucos_photos/issues/42"

Wait for the persona to complete.

**Why the dispatcher picks the issue:** All implementation agents run in the same sandbox, so dispatching multiple personas to different repos simultaneously would risk filesystem conflicts. The dispatcher controls sequencing by picking one issue at a time.

## Step 3: Check for a new PR

After the agent finishes, check its output to determine whether a pull request was created. Look for PR URLs (e.g. `https://github.com/lucas42/.../pull/N`) or explicit statements that a PR was opened.

## Step 4: Review loop (if a PR was created)

If no PR was created (e.g. the agent hit a blocker before opening a PR), skip this step.

If a PR was created, follow the **PR Review Loop** defined in [`~/.claude/pr-review-loop.md`](../../pr-review-loop.md). The inputs are:

- **PR URL**: the URL from the agent's output
- **Implementation persona**: the persona dispatched in Step 2

## Step 5: Post-approval handling

After the PR review loop completes with approval:

1. **Determine the repository name** from the PR URL (e.g. `lucos_photos` from `https://github.com/lucas42/lucos_photos/pull/5`).

2. **Check `~/sandboxes/lucos_configy/config/systems.yaml`** for the entry matching that repository name. Look for the field `unsupervisedAgentCode`.

3. **If `unsupervisedAgentCode` is `true`:**
   - Wait for the PR to be automatically merged and the corresponding issue to be closed. Poll periodically (e.g. every 30 seconds) for up to 5 minutes.
   - If after 5 minutes the PR has not been merged or the issue has not been closed, flag this as a problem to the user and stop.
   - Once the issue is closed, launch `lucos-issue-manager` via the Task tool and ask it to update any issues that were blocked by the now-closed issue (i.e. remove the blocking relationship / unblock dependent issues).

4. **If `unsupervisedAgentCode` is missing or `false`:**
   - Tell the user they need to review and merge the pull request themselves. Provide the full PR URL so they can easily navigate to it.
