# PR Review Loop

This document describes the standard review loop that the dispatcher follows whenever a persona creates a pull request. It applies in all contexts -- the `/next` skill, ad-hoc implementation tasks, ops check fixes, or any other workflow where an agent opens a PR.

## Inputs

Before starting this loop, the dispatcher must know:

1. **PR URL** -- the full GitHub PR URL (e.g. `https://github.com/lucas42/lucos_photos/pull/5`)
2. **Implementation persona** -- the persona that created the PR (e.g. `lucos-developer`, `lucos-system-administrator`). This is needed to route review feedback back to the right agent.

## The loop

Track the **iteration count** starting at 1.

### Step 1: Launch code review

Launch `lucos-code-reviewer` with a prompt to review the PR:

> "review PR {pr_url}"

Wait for it to complete.

### Step 2: Check the review outcome

If the code reviewer **approved** the PR, the loop is done -- report success to the user and stop.

If the code reviewer's output contains `SPECIALIST_REVIEW_REQUESTED: <persona>`, go to step 4.

If the code reviewer **requested changes** and the iteration count is **less than 5**, continue to step 3.

If the code reviewer **requested changes** and this is iteration **5**, stop the loop and tell the user:

> The PR at {pr_url} has gone through 5 review iterations without approval. This likely indicates a mismatch in expectations that needs human judgement -- please take a look.

### Step 3: Send the PR back to the implementation persona

Launch the **implementation persona** (from the inputs above) with a prompt to address the review feedback:

> "address the code review feedback on PR {pr_url}"

Wait for it to complete, increment the iteration count, and go back to step 1.

### Step 4: Specialist review

The code reviewer has requested input from a specialist persona (either `lucos-security` or `lucos-site-reliability`). Extract the persona name from the `SPECIALIST_REVIEW_REQUESTED: <persona>` line.

Launch that specialist persona with a prompt to review the PR:

> "review PR {pr_url} -- the code reviewer has requested your input, see their comment on the PR for context"

Wait for it to complete. The specialist may post comments on the PR, request changes, or indicate the PR is fine from their perspective.

After the specialist finishes, go back to step 1 to re-launch the code reviewer. The code reviewer will see the specialist's feedback on the PR and factor it into its final verdict. This does **not** increment the iteration count -- the specialist review is a side-trip, not a code-change iteration.
