# PR Review Loop

This document describes the standard review loop that an implementation teammate follows after creating a pull request. It applies in all contexts -- the `/next` skill, ad-hoc implementation tasks, ops check fixes, or any other workflow where a teammate opens a PR.

Every teammate that creates a PR is responsible for driving the review loop to completion before reporting back to whoever asked it to do the work.

**Coordinator override rule:** If a coordinator instruction reverses a step you are in the middle of (e.g. "stop pushing", "leave the PR as-is", "don't dispatch the reviewer"), drop any in-flight work in that step immediately — even if a commit is half-staged or a message is about to be sent. Do not complete the step and then apply the instruction to the next one. Message queues are async, so an override that arrives mid-step is still binding for everything you haven't yet executed.

## The loop

After creating a PR, track the **iteration count** starting at 1.

### Step 1: Request code review

Send a message to the `lucos-code-reviewer` teammate asking it to review the PR. **Use `SendMessage` with `to: "lucos-code-reviewer"`** — the reviewer is already a teammate on the running team. **Do NOT use the `Agent` tool to spawn a fresh `lucos-code-reviewer` subagent**: that bypasses the team flow, gives the reviewer no shared inbox or context, and produces a tool-call return rather than a teammate message visible to the rest of the team.

The message body is:

> "review PR {pr_url}"

Wait for the lucos-code-reviewer to respond.

### Step 2: Check the review outcome

**Review precedence rule:** A PR is approved only when *all* reviewers who have submitted reviews are in APPROVED state. A CHANGES_REQUESTED from any reviewer — including lucas42 — is binding until *that same reviewer* submits a new APPROVED review. An APPROVED from a *different* reviewer does not dismiss someone else's CHANGES_REQUESTED. Before declaring a PR approved, query the GitHub API and verify no reviewer has a current CHANGES_REQUESTED state.

If the code reviewer **approved** the PR:

- **Check whether lucas42 has a pending CHANGES_REQUESTED** (query the GitHub API). If so, re-request lucas42's review now — the code reviewer's approval is the gate; only after they approve do you put the PR back in lucas42's queue. Use the developer app (not the coordinator, which lacks `pull_requests: write`):
  ```bash
  ~/sandboxes/lucos_agent/gh-as-agent --app lucos-developer \
      repos/lucas42/{repo}/pulls/{number}/requested_reviewers \
      --method POST \
      --field 'reviewers[]=lucas42'
  ```
  Then wait for lucas42's approval before reporting back.
- If lucas42 has no pending CHANGES_REQUESTED: **do not merge.** Never call the merge API — merging is handled by auto-merge (GitHub) or the user. **Before reporting back, re-fetch `pulls/{n}` and check `merged` and `state` — the PR may have already merged between your analysis and the send.** Report the current state accurately: if it's merged, say so; if it's still open, report it as approved and awaiting merge. Your job is done once the PR is approved or merged.

Do not determine or report whether the repo is supervised or unsupervised — the coordinator handles that. Do not wait for CI, do not poll CI status.

If the code reviewer's response contains `SPECIALIST_REVIEW_REQUESTED: <persona>`, go to step 4.

If the code reviewer **requested changes** and the iteration count is **less than 5**, continue to step 3.

If the code reviewer **requested changes** and this is iteration **5**, stop the loop and report back:

> The PR at {pr_url} has gone through 5 review iterations without approval. This likely indicates a mismatch in expectations that needs human judgement.

### Step 3: Address the review feedback

Address the code review feedback yourself -- you are the implementation teammate who created the PR.

**Before pushing:** if the changes alter the PR's scope or shape — switching designs, making a parameter required when it was optional, renaming a function, deleting a code path the description mentions, or any other substantive rework — re-read the PR body and verify it still accurately describes the code. Check "What changed", behaviour claims, and the test plan section. Update the body in the same push (or immediately after via a PATCH to the PR). A description that contradicts the code is a review blocker that wastes review cycles.

Push the fixes, increment the iteration count, then **go back to step 1** (dispatch `lucos-code-reviewer` again). Do NOT re-request lucas42 at this point — lucas42 only goes back in the queue after the code reviewer approves the new commit. The correct sequence is always: fix → code-reviewer → (code-reviewer approves) → re-request lucas42.

**Important: this also applies when you push changes to an already-approved PR** (e.g. a rework requested by the coordinator). Pushing a new commit to a PR dismisses any prior approval and resets `review_decision` to null. After every push — including reworks — you must go back to step 1 before reporting back to the coordinator. Check that `review_decision` is not null and `mergeable_state` is not `blocked` on the new head commit before declaring the loop complete. Reporting "done" on a PR with `review_decision: null` is a failure to complete the loop.

### Step 3b: Required-check failures that need a non-code action

Some required checks fail in ways that no further code change can fix — most commonly a CodeQL / GHAS alert that an agent has assessed as a false positive but that hasn't auto-cleared after the fix lands. The code-reviewer cannot approve while a required check is failing, so the loop will stall here unless you act.

Recognise the scenario: a required check (e.g. `CodeQL`) has `conclusion: "failure"` on the PR head, but the assessing specialist (e.g. `lucos-security`) has already commented on the PR that the underlying finding is safe / a false positive / mitigated.

In that case, you (the implementation teammate driving the loop) are responsible for coordinating the non-code resolution. SendMessage the assessing specialist, ask them to dismiss the alert as a false positive (`lucos-security` has `security_events: write` and can `PATCH` the alert), and wait for confirmation. Do not assume the dismissal will happen on its own.

If the specialist replies that they can't dismiss (e.g. permission issue, audit-trail preference), escalate to the coordinator with the PR URL and the specific blocker — don't loop indefinitely.

Once the check clears, go back to step 1 to re-request `lucos-code-reviewer`. This does not increment the iteration count — it's a non-code resolution, not a code-change iteration.

### Step 4: Specialist review

The code reviewer has requested input from a specialist (either `lucos-security` or `lucos-site-reliability`). Extract the teammate name from the `SPECIALIST_REVIEW_REQUESTED: <persona>` line — the persona name is also the teammate name (e.g. `lucos-security`).

Send a message to that specialist teammate via `SendMessage` (same rule as Step 1 — they are already on the team, do NOT spawn them via the `Agent` tool):

> "review PR {pr_url} -- the code reviewer has requested your input, see their comment on the PR for context"

Wait for the specialist to respond. The specialist may post comments on the PR, request changes, or indicate the PR is fine from their perspective.

After the specialist responds, go back to step 1 to request another code review. The code reviewer will see the specialist's feedback on the PR and factor it into its final verdict. This does **not** increment the iteration count -- the specialist review is a side-trip, not a code-change iteration.