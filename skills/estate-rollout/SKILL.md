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

The system administrator should merge in staggered batches where deploys are triggered (see staggering guidance below).

**Staggering applies to merges/deploys, not PR creation.** PRs can be created in any order at any speed — creating a PR does not trigger a deploy. The staggering concern is about the production deploys triggered when PRs are merged:

- **If merges trigger CI builds and production deploys** (e.g. application code, workflow files, config files): "Stagger the **merges** in batches of 5 repos with a few minutes between batches to avoid saturating the production host. PRs can be created all at once."
- **If merges do not trigger production deploys** (e.g. documentation-only changes): "No staggering needed."

Also ask the system administrator to post a comment on the draft PR summarising what was done once the migration is complete — e.g. how many repos were migrated, any failures or repos that needed special handling. This gives the code reviewer context when they review the PR later.

Wait for the system administrator to report back that the migration is complete (PRs merged and deployed, not just opened).

## Step 5: Verify the dry-run shows no remaining failures

After the migration is complete, the dry-run needs to be re-run on the same draft PR. The system administrator or developer should push an empty commit or re-trigger the workflow to get a fresh diff.

Check the updated diff comment. It should now show no additional failures from the convention change (the "new failures" count should be zero or match only repos that are expected exceptions).

If unexpected failures remain, report them to the user and stop — the migration may be incomplete or some repos may need special handling.

## Step 6: Mark the PR as ready for review

Once the dry-run confirms the migration is complete, send a message to `lucos-developer`:

> "The dry-run on {PR URL} confirms all repos have been migrated. Please mark the PR as ready for review and drive the PR review loop (see `~/.claude/pr-review-loop.md`)."

Wait for the developer to complete the review loop and report back.

## Step 7: Report to user

Summarise the outcome: how many repos were migrated, the PR URL, and whether the review loop completed successfully.
