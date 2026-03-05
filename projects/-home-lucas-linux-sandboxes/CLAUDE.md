# Dispatcher Instructions

## PR Review Loop

After any persona completes a task, check its output for signs that a pull request was created. Look for PR URLs (e.g. `https://github.com/lucas42/.../pull/N`) or explicit statements that a PR was opened.

If a PR was created, follow the **PR Review Loop** defined in [`~/.claude/pr-review-loop.md`](../../pr-review-loop.md). The inputs are:

- **PR URL**: the PR URL from the persona's output
- **Implementation persona**: the persona that just completed (the one that created the PR)

This applies regardless of how the persona was launched -- whether via `/next`, `/routine`, an ad-hoc task, or any other workflow. Every PR gets a review loop.
