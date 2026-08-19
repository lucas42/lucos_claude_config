---
name: pattern-github-silently-disables-automerge
description: "GitHub can disable auto-merge on a Dependabot PR seconds after the last required check goes green, with no reason recorded — the PR then sits until someone merges it by another path. Occurrence log; a 2nd sighting changes the remedy arithmetic."
metadata:
  type: pattern
---

**Symptom:** a Dependabot PR with all required checks green sits unmerged for days, and `lucos_monitoring`'s `stale-dependabot-prs` check on `lucos_repos` goes red at the 48h mark.

**Tell that distinguishes it from an ordinary blocked PR:** the issue timeline contains an `auto_merge_disabled` event that *nothing in our system asked for*, moments after the final required check reports success. Check it with:

```bash
gh-as-agent --app lucos-site-reliability "repos/lucas42/{repo}/issues/{N}/timeline?per_page=100" \
  --jq '.[]|{event,created_at,actor:.actor.login}'
```

**Occurrence log — append here rather than filing a ticket.**

| # | date | PR | gap | notes |
|---|---|---|---|---|
| 1 | 2026-08-11 | lucas42/lucos_repos#485 | 6d15h | `auto_merge_enabled` 07:11:02Z → last required check (`Analyze (go)`) green 07:14:55Z → `auto_merge_disabled` **07:14:58Z**, both by `lucos-ci[bot]`. Merged 08-17 via the code-reviewer approval path. |

**Ruled out at occurrence 1** (re-run these before concluding anything on occurrence 2): a failing required check (all three green, combined status `success`); the base branch moving (no commit on `main` for 6 hours either side); a push to head (single commit, untouched); a conflict (later merged cleanly from that same commit, no rebase). Mechanism is GitHub-side and **not established** — the timeline records the disable with no reason.

**Why no ticket:** one occurrence in 27.7 days against the build-and-maintain cost of a re-enable job, when detection already exists at 48h. The gap is *response*, not detection — same argument as `lucos/docs/incidents/2026-08-17-backups-python-alpha-charset-normalizer.md` §Stage 6 ("detection worked; response didn't"), which is a merged report, **not an open thread**. Datapoint recorded publicly as a comment on lucas42/lucos_repos#492 so it is discoverable by whoever meets occurrence 2.

**On a second sighting:** the arithmetic changes and a remedy becomes proposable. Note the sibling cause first — a *failed* required check that nothing ever retries (lucas42/lucos_repos#492, a flaky timing test) produces the identical symptom, so confirm which one you have from the timeline before proposing anything.

Related: [[feedback_check_trap_precondition_before_firing]] (`auto_merge: null` alone means nothing), [[feedback_pr_check_merged_field_first]].
