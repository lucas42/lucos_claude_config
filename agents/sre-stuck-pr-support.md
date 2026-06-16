# SRE — Stuck PR infrastructure support

This file is read by `lucos-site-reliability` when the code reviewer or another agent escalates a stuck PR with infrastructure-level symptoms.

## Scope

SRE responsibility covers **infrastructure-level** stuck PRs — not code-level ones.

**SRE territory (plumbing):**
- CI infrastructure failures (runner out of disk, Docker layer extraction failures, network timeouts to registries).
- `mergeable_state: blocked` with no obvious code-level cause (branch protection misconfiguration, stale required checks from deleted workflows).
- Auto-merge not triggering despite an approved PR meeting all visible requirements.
- Persistently red CI on a repo where *all* PRs are failing (broken main branch or CI config).
- GitHub Actions workflow failures that need investigation. (Workflow re-runs go to `lucos-system-administrator` which has `actions:write`.)

**Not SRE territory (code):**
- A single PR with a test failure → route to `lucos-developer`.
- Merge conflicts → route back to code reviewer or PR author.
- Missing approvals → route to code reviewer.

## The auto-merge trap

**Don't infer "needs manual merge" from `auto_merge: null` or a skipped `reusable/auto-merge` check.** Almost every repo has `.github/workflows/code-reviewer-auto-merge.yml`, which auto-merges once `lucos-code-reviewer` (or another approver) approves. That workflow is independent of the PR-level `auto_merge` field (which only reflects GitHub-native auto-merge — it is `null` even when workflow-driven auto-merge is in place) and of the `reusable/auto-merge` check that gets `skipped` on supervised repos (that is the *Dependabot* path, not the code-reviewer path). Verify by checking for `code-reviewer-auto-merge.yml` in the repo before claiming manual merge is needed:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-site-reliability \
  repos/lucas42/<repo>/contents/.github/workflows/code-reviewer-auto-merge.yml --jq '.path' 2>/dev/null
```

## The draft-approval re-trigger trap

A PR approved + green + marked-ready but **not merging**, with the `reusable / auto-merge` check at `conclusion: failure` and `auto_merge: null`, is usually the **approvals-fired-while-draft** quirk:

1. The reviewer(s) approved while the PR was still a **draft**.
2. `code-reviewer-auto-merge.yml` fired on the `pull_request_review` event, passed its reviewer-match logic, then `gh pr merge --auto` failed with `GraphQL: Pull Request is still a draft (mergePullRequest)` (it retries a few times, all fail).
3. The author later marked it ready — but `ready_for_review` is **not** a trigger for that workflow (it only listens to `pull_request_review: submitted` and `pull_request: closed`), so nothing re-fires.

**Confirm before acting** (don't just assume — read the evidence):
- `issues/<N>/timeline` → find the `ready_for_review` timestamp.
- The failed auto-merge run's timestamps → if every run predates `ready_for_review`, they all ran against a draft.
- The failed job log → look for `Pull Request is still a draft (mergePullRequest)`.

**Fix:** emit a fresh `pull_request_review: submitted` event by having the **expected reviewer** (the one the workflow matches on — usually `lucos-code-reviewer`, *not* `lucos-security`) submit a new APPROVE on the current HEAD. The HEAD is unchanged, so it's a re-trigger, not a re-review. **Re-running the old failed run does NOT work** — its event payload is frozen with `draft=true`, so it'll fail identically. As SRE you can't emit the reviewer's approval yourself; SendMessage the code reviewer to re-approve.

## Verification after infrastructure fixes

After any remediation action, re-check the PR's CI status, `mergeable_state`, and auto-merge status. Report the result — do not assume success. If the fix didn't work, investigate further or re-escalate.

## Verify secondary-PR state before claiming anything about it

When an investigation surfaces a "while you're at it" or "the same may apply to..." secondary PR, fetch that PR's **current** state in the same investigation pass before mentioning it in a report or SendMessage. Do not reason from the state-at-the-time-of-the-event you originally investigated — the secondary PR may have moved on hours or days ago.

Include `merged`, `merged_at`, and `state` in every PR-state fetch — not just `mergeable` / `mergeStateStatus`. A merged PR shows `mergeable: UNKNOWN`, `mergeStateStatus: UNKNOWN`, `autoMergeRequest: null` — superficially identical to an open PR mid-computation. Inspecting only the latter cluster produces confidently-stated false-negative claims like "this PR isn't merged yet."

Canonical safe pre-claim fetch:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-site-reliability \
  repos/lucas42/<repo>/pulls/<N> \
  --jq '{state, merged, merged_at, merged_by: .merged_by.login, mergeable_state}'
```

This applies to **every** secondary-PR mention in a report or message — whether proposing close+reopen, predicting it'll-stick-too-when-approved, or any other forward-looking framing about a PR you're not already actively driving.
