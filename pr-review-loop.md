# PR Review Loop

This document describes the standard review loop that an implementation teammate follows after creating a pull request. It applies in all contexts -- the `/next` skill, ad-hoc implementation tasks, ops check fixes, or any other workflow where a teammate opens a PR.

Every teammate that creates a PR is responsible for driving the review loop to completion before reporting back to whoever asked it to do the work.

## The loop

After creating a PR, track the **iteration count** starting at 1.

### Step 1: Request code review

Send a message to the `lucos-code-reviewer` teammate asking it to review the PR:

> "review PR {pr_url}"

Wait for the lucos-code-reviewer to respond.

### Step 2: Check the review outcome

If the code reviewer **approved** the PR, check whether you are allowed to merge it (see "Merge permissions" below). Then report the outcome (approval + PR URL + whether it was merged or is awaiting human merge) back to whoever asked you to do the work.

If the code reviewer's response contains `SPECIALIST_REVIEW_REQUESTED: <persona>`, go to step 4.

If the code reviewer **requested changes** and the iteration count is **less than 5**, continue to step 3.

If the code reviewer **requested changes** and this is iteration **5**, stop the loop and report back:

> The PR at {pr_url} has gone through 5 review iterations without approval. This likely indicates a mismatch in expectations that needs human judgement.

### Step 3: Address the review feedback

Address the code review feedback yourself -- you are the implementation teammate who created the PR. Push the fixes, increment the iteration count, and go back to step 1.

### Step 4: Specialist review

The code reviewer has requested input from a specialist (either `lucos-security` or `lucos-site-reliability`). Extract the teammate name from the `SPECIALIST_REVIEW_REQUESTED: <persona>` line — the persona name is also the teammate name (e.g. `lucos-security`).

Send a message to that specialist teammate asking it to review the PR:

> "review PR {pr_url} -- the code reviewer has requested your input, see their comment on the PR for context"

Wait for the specialist to respond. The specialist may post comments on the PR, request changes, or indicate the PR is fine from their perspective.

After the specialist responds, go back to step 1 to request another code review. The code reviewer will see the specialist's feedback on the PR and factor it into its final verdict. This does **not** increment the iteration count -- the specialist review is a side-trip, not a code-change iteration.

## Merge permissions

After a PR is approved, **do not automatically merge it.** Whether an agent is allowed to merge depends on the repository's configuration in lucos_configy.

**Check `unsupervisedAgentCode`:** Look up the repository in lucos_configy's configuration. If the repo has `unsupervisedAgentCode: true`, the agent may merge the PR. If the repo does not have this flag (or it is `false`), the agent must **not** merge -- instead:

1. Post a comment on the PR indicating it has been approved and is ready for a human to merge.
2. Report back to whoever assigned the work that the PR is approved but awaiting human merge.

This distinction exists because some repositories require human oversight before code reaches production. Merging a PR in a repo without `unsupervisedAgentCode: true` bypasses that oversight.
