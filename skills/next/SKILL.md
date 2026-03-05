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

If a PR was created, enter a review loop. Track the **iteration count** starting at 1.

**4a. Launch code review.**

Launch `lucos-code-reviewer` with a prompt to review the PR:

> "review PR https://github.com/lucas42/{repo}/pull/{number}"

Wait for it to complete.

**4b. Check the review outcome.**

If the code reviewer **approved** the PR, the loop is done — report success to the user and stop.

If the code reviewer's output contains `SPECIALIST_REVIEW_REQUESTED: <persona>`, go to step 4d.

If the code reviewer **requested changes** and the iteration count is **less than 5**, continue to step 4c.

If the code reviewer **requested changes** and this is iteration **5**, stop the loop and tell the user:

> The PR at {url} has gone through 5 review iterations without approval. This likely indicates a mismatch in expectations that needs human judgement — please take a look.

**4c. Send the PR back to the implementation persona.**

Launch the **same persona** from Step 2 (the one that opened the PR) with a prompt to address the review feedback. For example:

> "address the code review feedback on PR https://github.com/lucas42/{repo}/pull/{number}"

Wait for it to complete, increment the iteration count, and go back to step 4a.

**4d. Specialist review.**

The code reviewer has requested input from a specialist persona (either `lucos-security` or `lucos-site-reliability`). Extract the persona name from the `SPECIALIST_REVIEW_REQUESTED: <persona>` line.

Launch that specialist persona with a prompt to review the PR:

> "review PR https://github.com/lucas42/{repo}/pull/{number} — the code reviewer has requested your input, see their comment on the PR for context"

Wait for it to complete. The specialist may post comments on the PR, request changes, or indicate the PR is fine from their perspective.

After the specialist finishes, go back to step 4a to re-launch the code reviewer. The code reviewer will see the specialist's feedback on the PR and factor it into its final verdict. This does **not** increment the iteration count — the specialist review is a side-trip, not a code-change iteration.
