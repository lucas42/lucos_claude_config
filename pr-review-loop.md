# PR Review Loop

This document describes the standard review loop that the dispatcher follows whenever a persona creates a pull request. It applies in all contexts -- the `/next` skill, ad-hoc implementation tasks, ops check fixes, or any other workflow where an agent opens a PR.

## Inputs

Before starting this loop, the dispatcher must know:

1. **PR URL** -- the full GitHub PR URL (e.g. `https://github.com/lucas42/lucos_photos/pull/5`)
2. **Implementation teammate** -- the teammate that created the PR (e.g. `developer`, `system-administrator`). This is needed to route review feedback back to the right teammate.

## The loop

Track the **iteration count** starting at 1.

### Step 1: Request code review

Send a message to the `code-reviewer` teammate asking it to review the PR:

> "review PR {pr_url}"

Wait for the teammate to respond with the result.

### Step 2: Check the review outcome

If the code reviewer **approved** the PR, the loop is done -- report success to the user and stop.

If the code reviewer's output contains `SPECIALIST_REVIEW_REQUESTED: <persona>`, go to step 4.

If the code reviewer **requested changes** and the iteration count is **less than 5**, continue to step 3.

If the code reviewer **requested changes** and this is iteration **5**, stop the loop and tell the user:

> The PR at {pr_url} has gone through 5 review iterations without approval. This likely indicates a mismatch in expectations that needs human judgement -- please take a look.

### Step 3: Send the PR back to the implementation teammate

Send a message to the **implementation teammate** (from the inputs above) asking it to address the review feedback:

> "address the code review feedback on PR {pr_url}"

Wait for the teammate to respond, increment the iteration count, and go back to step 1.

### Step 4: Specialist review

The code reviewer has requested input from a specialist (either `lucos-security` or `lucos-site-reliability`). Extract the persona name from the `SPECIALIST_REVIEW_REQUESTED: <persona>` line and derive the teammate name by stripping the `lucos-` prefix (e.g. `lucos-security` becomes teammate `security`).

Send a message to that specialist teammate asking it to review the PR:

> "review PR {pr_url} -- the code reviewer has requested your input, see their comment on the PR for context"

Wait for the teammate to respond. The specialist may post comments on the PR, request changes, or indicate the PR is fine from their perspective.

After the specialist responds, go back to step 1 to request another code review. The code reviewer will see the specialist's feedback on the PR and factor it into its final verdict. This does **not** increment the iteration count -- the specialist review is a side-trip, not a code-change iteration.
