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
