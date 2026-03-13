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

## Step 1a: Pre-dispatch dependency check

Before dispatching the issue, read the full issue body. Look for references to other issues described as dependencies, prerequisites, or blockers — including cross-repo references (e.g. `lucas42/other_repo#N`). Check task-list items in a `## Dependencies` section, prose mentions like "depends on", "blocked by", "requires", or any other phrasing that indicates a prerequisite.

For every issue referenced as a dependency, check whether it is closed:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues/{number} --jq '.state'
```

If **any** dependency is still open, **do not dispatch the issue.** Instead, warn the user:

> Issue {url} has unresolved dependencies: {list of open dependency URLs}. It should not be implemented yet.

Then stop. Do not proceed to Step 2.

If all dependencies are closed (or no dependencies are mentioned), continue to Step 2.

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
   - First, check whether any open issues are blocked by the issue this PR closes. Search for open issues that reference the closing issue as a blocker (e.g. issues with `status:blocked` that mention the issue number in their body or comments).
   - **If there ARE dependent issues to unblock:**
     - Wait for the PR to be automatically merged and the corresponding issue to be closed. Poll periodically (e.g. every 30 seconds) for up to 10 minutes.
     - If after 10 minutes the PR has not been merged or the issue has not been closed, flag this as a problem to the user and stop.
     - Once the issue is closed, send a message to the `lucos-issue-manager` teammate asking it to check issues that were blocked by the now-closed issue. Remind it to verify that **all** dependencies of each blocked issue are resolved before removing `status:blocked` — not just the one that was just closed.
   - **If there are NO dependent issues:** skip the waiting entirely — the PR will merge on its own via auto-merge and there is nothing else to do.

4. **If not unsupervised (exit code 1) or error (exit code 2):**
   - Tell the user they need to review and merge the pull request themselves. Provide the full PR URL so they can easily navigate to it.
