# Incident Reporting

This document defines the process for writing an incident report for a specific resolved critical incident. Incident reports live in `docs/incidents/` in the `lucos` repo.

Use this process when you have identified a critical issue that needs a report -- whether during ops checks (Check 2: Incident Report Coverage) or when asked to write a report ad-hoc.

## Extend an existing report, or write a new one?

Before writing a new report, check whether the incident you are about to document is actually a *continuation* of an existing one. The rule:

- **Ongoing impact** → extend the existing report. If the user-visible impact (e.g. "no backups are running", "service is down", "data is stale") has not yet been resolved, and a new failure is just the next chapter of the same story, append to the existing report rather than creating a new one. Add a new section to the timeline, document the second failure mode, and update the resolution / follow-up sections.
- **Fresh impact** → write a new report. If the previous incident was fully resolved (impact ended, service restored to normal) and a *new* problem has since started, that is a separate incident even if the symptoms or affected systems look similar.

When in doubt, ask the team-lead before creating a fresh report — it is far easier to fold information into an existing report than to merge two later.

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

Once the incident report PR is merged or closed, broadcast a notification to all teammates with a link to the report so they can learn from the outcomes:

```
SendMessage (type: broadcast):
  "Incident report published: docs/incidents/{filename}.md
   Source issue: https://github.com/lucas42/{repo}/issues/{number}
   Summary: {one-line summary of what happened and the root cause}
   Read the full report at: https://github.com/lucas42/lucos/blob/main/docs/incidents/{filename}.md"
```

This ensures all agents -- architect, developer, sysadmin, security, and issue manager -- can absorb lessons learned and update their own memory or practices as needed. Use `broadcast` for this notification since incident learnings are relevant to the entire team.
