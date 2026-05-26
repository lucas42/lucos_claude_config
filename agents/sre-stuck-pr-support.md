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
