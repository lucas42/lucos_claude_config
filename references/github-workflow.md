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
- **Reading branch protection — read it yourself; route it to nobody.** `GET /repos/{owner}/{repo}/branches/{branch} --jq '.protection'` gives the required status checks and works for agent Apps that get 403 on the dedicated `…/branches/{branch}/protection` sub-path. **A 403 on the sub-path is never evidence that agents cannot read protection** — that inference was drawn independently by three agents in one evening and is wrong. Three things to get right:
  - **An *unprotected* branch returns 200 here, not an error** — a fully-shaped object with `enabled: false`, `contexts: []` (verified on `lucas42/lucos`). Don't expect the sub-path's `404 "Branch not protected"`; read `.protected` for that question.
  - **The payload is narrow.** `.protection` carries only `enabled` and `required_status_checks`. Everything else (`enforce_admins`, `allow_force_pushes`, `required_conversation_resolution`) exists only on the sub-path.
  - **It cannot tell you whether reviews are required.** `required_pull_request_reviews` is absent here, and has been observed absent on the sub-path too across a uniformly-negative sample — with no positive control, that sample is an untested instrument, so the honest statement is *"no evidence of a review requirement"*, never *"there is none"*. **Beware `jq` here — it is what fabricated the wrong answer.** Both `jq '.field'` and, far more insidiously, object construction `jq '{a, b, c}'` render a **missing key** as `null`, identically to a real null (`echo '{"a":1}' | jq -c '{a, missing_key}'` → `{"a":1,"missing_key":null}`). So a summary object built to compare several protection fields silently reports every absent one as `null`, and reads as an authoritative "not configured". A `null` from jq is never evidence the field is null. Use `has("field")`, or dump the raw payload, before reasoning about any field's absence.
- **Branch protection rule changes** — `lucos-system-administrator` has `administration: write` and CAN modify branch protection rules (required status checks, etc.) via the API. Do not use `/repos/{owner}/{repo}/collaborators/{user}/permission` to pre-check — it reflects collaborator status, not GitHub App installation permissions, and will falsely return `none`. Just make the API call directly and handle a 403 if it comes back.
- **`lucos-issue-manager` cannot comment on or close pull requests — by design.** It has `issues:write` and `pull_requests:read` but not `pull_requests:write`. This is intentional: `pull_requests:write` would also allow *creating* PRs, which the coordinator should never do — all code-level work must be delegated to implementation teammates. The `repos/{owner}/{repo}/issues/{n}/comments` endpoint returns 403 when `n` is a PR even though it works fine for issues. PR-side actions must be delegated via SendMessage to the PR's author bot (typically `lucos-developer`) — they have `pull_requests:write` on PRs they authored. When triage requires a paired PR action (e.g. closing a now-superseded PR), send the author bot a brief message describing the action and rationale. **This is permanent policy, not a temporary workaround.** Read access (search/issues with `is:pr` filter, viewing PRs, listing reviewers, fetching timeline) does work for the issue-manager and should be used by the coordinator directly — do NOT route PR read queries through another bot's credentials.

When an agent discovers it lacks permissions for an action (e.g. a 403 response), it must **escalate immediately** with a clear explanation of what permission is missing and who can grant it — not retry, work around it, or silently drop the task. **In particular: never reach for another agent's credentials to work around the missing permission.** See [`agent-github-identity.md`](agent-github-identity.md) for the credential-isolation rule.

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

### Approve only after the PR is un-drafted

`code-reviewer-auto-merge.yml` triggers on `pull_request_review: submitted` and `pull_request: closed` — there is **no** `ready_for_review` trigger. GitHub separately refuses to enable auto-merge on a draft. So an approval submitted while a PR is still a draft is wasted: the merge cannot be enabled at the time, and marking the PR ready afterwards re-fires nothing. The PR is left approved, un-drafted, and `auto_merge: null` — looking merge-ready and never merging.

Always sequence it **mark ready → then request the review**. Only an *approving* review is trapped — the merge job's `if` requires `review.state == 'approved'` — so a `COMMENT` or `REQUEST_CHANGES` review on a draft fires nothing and costs nothing. It is specifically approvals that must wait for the PR to be un-drafted.

If an approval did land on a draft, the fix is a **fresh approval submitted on the now-ready head**. Marking the PR ready is not enough on its own; nothing else will start the merge.

The wasted attempt does fail the workflow run rather than skipping silently — the enable-auto-merge step retries three times and then exits non-zero — but that surfaces only as a red run in the repo's Actions tab, which nobody is watching. Do not rely on spotting it.

### A push that races the merge is lost silently

The mirror of the trap above. Because approval fires the merge immediately on an unsupervised repo, a commit pushed to the branch *while the review is in flight* can land after the merge has already been computed. The push succeeds, the PR closes as merged without it, and **nothing reports an error to anyone** — not the pusher, not the reviewer, not the merge job.

Every endpoint hanging off the merged PR then agrees the work is present: `/pulls/{n}/commits`, `head.sha` and the reviews list all **freeze at merge time**, so they show the state the reviewer approved and not the later push. Checking any of them confirms a false picture with apparent authority.

