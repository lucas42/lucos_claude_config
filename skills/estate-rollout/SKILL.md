---
name: estate-rollout
description: Coordinate an estate-wide change across repositories, verified by the lucos_repos dry-run diff
disable-model-invocation: false
---

Follow this process to roll out an estate-wide change across lucos repositories, using the lucos_repos dry-run diff to verify the migration at each stage. The user will describe the change to be made.

## Step 1: Update or create the convention

Send a message to `lucos-developer`:

> "Implement the following change in lucos_repos: {description of the convention change — either editing an existing convention or creating a new one, based on what the user described}. Create a **DRAFT** pull request with the change. Do not mark it ready for review yet — we need to verify the dry-run diff first. After creating the draft PR, report back with the PR URL."

Wait for the developer to respond with the draft PR URL.

## Step 2: Verify the dry-run shows expected failures

Once the developer reports back with the draft PR URL, wait for the audit dry-run diff to be posted as a comment on the PR. This happens automatically via GitHub Actions.

Check the diff comment on the PR. It should show additional failures — these are the repos that don't yet comply with the new or updated convention. Report the number of affected repos to the user and ask them to confirm the diff matches expectations before proceeding.

If the dry-run has not posted yet, wait and re-check periodically. If the workflow is not present (e.g. the dry-run CI hasn't been set up yet), tell the user and stop.

## Step 3: Smoke test via .github-test (when applicable)

**This step is mandatory when the convention change involves a reusable workflow or workflows that call a reusable workflow** (e.g. changes to `code-reviewer-auto-merge.yml`, `codeql-analysis.yml`, or any caller template that references a workflow in `lucas42/.github`). Skip this step only if the change has no relationship to reusable workflows.

Before migrating any other repositories, the change must be applied to `lucas42/.github-test` first and validated against the smoke tests in `lucas42/.github`.

Send a message to `lucos-system-administrator`:

> "Apply the following per-repo change to `lucas42/.github-test` only: {description of the per-repo change}. After pushing, check whether the smoke tests in `lucas42/.github` pass. Report back with the result — do not proceed to other repos."

Wait for the system administrator to report back.

- **If the smoke tests pass**: proceed to Step 4.
- **If the smoke tests fail**: stop and report the failure to the user. The convention change or the per-repo migration may need adjustment before it can be rolled out. Do not proceed to the estate-wide migration.

**Self-referential changes:** Pay particular attention when the change touches the merge workflow itself (e.g. `code-reviewer-auto-merge.yml`). A broken caller template will prevent auto-merge from triggering on the very PR that introduced the change — a self-locking situation that cannot be detected by code review alone. The `.github-test` smoke test is the only way to catch this before the PR merges and the breakage propagates estate-wide.

## Step 4: Migrate affected repos

Once the user confirms the diff looks correct (and the smoke test has passed, if applicable), send a message to `lucos-system-administrator`:

> "Apply the following change across all affected repositories: {description of the per-repo change the user described}. The dry-run diff on {PR URL} shows which repos need updating. {If Step 3 was performed: 'Note: lucas42/.github-test has already been migrated during the smoke test step — skip it in this batch.'}"

**Migration means deployed, not just PR-opened.** The migration is not complete until the changes have been merged and deployed. Opening pull requests is the first step — the system administrator must also ensure the PRs are reviewed, approved, and merged. On unsupervised repos, approved PRs auto-merge.

**Estate rollout merge exception:** For estate rollouts of templated changes (the same change applied across all repos), the system administrator may merge PRs directly on supervised repos — this is an explicit exception to the normal `unsupervisedAgentCode` policy. This is permitted because estate rollouts have already passed multiple verification gates that exceed normal PR review:
1. The change was smoke-tested on `.github-test`
2. The dry-run confirmed the scope
3. The user confirmed the diff
4. A code reviewer approved the PRs

The system administrator must verify that CI checks (tests, builds, and other required workflows) are passing before merging each PR. If CI is still running, enable auto-merge on the PR rather than waiting — but check back to confirm it actually merged before declaring the migration complete.

**No merge staggering needed.** PRs can be merged as quickly as CI allows. Deploy serialization is handled automatically by the `serial-group: deploy-<host>` config in each repo's CircleCI config (rolled out 2026-04-22) — concurrent deploys to the same host queue in CircleCI rather than racing. Transient CI failures that do occur during a rollout wave are handled in Step 6 (CI verification and auto-retry).

Also ask the system administrator to post a comment on the draft PR summarising what was done once the migration is complete — e.g. how many repos were migrated, any failures or repos that needed special handling. This gives the code reviewer context when they review the PR later.

Wait for the system administrator to report back that the migration is complete (PRs merged and deployed, not just opened).

## Step 5: Verify the dry-run shows no remaining failures

After the migration is complete, the dry-run needs to be re-run on the same draft PR. Send a message to `lucos-system-administrator` asking them to trigger the audit dry-run workflow via `workflow_dispatch`:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-system-administrator \
  repos/lucas42/lucos_repos/actions/workflows/audit-dry-run.yml/dispatches \
  --method POST \
  -f ref="{pr_branch_name}" \
  -f inputs[pr_number]="{pr_number}"
```

Only `lucos-system-administrator` has `actions:write` permission for this. Do not push empty commits to re-trigger — use `workflow_dispatch` instead to keep commit history clean.

Check the updated diff comment. The "new failures" count must be **zero**. An open PR on a repo does not count as resolving a violation — the PR must be merged and the repo's default branch must pass the convention.

**Do not move the PR out of draft status until the dry-run shows zero new failures.** If failures remain:
- Identify why — is it an unmerged migration PR, a repo that was missed, or a genuine issue with the convention?
- Get the remaining repos fixed (merge their PRs, or create new ones)
- Re-run the dry-run again
- Repeat until zero new failures

Only then proceed to Step 6.

## Step 6: Verify CI is green across migrated repos

After the migration is complete, transient failures are expected during rollout waves (shared infra like loganne, creds, docker mirror, configy briefly under load). These are mechanical to recover from — poll and auto-retry rather than treating every failure as a real bug.

For each repo touched by the migration, poll the CircleCI v2 API for the latest main-branch pipeline:

```
GET https://circleci.com/api/v2/project/gh/lucas42/{repo}/pipeline?branch=main
```

Fetch its workflows:

```
GET https://circleci.com/api/v2/pipeline/{pipeline_id}/workflow
```

For any workflow with `status == "failed"`, trigger a rerun from failed:

```
POST https://circleci.com/api/v2/workflow/{workflow_id}/rerun
Body: {"from_failed": true}
```

Wait 5–10 minutes, re-poll, and re-trigger any still-failing pipelines once more. After the second retry, treat persistent failures as real bugs — raise a GitHub issue on the affected repo and continue.

**The rollout is not "done" until every migrated repo's latest main-branch pipeline is green** (or persistent failures have open issues tracking them). A rollout where PRs merged but pipelines are red is incomplete.

Use the CircleCI API token from the environment. See `~/.claude/references/circleci-conventions.md` for API access patterns.

## Step 7: Mark the PR as ready for review

Once the dry-run confirms zero new failures and CI is green, send a message to `lucos-developer`:

> "The dry-run on {PR URL} confirms all repos have been migrated (zero new failures). Please mark the PR as ready for review and drive the PR review loop (see `~/.claude/pr-review-loop.md`)."

Wait for the developer to complete the review loop and report back.

## Step 8: Close the originating issue

If this estate rollout was triggered by a specific GitHub issue (passed in as context at Step 1), check whether the convention PR merging completes the issue's requirements. If so, post a closing comment summarising what was done (convention added, N repos migrated, PR merged) and close the issue. If the issue has remaining work beyond the convention + migration, leave it open and note what's left.

## Step 9: Report to user

Summarise the outcome: how many repos were migrated, the PR URL, whether the review loop completed successfully, and whether the originating issue was closed.
