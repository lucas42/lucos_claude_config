---
name: estate-rollout
description: Coordinate an estate-wide change across repositories, verified by the lucos_repos dry-run diff
disable-model-invocation: true
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

## Step 3: Migrate affected repos

Once the user confirms the diff looks correct, send a message to `lucos-system-administrator`:

> "Apply the following change across all affected repositories: {description of the per-repo change the user described}. The dry-run diff on {PR URL} shows which repos need updating."

Include these instructions based on the type of change:

- **If the change involves code changes that trigger CI builds and production deploys** (e.g. editing workflow files, config files, source code): "Stagger the changes in batches of 5 repos with 1 minute between batches to avoid saturating the production host."
- **If the change only affects repo configuration that does not trigger a release** (e.g. branch protection rules, GitHub settings): "No staggering needed — these changes do not trigger production deploys."

Wait for the system administrator to report back that the migration is complete.

## Step 4: Verify the dry-run shows no remaining failures

After the migration is complete, the dry-run needs to be re-run on the same draft PR. The system administrator or developer should push an empty commit or re-trigger the workflow to get a fresh diff.

Check the updated diff comment. It should now show no additional failures from the convention change (the "new failures" count should be zero or match only repos that are expected exceptions).

If unexpected failures remain, report them to the user and stop — the migration may be incomplete or some repos may need special handling.

## Step 5: Mark the PR as ready for review

Once the dry-run confirms the migration is complete, send a message to `lucos-developer`:

> "The dry-run on {PR URL} confirms all repos have been migrated. Please mark the PR as ready for review and drive the PR review loop (see `~/.claude/pr-review-loop.md`)."

Wait for the developer to complete the review loop and report back.

## Step 6: Report to user

Summarise the outcome: how many repos were migrated, the PR URL, and whether the review loop completed successfully.
