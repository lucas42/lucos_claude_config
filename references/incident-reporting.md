# Incident Reporting

This document defines the process for writing an incident report for a specific resolved critical incident. Incident reports live in `docs/incidents/` in the `lucos` repo.

Use this process when you have identified a critical issue that needs a report -- whether during ops checks (Check 2: Incident Report Coverage) or when asked to write a report ad-hoc.

> **STOP — read the completion checklist before you start, not after.** Incident-report work is delivered when *all four* items below are true, not when the report PR is open:
>
> 1. Report written following `docs/incidents/TEMPLATE.md`
> 2. Follow-up issues filed and linked in the Follow-up Actions table
> 3. PR raised, **reviewed, and merged** (drive the review loop yourself per `pr-review-loop.md` — do not stop at "PR opened")
> 4. Individual notification messages sent to **every other teammate** (six messages, not one "broadcast")
>
> The full checklist with checkbox syntax is at the bottom of this file. It is duplicated here at the top because every previous false-completion of this workflow has been caused by reading down to Step 2 and stopping. Items 3 and 4 are not optional follow-ups — they are part of the work.

## Extend an existing report, or write a new one?

Before writing a new report, check whether the incident you are about to document is actually a *continuation* of an existing one. The rule:

- **Ongoing impact** → extend the existing report. If the user-visible impact (e.g. "no backups are running", "service is down", "data is stale") has not yet been resolved, and a new failure is just the next chapter of the same story, append to the existing report rather than creating a new one. Add a new section to the timeline, document the second failure mode, and update the resolution / follow-up sections.
- **Fresh impact** → write a new report. If the previous incident was fully resolved (impact ended, service restored to normal) and a *new* problem has since started, that is a separate incident even if the symptoms or affected systems look similar.

When in doubt, ask the team-lead before creating a fresh report — it is far easier to fold information into an existing report than to merge two later.

## Don't gate drafting or shipping on long-running verification

When verifying an incident's resolution takes meaningful time — multi-hour cron reruns, soak windows, estate-wide deploy propagation, post-failure data backfills, etc. — draft the report **and ship the PR** in parallel with the verification. Two principles:

- **Don't sit idle before drafting.** Almost everything that goes into the report (root cause, code-site references, fix description, timeline up to the verification trigger, the analysis sections) is already known once the fix is shipped.
- **Don't gate the PR on verification.** Durability of state-in-git matters more than the tidiness of a TBD-free first commit. Verification windows can outlast a work session; uncommitted draft material on disk does not survive a context loss, but pushed commits do.

The pattern:

1. Once the fix is shipped and verification is in flight, start drafting immediately.
2. Leave verification-result sections as clearly-marked TBDs. Examples:
   - In the timeline: `2026-04-28 HH:MM | Rerun completes — TBD pending result`
   - In the header table: `Duration | … — TBD pending verification`
   - In the summary: `Verified end-to-end with rerun — TBD pending rerun completion`
3. **Open the PR as soon as the draft is coherent** — default mode is a normal (non-draft) PR. List the outstanding TBDs in the PR body so reviewers know what's pending and a cold reader (e.g. you in a future session) can pick up the work. Use a *draft* PR only when the substantive content (root cause, fix description) is itself still uncertain — not merely because verification is pending.
4. As verification completes, fill in the TBDs:
   - **If the original PR is still open** (e.g. on a supervised repo where merge waits on a human): push follow-up commits to the same branch.
   - **If the original PR has already merged** (e.g. auto-merge repos like `lucos`, where reviewer-approval triggers immediate merge): open a fresh branch off latest main, fill in the TBDs, and open a follow-up PR. Reference the original PR in the body so the audit trail is intact. Drive the review loop on the new PR per `pr-review-loop.md`.
