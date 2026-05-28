---
name: feedback-refetch-state-before-writing-final-artifact
description: Before writing a PR/issue's state (Draft / Open / Closed / Merged) into a final artifact — incident report, completion summary, follow-up actions table, hand-off message — re-fetch the live state. Cached SendMessage knowledge decays fast.
metadata:
  type: feedback
---

When writing a "follow-up actions" table, an incident-report timeline row, a completion-summary status field, or any artifact that future readers will treat as the system-of-record for what was true at write-time: **re-fetch the state of every external identifier (PR, issue, commit) immediately before writing it.**

**Why:** State fields decay. A teammate's SendMessage saying "PR #199 is Draft awaiting sign-off" was true at SendMessage time, but state moves underneath: sign-off lands, the PR transitions to ready, code-reviewer approves, auto-merge fires — all of this can happen in minutes. The cached SendMessage view is then propagated stale into a final artifact.

This bit me 2026-05-28 on the xwing incident's TBD-fill PR #200: I wrote "lucas42/lucos#199 — Draft — awaiting lucas42 sign-off" into the Follow-up Actions row 5 based on architect's SendMessage from ~30 minutes earlier. The architect-message was accurate at the time it was sent; by the time I shipped #200, #199 had been signed off, marked ready, reviewed, and merged at 18:47:18Z — ~6 minutes before I opened #200 at ~18:53Z. I then repeated the stale "draft awaiting sign-off" framing in my completion summary to team-lead at ~19:08Z, ~21 minutes after the merge. team-lead caught the drift.

**How to apply:**

- Before writing any external-state field (PR `Draft`/`Open`/`Closed`/`Merged`; issue `Open`/`Closed`) into a final artifact, run a `gh-as-agent repos/{owner}/{repo}/{pulls|issues}/{N} --jq '{state, merged, merged_at}'` (or equivalent) **at the time of writing**, not from prior memory.
- This applies even when the state was just relayed via SendMessage by the artefact's author. SendMessage timestamps tell you when the source agent observed the state; they say nothing about whether the state still holds.
- Most prone to this failure mode: Follow-up Actions tables in incident reports (many rows × many repos, each subject to drift), completion summaries (typically written at the *end* of a busy session when the longest drift has accumulated), and PR descriptions referencing other PRs.
- The cost of the re-fetch is small (~one API call per identifier) and runs concurrently in a single bash invocation. The cost of a stale-state-shipped artifact is a correction round-trip with the dispatcher — strictly more expensive.

Related: [[feedback_pr_check_merged_field_first]] (same fields to query, scoped to pre-action fetches), [[feedback_verify_sibling_repo_claims]] (verify behavioural claims before propagating), [[feedback_verify_closed_issue_disposition]] (closed ≠ "successful"; check body + closing comment too).

**Concrete checklist for incident-report Follow-up Actions tables:** before pushing the commit, run a one-shot fetch over all referenced PRs and issues:

```bash
for ref in "lucas42/lucos#199" "lucas42/lucos_claude_config#95" ... ; do
  repo="${ref%#*}" ; n="${ref#*#}"
  echo -n "$ref: "
  gh-as-agent --app lucos-site-reliability "repos/$repo/issues/$n" --jq '{state, merged_at}'
done
```

Compare the output against the status column you've written. Treat mismatches as blockers on the commit.
