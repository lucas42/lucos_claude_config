# Code Reviewer: Stuck PR Guide

This file is read by `lucos-code-reviewer` during the "review all open PRs" pass.

## Stuck PR Identification Criteria

A PR is stuck if any of the following are true:

**1. CI failure.** Any check-run has `conclusion: failure`, or any commit status has `state: failure`. Check both check-runs AND commit statuses — some CI systems (e.g. CircleCI) report via commit statuses, not check-runs.

**2. `CHANGES_REQUESTED` with no new commits for >24 hours.** Applies to both Dependabot and agent PRs. If no one has pushed a fix within 24 hours of the review, the PR is stuck.

**3. PR on an archived repo.** A PR on an archived repo can never be merged. Action: close the PR with a comment explaining the repo is archived.

**4. Auto-merge enabled but `mergeable_state: blocked` despite passing CI and an existing approval.** This means something is silently preventing the merge — usually a branch protection rule or a required status check that isn't surfacing as a check-run (e.g. a stale required check from a deleted workflow).

**5. `mergeable_state: dirty` (actual merge conflict) with no rebase for >72 hours.** The PR has genuine conflicts with the base branch. For Dependabot PRs, Dependabot will rebase on its own scheduled cadence — do not immediately escalate. Only flag as stuck if the conflict has been unresolved for >72 hours with no activity. Note: `mergeable_state: behind` (branch is simply behind main, no conflicts) is NOT stuck — GitHub will not block merge for this reason alone, and Dependabot handles it automatically.

**6. Workflow `startup_failure`.** Check recent GitHub Actions workflow runs for the PR's head SHA — not just check-runs. A workflow that fails at startup (e.g. permissions error, missing secret, invalid YAML) won't register as a check-run conclusion at all, so it's invisible to check-run-only queries. Use:
```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-code-reviewer \
  repos/lucas42/{repo}/actions/runs?head_sha={sha}&per_page=10 \
  --jq '.workflow_runs[] | {name, status, conclusion}'
```

**7. Approved + CI green + `mergeable_state: clean` + `auto_merge: null`.** Everything looks ready but auto-merge was never enabled. Check the Actions runs API for the head SHA for any workflow with `startup_failure` or `failure` conclusion — the auto-merge workflow may have failed silently regardless of what it's named. Do NOT rely on checking for a specific workflow filename (e.g. `code-reviewer-auto-merge.yml`) — repos use different names (e.g. `dependabot-auto-merge.yml`).

---

## Stuck PR Escalation Routing

Before escalating, **always try self-service fixes first**. Asking a human to intervene should be a last resort. The most common self-service fix is re-running a failed workflow — ask `lucos-system-administrator` to re-run it (they have `actions:write` access). **Try re-running multiple times before concluding it needs a human** — "unstable status" and "base branch was modified" errors on the Dependabot auto-merge workflow are usually transient and clear on a subsequent re-run. Only escalate to the team lead if the re-run fails repeatedly with the same non-transient error.

| Problem | First action | Escalate to (if first action fails) |
|---|---|---|
| **Test failure in PR code** (tests fail, not infra) | N/A — escalate directly | `lucos-developer` — SendMessage with repo, PR number, failing test |
| **CI failure** (infrastructure, runner issues, Docker errors, network timeouts, stale checks, startup failures, persistently red CI) | Ask `lucos-system-administrator` to re-run the failing workflow | `lucos-site-reliability` — SendMessage if re-run fails or problem recurs |
| **Auto-merge workflow failed** (race condition, "unstable status", "base branch modified", startup failure) | Ask `lucos-system-administrator` to re-run — try multiple times; these errors are often transient | Team lead — only if re-run fails repeatedly with the same error and is clearly non-transient |
| **`mergeable_state: dirty`** (genuine merge conflict) | Leave it — Dependabot rebases on its own schedule. Only escalate if still dirty after 72+ hours with no activity | Team lead (for `@dependabot rebase` if you need to force sooner) — **note: `@dependabot rebase` cannot be posted by GitHub Apps; requires lucas42** |
| **`mergeable_state: blocked` with no obvious cause** | `lucos-site-reliability` | SendMessage — likely branch protection issue |
| **Auto-merge not triggering** (criterion 7) | Ask `lucos-system-administrator` to re-run the auto-merge workflow | `lucos-site-reliability` — if re-run succeeds but auto-merge still not set |
| **Archived repo** | Close directly | Post a comment explaining why, then close |

---

## Post-escalation Verification

**Treat every escalation as pending until you observe a state change.** Do not report a stuck PR as "handled" just because you sent a message. After escalating:

1. Note the PR as "escalated, pending verification" in your report.
2. On your next PR review pass (or if the teammate messages you back), re-check the PR's state to confirm it has progressed.
3. If the PR is still stuck after the teammate's action, re-escalate with the new information.

This also applies to `@dependabot` commands: if someone posts `@dependabot recreate`, check Dependabot's response. A permissions error means the command failed silently.