5. If verification surfaces a further failure mode (the incident isn't actually resolved yet), update the report via further commits to reflect the new chapter of the story. An explicit `TBD pending result` line is not a claim of success, so leaving it in place while waiting does not violate this — but once the result is known, do not retain a TBD that no longer reflects reality. The report is amendable: if anything else develops after merge, update it via a fresh PR.

Sitting idle until verification completes — or holding the PR back — wastes time and delays the team-lead's ability to confirm the incident is closed out. The TBD-and-fill-in pattern keeps work flowing and durable without misrepresenting state.

This rule applies equally to fresh reports and to extending an existing one.

## Propagate factual corrections through every narrative section

When a reviewer (lucas42, team-lead, code-reviewer, or any other source) supplies a factual correction during the drafting or review loop — especially one about *framing* (e.g. "this wasn't routine, it was X"; "the cause wasn't Y, it was Z"; "the trigger wasn't discretionary, it was instructed by W") — apply it to **every** narrative section that touches the corrected fact, not just the section the reviewer pointed at.

Why: the closest match to the reviewer's quote is rarely the only place where the original framing appeared. The Summary, Timeline (especially pre-incident rows), Analysis stages, "What Was Tried That Didn't Work," Sensitive Findings, and the PR description are all narrative surfaces. Most readers skim the Summary; a Summary that contradicts a deeper section is worse than either alone, because it creates visible incoherence and signals carelessness.

The pattern:

1. Re-read the reviewer's correction in full and identify the **fact** being corrected, not just the surface wording.
2. `grep` the file for the **original framing** — the wording you used before the correction — and any synonyms you might have varied (e.g. "routine," "maintenance," "scheduled," "hygiene," "automatic," "background," "incidental"). Don't rely on memory of where you wrote what; let `grep` find every occurrence.
3. For each match, decide whether the correction applies. If yes, rewrite that sentence/row to match the corrected framing. Update both the prose and any structured fields (timeline rows, header table) consistently.
4. **Re-read the Summary explicitly after the pass.** Even after a thorough grep, the Summary often retains residual phrasing (different word, same framing) that the grep didn't catch. The Summary is the most-read section; getting it consistent is the highest-leverage thing.
5. Push a single commit with the propagation pass and reference the corrector in the commit message ("per lucas42's correction" / "per team-lead's correction").
6. When reporting back to the corrector, **list every section you updated**, not just "I applied your correction" — that lets the corrector verify the propagation was complete without reading the diff.

This is independent of whether the original framing was yours or inherited from upstream sources (issue body, PR description, prior agent's notes). The propagation pass is about the report's coherence, not assigning blame.

## Step 1: Write the incident report

Given a closed critical issue that needs a report:

1. **Gather context**: Read the full issue body, all comments, and any linked PRs (check for `Closes #N` / `Fixes #N` references and PR cross-references in the timeline). Piece together the timeline, root cause, and resolution from the available information.

2. **Write the report**: Create a new file following the template at `docs/incidents/TEMPLATE.md`. The file naming convention is `YYYY-MM-DD-short-description.md`, where the date is the date of the incident (not today's date). Use lowercase words separated by hyphens for the description.

3. **Fill in the template** using information gathered from the issue and its linked PRs:
   - **Summary**: What happened, what the impact was, how it was resolved
   - **Timeline**: Reconstruct from issue timestamps, comments, and PR merge times
   - **Root cause**: Technical explanation drawn from the issue discussion
   - **Resolution**: The specific fix applied, referencing PRs/commits
   - **Follow-up actions**: Link to any open issues raised as a result. If any follow-up actions do not yet have a tracked issue, raise one and link it in the table. **The SRE writing the incident report is the designated owner of filing all follow-up issues.** Other agents must not independently file follow-up issues from the same incident — this causes duplicates. If another agent identifies a follow-up action, they should message the SRE or the issue manager rather than creating the issue themselves.
   - If information for a section is not available from the issue or its comments, say so explicitly (e.g. "Timeline details not available from the issue discussion") rather than inventing details

4. **Reference the source issue**: Include a link to the original critical issue near the top of the report (e.g. in the summary or as a metadata field) so there is a clear audit trail.

5. **Use fully-qualified cross-repo references.** Because incident reports live in the `lucos` repo, bare `#N` references resolve to `lucos` issues -- not the repo where the incident occurred. Always use the `lucas42/repo_name#N` format for issue and PR references (e.g. `lucas42/lucos_contacts#42`, not `#42`). This is the general rule from CLAUDE.md but is especially easy to get wrong in incident reports, where nearly every reference points to a different repo.

## Step 2: Raise a PR

Create a branch, commit the new incident report(s), and open a PR on the `lucos` repo:

```bash
cd ~/sandboxes/lucos
git checkout -b incident-report-{short-description}
~/sandboxes/lucos_agent/git-as-agent --app lucos-site-reliability \
    add docs/incidents/{filename}.md
~/sandboxes/lucos_agent/git-as-agent --app lucos-site-reliability \
    commit -m "Add incident report for {short description}

Refs lucas42/{repo}#{number}"
git push -u origin incident-report-{short-description}
```

Then create the PR via `gh-as-agent`:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-site-reliability repos/lucas42/lucos/pulls \
    --method POST \
    -f title="Add incident report: {short title}" \
    -f head="incident-report-{short-description}" \
    -f base="main" \
    --field body="$(cat <<'ENDBODY'
Adds an incident report for the {short description} incident.

Source issue: lucas42/{repo}#{number}

Written from issue body, comments, and linked PRs following `docs/incidents/TEMPLATE.md`.
ENDBODY
)"
```

If multiple critical issues need reports, include them all in a single PR with a commit per report.

After opening the PR, follow the PR review loop defined in `pr-review-loop.md` -- message the `lucos-code-reviewer` teammate and drive the review to completion before reporting back.

## Step 3: Notify the team after merge

Once the incident report PR is merged or closed, send a notification to every other teammate with a link to the report so they can learn from the outcomes.

**There is no broadcast mechanism in SendMessage.** Setting `to: "broadcast"` puts the message into a phantom inbox no agent reads — it does not multiplex. The only structured message types are `shutdown_request`, `shutdown_response`, and `plan_approval_response`. To reach the whole team, send **individual SendMessage calls**, one per teammate. You can issue all of them in a single response (parallel tool calls).

Recipients (excluding yourself):

- lucos-architect
- lucos-code-reviewer
- lucos-developer
- lucos-security
- lucos-system-administrator
- lucos-ux

Suggested content (same for each recipient):

```
Incident report published: docs/incidents/{filename}.md
Source issue: https://github.com/lucas42/{repo}/issues/{number}
Summary: {one-line summary of what happened and the root cause}
Lessons: {bullet list of the load-bearing lessons most likely to affect future work}
Read the full report at: https://github.com/lucas42/lucos/blob/main/docs/incidents/{filename}.md
```

This ensures every agent — architect, code-reviewer, developer, security, sysadmin, ux — can absorb lessons learned and update their own memory or practices as needed.

## Completion checklist

The incident report is delivered when ALL of the following are true. Reporting back to the dispatcher before all four are true is incomplete; do not substitute an outcomes-style "Done" summary that omits any step.

- [ ] Report written following `docs/incidents/TEMPLATE.md` (Step 1)
- [ ] Follow-up issues filed and linked in the report's Follow-up Actions table (Step 1, item 3)
- [ ] PR raised, reviewed, and merged (Step 2)
- [ ] Individual notification messages sent to every other teammate (Step 3 — six messages, not one "broadcast")

### Mandatory completion-report format

Before reporting back to the dispatcher (team-lead or user) that the incident report is delivered, **the completion message must restate each of the four checklist items verbatim, each annotated `done` or `not done`**. This is a forcing function: composing the message exposes any item that isn't actually true.

Example completion-report fragment:

> **Incident report completion checklist:**
> - [x] Report written following `docs/incidents/TEMPLATE.md` — done (`docs/incidents/2026-05-18-…md`)
> - [x] Follow-up issues filed and linked — done (`lucas42/lucos_arachne#544` in Follow-up Actions table)
> - [x] PR raised, reviewed, and merged — done (`lucas42/lucos#161`, merged HH:MMZ)
> - [x] Individual notifications sent to every other teammate — done (architect, code-reviewer, developer, security, system-administrator, ux — six messages)

If any item is `not done`, the completion report is premature; **do not send it**. Continue the work (drive the review loop, send the notifications) and report back only once all four are `done`. A partial-progress update is fine and welcome — but it must clearly say "in progress" and list which items remain, not "done" / "no outstanding actions".
