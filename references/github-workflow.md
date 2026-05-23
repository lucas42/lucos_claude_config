# GitHub Workflow Reference

The mechanics of how agents authenticate to GitHub and write commits — `gh-as-agent`, `git-as-agent`, the heredoc pattern, the `{owner}/{repo}` template-substitution gotcha, cross-repo issue references, and the "committing `~/.claude` changes" rules — are in [`agent-github-identity.md`](agent-github-identity.md). Read that first.

This file collects the remaining workflow material:

- The GitHub Projects API (uses a different wrapper).
- GitHub App permission limits (what agents cannot do, and who to escalate to).
- Marking draft PRs ready for review (REST silently no-ops; use GraphQL).
- After-PR review-loop pointer.
- Bulk cross-repo operation safety rules.

For the per-issue implementation walk (starting comments, branching, PR creation, closing keywords, supervised-repo reviewer requests), see [`../agents/workflows/implement-issue.md`](../agents/workflows/implement-issue.md).

---

## GitHub Projects API calls (PAT required)

GitHub Apps cannot access v2 user projects. For GitHub Projects interactions **only**, use the `gh-projects` wrapper instead of `gh-as-agent`:

```bash
~/sandboxes/lucos_agent/gh-projects graphql \
    -f query='{ viewer { projectsV2(first: 10) { nodes { id title } } } }'
```

**Do not use `gh-projects` for anything other than GitHub Projects.** All other GitHub API calls must use `gh-as-agent` with the appropriate `--app`.

---

## GitHub App limitations — things agents cannot do

Some GitHub operations require the **repo owner** (lucas42) to perform them in the GitHub web UI. Agents must not accept tasks for these — tell the user what needs changing and why upfront:

- **GitHub App permission changes** (adding `actions:write`, `contents:write`, etc.) — requires the app owner to update them in GitHub Developer Settings, then the repo owner to approve the new permissions on each installation. No API for this.
- **`@dependabot` commands** (`recreate`, `rebase`, etc.) — require push access to the repository. No agent app currently has push access.
- **Actions workflow re-runs** — require `actions:write`. `lucos-system-administrator` has this permission and can re-run workflows.
- **Branch protection rule changes** — `lucos-system-administrator` has `administration: write` and CAN modify branch protection rules (required status checks, etc.) via the API. Do not use `/repos/{owner}/{repo}/collaborators/{user}/permission` to pre-check — it reflects collaborator status, not GitHub App installation permissions, and will falsely return `none`. Just make the API call directly and handle a 403 if it comes back.
- **`lucos-issue-manager` cannot comment on or close pull requests — by design.** It has `issues:write` but not `pull_requests:write`. This is intentional: `pull_requests:write` would also allow *creating* PRs, which the coordinator should never do — all code-level work must be delegated to implementation teammates. The `repos/{owner}/{repo}/issues/{n}/comments` endpoint returns 403 when `n` is a PR even though it works fine for issues. PR-side actions must be delegated via SendMessage to the PR's author bot (typically `lucos-developer`) — they have `pull_requests:write` on PRs they authored. When triage requires a paired PR action (e.g. closing a now-superseded PR), send the author bot a brief message describing the action and rationale. **This is permanent policy, not a temporary workaround.**

- **`lucos-issue-manager` also lacks `pull_requests:read`, which silently corrupts PR searches.** A query like `gh-as-agent --app lucos-issue-manager search/issues?q='org:lucas42 is:pr is:open'` returns 200 OK with a populated `items[]` — but the `is:pr` filter is silently dropped and you get back **all open issues**, not PRs. Items have `pull_request: null`, `html_url` ending in `/issues/N`, and titles that look like issue titles, but there is no error to alert you. The same corruption affects `is:pr is:closed`, `review-requested:lucas42`, and any other PR-specific filter. Fix: use `--app lucos-developer` (or any bot with `pull_requests:read`) for PR search queries. `lucos-developer` returns the real counts (e.g. 0 open vs 6740 closed across the org) with correct `/pull/N` URLs. **Trap to avoid:** never compile a "PRs waiting on lucas42" list from the issue-manager bot — switch to the developer bot before searching.

When an agent discovers it lacks permissions for an action (e.g. a 403 response), it must **escalate immediately** with a clear explanation of what permission is missing and who can grant it — not retry, work around it, or silently drop the task.

---

## Marking draft PRs as ready for review

The REST API (`PATCH /repos/{owner}/{repo}/pulls/{number}` with `draft: false`) **does not work** — it silently ignores the `draft` field. Use the GraphQL `markPullRequestReadyForReview` mutation instead:

```bash
PR_NODE_ID=$(~/sandboxes/lucos_agent/gh-as-agent --app lucos-developer \
  repos/lucas42/{repo}/pulls/{number} --jq '.node_id')

~/sandboxes/lucos_agent/gh-as-agent --app lucos-developer graphql \
  -f query="mutation { markPullRequestReadyForReview(input: {pullRequestId: \"$PR_NODE_ID\"}) { pullRequest { isDraft } } }"
```

The `pull_requests: write` permission (which developer and other apps already have) is sufficient. Do **not** use `gh-projects` for this — that PAT only has `project` scope.

---

## After a PR is Created

Implementation teammates are responsible for requesting their own code review after opening a PR. The handover is peer-to-peer: SendMessage `lucos-code-reviewer` directly, following the process in [`../pr-review-loop.md`](../pr-review-loop.md). The dispatcher does not orchestrate this. Do not consider an implementation task complete until the review loop has finished.

---

## Bulk Cross-Repo Operations

When pushing commits to many repos simultaneously (rolling out a workflow change, bulk secret updates, convention fixes), **stagger them in batches of 3-5 repos with a few minutes between batches**. Do not push to all repos at once.

Each push triggers a CI build and deploy. Simultaneous deploys to the same production host saturate CPU and I/O, causing Docker healthcheck cascades, port binding failures, and service outages. Both the 2026-03-19 incident (PORT missing from .env under concurrent SFTP load) and the 2026-03-20 incident (avalon load spike to 40) were caused or worsened by pushing to ~30 repos simultaneously.
