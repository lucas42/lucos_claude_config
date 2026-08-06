---
name: feedback-refetch-state-before-writing-final-artifact
description: Re-fetch an external identifier's live STATE at the moment you USE it — in a final artifact OR a mid-conversation claim to a teammate — and its IDENTITY for anything not read this turn. A same-session fetch is not a cache. Stale truths feel like recall; invented identifiers don't announce themselves.
metadata:
  type: feedback
---

When writing a "follow-up actions" table, an incident-report timeline row, a completion-summary status field, or any artifact that future readers will treat as the system-of-record for what was true at write-time: **re-fetch the state of every external identifier (PR, issue, commit) immediately before writing it.**

**Why:** State fields decay. A teammate's SendMessage saying "PR #199 is Draft awaiting sign-off" was true at SendMessage time, but state moves underneath: sign-off lands, the PR transitions to ready, code-reviewer approves, auto-merge fires — all of this can happen in minutes. The cached SendMessage view is then propagated stale into a final artifact.

This bit me 2026-05-28 on the xwing incident's TBD-fill PR #200: I wrote "lucas42/lucos#199 — Draft — awaiting lucas42 sign-off" into the Follow-up Actions row 5 based on architect's SendMessage from ~30 minutes earlier. The architect-message was accurate at the time it was sent; by the time I shipped #200, #199 had been signed off, marked ready, reviewed, and merged at 18:47:18Z — ~6 minutes before I opened #200 at ~18:53Z. I then repeated the stale "draft awaiting sign-off" framing in my completion summary to team-lead at ~19:08Z, ~21 minutes after the merge. team-lead caught the drift.

## Scope is wider than "final artifacts": re-fetch at the moment of USE, not of first learning

The rule above is written for artifacts, but the same decay hits **any claim you make to a teammate mid-conversation** — and that's the more frequent case, because it feels like recall rather than assertion.

**2026-08-06, lucos_worlds#68.** I fetched its reviews, saw `lucos-code-reviewer APPROVED`, and told two teammates it was "fully approved, identical in state to #67". The approval had been posted by mistake and was dismissed **59 seconds later**. My fetch was my own, first-hand, and four minutes old. Not a misreading — a *stale truth*.

⚠️ **Calibration, and the reason this rule is NOT justified by that #68 case** (team-lead's push-back, which was right): a sub-minute decay window is **irreducible latency**, not a rule you failed to follow. I *had* checked, and reported promptly. No re-fetch discipline changes that outcome. What earns this rule is the **hour-scale** cases — `#67 is draft-locked` (stale by an hour, never re-checked), `disjoint files`, `#68 is under review`. Apply it where the gap between learning and using is long enough to matter; don't let it metastasise into re-fetching before every sentence. Adding a line that cannot change the outcome makes the load-bearing lines easier to skip.

Nearly every wrong claim across four agents that evening was this, not fabrication: `#68 is under review`, `both approvals stand`, `#67 is draft-locked`, `disjoint files`. Each held when first checked and had decayed by the time it was repeated. **A stale truth is harder to catch than a guess**, because it carries the felt confidence of something you genuinely verified — the verification just happened at the wrong moment.

**How to apply:** re-fetch immediately before the claim leaves your hands, even if *you* fetched it earlier in the same session, and even for a fast-moving field (review state, draft status, `mergeable`) you read minutes ago. If you're about to write a state word — `approved`, `draft`, `merged`, `blocked`, `open` — into a message, that's the trigger. A same-session fetch is not a cache; it's a timestamped observation.

Corollary that saves the most rework: **don't spend a resource on a step whose input might still change.** Ordering an expensive action (a `workflow_dispatch`, a check run, a rebase) *after* the state it depends on has settled is the same instinct, one stage earlier in the pipeline.

**How to apply:**

- Before writing any external-state field (PR `Draft`/`Open`/`Closed`/`Merged`; issue `Open`/`Closed`) into a final artifact, run a `gh-as-agent repos/{owner}/{repo}/{pulls|issues}/{N} --jq '{state, merged, merged_at}'` (or equivalent) **at the time of writing**, not from prior memory.
- This applies even when the state was just relayed via SendMessage by the artefact's author. SendMessage timestamps tell you when the source agent observed the state; they say nothing about whether the state still holds.
- Most prone to this failure mode: Follow-up Actions tables in incident reports (many rows × many repos, each subject to drift), completion summaries (typically written at the *end* of a busy session when the longest drift has accumulated), and PR descriptions referencing other PRs.
- The cost of the re-fetch is small (~one API call per identifier) and runs concurrently in a single bash invocation. The cost of a stale-state-shipped artifact is a correction round-trip with the dispatcher — strictly more expensive.

## The identity half: never write a numeric identifier you did not read this turn

State drift is the *slow* failure. The fast one is writing an identifier that never existed. Fetch it, or don't cite it.

**The worst offender is a comment permalink — `…/issues/345#issuecomment-4968691700`.** A wrong `#issuecomment-NNN` anchor **does not 404**: GitHub serves the issue page normally and simply doesn't scroll anywhere. So a fabricated permalink looks correct to the reader, to the reviewer, and to me. Nothing in the system will ever flag it. Contrast an issue number, where a wrong `#N` at least lands on a visibly unrelated ticket.

Caught 2026-08-02 on lucas42/lucos_backups#378: I wrote `#issuecomment-5083103399` into a PR body to cite lucas42's `recreate_effort` semantics, having invented the digits wholesale. The real id was `4968691700`. It survived drafting and was caught only because I ran the fetch afterwards out of habit. Had I not, the PR would have shipped a citation pointing at nothing, supporting the single load-bearing claim in the change.

**How to apply:** any `#issuecomment-`, `#discussion_r`, commit SHA, run/job id, or alert number goes into an artifact **only** by copy-paste from a tool result in the current turn. If you're reaching for it from memory or reconstructing it, you are inventing it — run the fetch first:

```bash
gh-as-agent --app lucos-site-reliability "repos/{owner}/{repo}/issues/{N}/comments" \
  --jq '.[] | select(.user.login=="lucas42") | {created:.created_at, url:.html_url}'
```

Note the asymmetry that makes this worth a rule: verifying costs one API call, while the failure is *permanently invisible* rather than merely wrong.

Related: [[feedback_pr_check_merged_field_first]] (same fields to query, scoped to pre-action fetches), [[feedback_verify_sibling_repo_claims]] (verify behavioural claims before propagating), [[feedback_verify_closed_issue_disposition]] (closed ≠ "successful"; check body + closing comment too), [[feedback_verify_body_file_before_pr]] (verify the file's *content* before `create-pr`; this rule covers the identifiers *inside* it).

**Concrete checklist for incident-report Follow-up Actions tables:** before pushing the commit, run a one-shot fetch over all referenced PRs and issues:

```bash
for ref in "lucas42/lucos#199" "lucas42/lucos_claude_config#95" ... ; do
  repo="${ref%#*}" ; n="${ref#*#}"
  echo -n "$ref: "
  gh-as-agent --app lucos-site-reliability "repos/$repo/issues/$n" --jq '{state, merged_at}'
done
```

Compare the output against the status column you've written. Treat mismatches as blockers on the commit.
