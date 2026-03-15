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

If the code reviewer **approved** the PR: **do not merge.** Never call the merge API on any PR — merging is handled by auto-merge (GitHub) or the user, not agents.

Before reporting back, check the repo's `unsupervisedAgentCode` custom property:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app <your-app> repos/lucas42/<repo>/properties/values --jq '.'
```

- If `unsupervisedAgentCode` is `YES` (or the property is not set): report back with the PR URL and approval. Auto-merge will handle the rest.
- If `unsupervisedAgentCode` is `NO`: report back with the PR URL and explicitly note that this repo requires human review and merge. The PR should be left open for the user.

Either way, do not wait for CI, do not poll CI status. Your job is done after reporting back.

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