To test whether specific work is actually in the base branch, resolve the live tip and compare:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app <persona> repos/lucas42/{repo}/branches/{branch} --jq '.commit.sha'
~/sandboxes/lucos_agent/gh-as-agent --app <persona> "repos/lucas42/{repo}/compare/main...{branch}" --jq '{status, ahead_by, behind_by}'
```

`ahead_by: 0` is the only result that means nothing is outstanding; `status: diverged` with `ahead_by ≥ 1` means the branch holds commits `main` does not. Confirm with a content probe on the file itself at `?ref=main` versus `?ref={branch}` — the commit graph and the content can tell different stories when a fix has been re-landed via a different branch.

The operational rule this implies is in [`pr-review-loop.md`](../pr-review-loop.md) § Step 1: once review is requested on an unsupervised repo the branch is frozen, and any further change — **including one the reviewer asks for** — belongs in a new PR.

---

## What the merge gate actually reads

**`GET /commits/{sha}/check-runs` is NOT the surface branch protection gates on.** A check can be `completed`/`success` there — correct name, correct `app_id`, even carrying `pull_requests: [N]` — and still not satisfy the gate. To determine whether a PR can merge, use GraphQL:

```graphql
pullRequest(number: N) {
  mergeStateStatus          # BLOCKED / CLEAN — the gating field
  reviewDecision
  commits(last: 1) { nodes { commit { statusCheckRollup {
    state
    contexts(first: 30) { nodes {
      ... on CheckRun { name conclusion }
      ... on StatusContext { context state }
    } }
  } } } }
}
```

Three traps, all hit in one evening (2026-08-06, `lucos_worlds#72`):

- **`mergeable` is not the gating field.** `mergeable: MERGEABLE` means "no merge conflict", not "allowed to merge". `mergeStateStatus` is the one that reflects branch protection.
- **`statusCheckRollup.state: SUCCESS` is not proof a required context is present.** The rollup aggregates over the contexts *in* it, so a required context that is entirely **absent cannot make it fail** — it simply isn't counted. **Enumerate `contexts` and look for the required name**; never infer membership from the summary. Cross-check against `required_status_checks.contexts` (see the branch-protection entry above), and beware a similarly-named non-required check standing in for the required one (`CodeQL` vs the required `Analyze (python)`).
- **A `workflow_dispatch`-triggered run may post a check-run without its required context entering the rollup.** On #72 the dispatch added the *Advanced Security* `CodeQL` context to the rollup but **not** the *GitHub Actions* `Analyze (python)` one — established by comparing against #73, an identical never-dispatched PR whose rollup held only the 7 CircleCI contexts. So this is not "dispatch never joins the rollup"; one suite joined and one didn't, which leaves structural-vs-stale-propagation genuinely open. **The operational rule holds regardless of cause: do not reach for `workflow_dispatch` expecting it to unblock a merge** — it makes a check *visible*, not reliably *counted*.

## After a PR is Created

Implementation teammates are responsible for requesting their own code review after opening a PR. The handover is peer-to-peer: SendMessage `lucos-code-reviewer` directly, following the process in [`../pr-review-loop.md`](../pr-review-loop.md). The dispatcher does not orchestrate this. Do not consider an implementation task complete until the review loop has finished.

---

## Censusing PRs/issues across the org — always reconcile against an unsliced total

Two independent failure modes make a sliced census silently wrong, and **they are easy to conflate — one gives you too few slices' worth of data, the other too little data per slice.** Print both numbers per slice and one line catches both.

**1. An impossible date silently yields zero.** `gh search` (and the `search/issues` API) returns `issueCount: 0` with a well-formed response and **no error** for a date that does not exist. `merged:YYYY-MM-01..YYYY-MM-31` therefore returns **nothing at all** for February and every 30-day month. It is not only `..-31`: `..-30` fails the same way on February. Half a year can vanish from a tally with nothing announcing it, and every conclusion drawn from the tally inherits the hole.

**2. Search paginates to a hard 1000 results.** A slice whose `issueCount` exceeds what you actually fetched is **silently truncated** — the count is honest, the data is short, and nothing errors.

So whenever you slice a search to get around result caps:

- **Don't hand-build month boundaries.** Compute each month's real last day, or — simpler and immune to the whole class — slice by **fixed-length windows** (7 or 10 days) that don't care where months end.
- **Reconcile the summed slices against the unsliced query's `issueCount`** before drawing any conclusion from the total. This is the check that actually catches failure 1: a bad slice is indistinguishable from a genuinely empty period at the per-slice level, and only the reconciliation distinguishes them.
- **Print each slice's `issueCount` alongside the number of items you fetched for it**, and assert they match. That catches failure 2, which reconciliation against the total will *not* catch on its own.
- Treat a per-slice zero as *suspect* until reconciled, not as data. Same principle as validating an extraction pattern against a known-positive: an instrument that returns nothing looks the same whether the thing is absent or the probe is broken.

## Bulk Cross-Repo Operations

When pushing commits to many repos simultaneously (rolling out a workflow change, bulk secret updates, convention fixes), **stagger them in batches of 3-5 repos with a few minutes between batches**. Do not push to all repos at once.

Each push triggers a CI build and deploy. Simultaneous deploys to the same production host saturate CPU and I/O, causing Docker healthcheck cascades, port binding failures, and service outages. Both the 2026-03-19 incident (PORT missing from .env under concurrent SFTP load) and the 2026-03-20 incident (avalon load spike to 40) were caused or worsened by pushing to ~30 repos simultaneously.
