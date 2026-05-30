---
name: dispatch
description: Guardrailed dispatch of a single GitHub issue to the correct implementation teammate
disable-model-invocation: false
---

Follow this process. The issue URL is provided as the first argument (e.g. `/dispatch https://github.com/lucas42/lucos_photos/issues/42`). An optional `owner:{name}` argument may follow (e.g. `/dispatch https://github.com/lucas42/lucos_photos/issues/42 owner:lucos-developer`). If provided, use that owner for dispatch in Step 5 without querying the project board. Do not ask for clarification -- immediately begin.

## Step 1: Parse the issue URL and fetch issue data

Extract the repository (`{owner}/{repo}`) and issue number from the URL. Fetch the issue:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/{owner}/{repo}/issues/{number}
```

Read the full issue body.

## Step 2: Pre-dispatch dependency check

Look for references to other issues described as dependencies, prerequisites, or blockers — including cross-repo references (e.g. `lucas42/other_repo#N`). Check task-list items in a `## Dependencies` section, prose mentions like "depends on", "blocked by", "requires", or any other phrasing that indicates a prerequisite.

**When interpreting references:** a bare `#N` in this issue's body means issue `N` in **this** repo. A `other_repo#N` or `owner/other_repo#N` reference means issue `N` in that **other** repo. Don't conflate them — `lucos_eolas#254` and `lucos_media_metadata_api#254` are distinct issues even though they share the number.

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
4. **If not unsupervised (exit code 1) or error (exit code 2):** tell the user they need to review and approve the existing PR — once approved, it will auto-merge (the `code-reviewer-auto-merge.yml` workflow is deployed across the lucos estate; lucas42's approval triggers it). Provide the PR URL. Then stop -- do not dispatch a teammate.

If no open PR exists for the issue, continue.

## Step 4: Check for estate-wide convention changes

If the issue is on the `lucos_repos` repository and involves **creating or modifying a convention** (i.e. the work will change which repos pass or fail an audit convention), this requires the estate-rollout workflow instead of a normal implementation dispatch. Convention changes need to be verified against all repos via the dry-run diff before merging, and affected repos may need migrating.

Read the issue body. If it describes adding a new convention, modifying an existing convention's check logic, or changing what a convention considers passing/failing, **use the `/estate-rollout` skill** instead of continuing. Pass the issue context to the skill so it knows what change to make. Then stop -- the estate-rollout skill handles the rest.

More broadly, any issue whose resolution requires the same change to be applied across many repos (enabling a GitHub setting, updating a workflow file, etc.) is an estate rollout, regardless of which repo the issue lives on. Route these to `/estate-rollout`.

If the issue is not an estate rollout (e.g. it's a bug fix, API change, dashboard change, or infrastructure work), continue.

## Step 5: Dispatch to the correct teammate

If an `owner:{name}` argument was provided (see top of this file), use that directly — skip the lookup below.

Otherwise, look up the owner from the **project board** (the source of truth for issue ownership). Query the issue's project board item to find the Owner field value. See `~/.claude/references/triage-reference-data.md` for the board query pattern. If the Owner field is not set, the issue has not been properly triaged — report this to the user and stop.

The Owner field value is the teammate name directly (e.g. `lucos-developer`). Send a message to that teammate using SendMessage, passing the **specific issue URL** so they know exactly what to work on. For example:

> "implement issue https://github.com/lucas42/lucos_photos/issues/42"

**Send ONLY the URL (and the `implement issue` verb) — do NOT restate, summarise, or embellish the ticket's design, decision, or implementation notes in the message.** The ticket is the single authoritative spec, and the implementer reads it in full as their first step. Any design summary you add is (a) redundant and (b) a second, unversioned copy that can drift from or contradict the ticket — including describing a rejected option as the chosen one. If you find yourself typing "the design is…", "summary:", "key points:", "note that…", or pasting decision/option details into the SendMessage body, STOP and delete it. If the ticket is genuinely ambiguous or under-specified, fix the *ticket* before dispatching — don't paper over it in the dispatch message. Relatedly, never parallelise the dispatch SendMessage with the issue-fetch: that is how a design description gets sent before the ticket has even been read.

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

3. **Check for issues to unblock (always — regardless of supervised/unsupervised).** Query the project board for all items with Status = Blocked (option ID `d79b6b67`), paginating until exhausted. For each Blocked item, fetch the issue body **and all comments**. Then pipe the combined text into `~/.claude/skills/dispatch/check-dependent` to determine whether the closing issue is a dependency:

   ```bash
   BODY_AND_COMMENTS="..."   # concatenated body + all comment bodies
   CLOSED_REF="{owner}/{closed_repo}#{N}"   # e.g. "lucas42/lucos_media_metadata_api#254"
   BLOCKED_REPO="{blocked_repo}"             # repo of the candidate blocked issue

   printf '%s' "$BODY_AND_COMMENTS" \
     | ~/.claude/skills/dispatch/check-dependent "$CLOSED_REF" "$BLOCKED_REPO"
   # exit 0 → confirmed dependent; exit 1 → not dependent
   ```

   The script enforces cross-repo-aware matching rules (following GitHub's autolinker):
   - **Backtick code spans are stripped first.** A reference inside backticks (e.g. `` `#254` `` or `` `lucas42/lucos_eolas#254` ``) is rendered as code by GitHub, not a link — it is never treated as a dependency.
   - **Same-repo** (`closed_repo == blocked_repo`): bare `#N` (not preceded by an alphanumeric/underscore/slash character) **or** a github.com URL for the closed issue.
   - **Cross-repo** (`closed_repo != blocked_repo`): only `{owner}/{closed_repo}#N` (fully-qualified) or a github.com URL — the short form `{closed_repo}#N` (no owner prefix) does **not** match (GitHub does not autolink it); bare `#N` alone does **not** match either.

   This prevents false positives when a blocked ticket in repo A references `repo_C#N` and the just-closed issue is `repo_A#N` (different issue, same number in a different repo). Run `~/.claude/skills/dispatch/check-dependent --test` to verify the rules and see the regression examples.

   Dependencies can be cross-repo (e.g. an issue on `lucos_media_metadata_api` blocked by an issue on `lucos_media_metadata_manager`), and a blocking dependency is often added in a comment after the issue was originally raised — so checking only the body will miss real dependents. For confirmed dependents, verify that **all** their dependencies are resolved before unblocking — not just the one that was just closed.

   **When unblocking an issue, you MUST do all three of the following — updating the Status without repositioning leaves the issue stranded at the bottom of the queue:**
   1. Update the project board Status field from Blocked → Ready (option ID `3aaf8e5e`).
   2. **Reposition the item per its priority.** When a Status field changes, the item keeps its existing global position on the board — it does NOT move to the top of the new column. So an unblocked item lands at whatever board position it had when blocked (typically the bottom). Apply the standard priority-positioning rules:
      - **Critical or High**: call `updateProjectV2ItemPosition` with no `afterId` to move to the top.
      - **Medium**: position with `afterId` set to the last High item in Ready, so the medium item lands above other mediums but below highs.
      - **Low**: leave at bottom (no repositioning needed).

      Without this step, the work has been "unblocked" in name only — `/next` won't see it ahead of older items, and you'll incorrectly claim it's "next in line" if you reason from memory rather than the board. (Lesson from 2026-05-05: I unblocked lucos_media_seinn#425, said it was next, then `/next` returned a different high-priority issue because #425 was sitting at the bottom of Ready.)

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
   - **First, verify lucas42 was requested as a reviewer at some point in the PR's history** so it landed in his GitHub "review requested" queue rather than relying on him spotting it via the project board. **Use the timeline, NOT the `requested_reviewers` field on the PR object:**
     ```bash
     ~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/issues/{pr_number}/timeline --jq '[.[] | select(.event == "review_requested" and .requested_reviewer.login == "lucas42")] | length'
     ```
     **Why not `requested_reviewers`?** Once a requested reviewer submits a review (approve, changes-requested, or comment), GitHub automatically removes them from `requested_reviewers` — the field reflects *pending* requests, not historical ones. If you check it after the code-reviewer round (or after lucas42 has approved), you'll see an empty array even when lucas42 was correctly requested at PR creation. The timeline preserves the original `review_requested` event regardless of subsequent reviews, so it's the right source of truth.

     Also check if lucas42 already has a review on the PR (which implicitly proves he was requested):
     ```bash
     ~/sandboxes/lucos_agent/gh-as-agent --app lucos-issue-manager repos/lucas42/{repo}/pulls/{pr_number}/reviews --jq '[.[] | select(.user.login == "lucas42")] | length'
     ```

     If **both** counts are 0, lucas42 was never requested — message the **developer who created the PR** to add him (`POST repos/.../pulls/{n}/requested_reviewers` with `reviewers[]=lucas42`). `lucos-issue-manager` intentionally does not have `pull_requests: write` — granting it would also allow creating PRs, which defeats the delegation model. This delegation pattern is permanent; see `references/github-workflow.md` for rationale.

     **CHECKPOINT — before accusing the developer of skipping the reviewer-request step:** If your draft contains "requested_reviewers is empty", "you didn't request lucas42", "no review_requested event", or any similar claim — STOP. Confirm via the timeline check above, not via `requested_reviewers`. Lesson from 2026-05-13 (lucos_monitoring#231): the dispatcher accused the developer of skipping the step when the developer had correctly requested lucas42 at PR creation, but lucas42 had already approved by the time the check ran — the developer's persona-update reinforcements weren't the problem; the dispatcher's check was structurally wrong.
   - Tell the user the PR needs their review and approval. Once approved, it will auto-merge (the `code-reviewer-auto-merge.yml` workflow is deployed across the lucos estate; lucas42's approval triggers it). Provide the full PR URL so they can easily navigate to it.
   - If there are dependent issues to unblock (from step 3), mention them — the user should know that merging this PR will unblock further work.
