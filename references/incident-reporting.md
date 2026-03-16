# Incident Reporting

This document defines the process for writing incident reports for resolved critical incidents. Incident reports live in `docs/incidents/` in the `lucos` repo.

## When to write an incident report

Every resolved critical incident (`priority:critical`) deserves a post-mortem. They are how the team learns and prevents recurrence.

## Step 1: Find recently closed critical issues

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-site-reliability \
  "search/issues?q=org:lucas42+is:issue+is:closed+label:priority:critical+sort:updated-desc&per_page=20"
```

## Step 2: Check for existing incident reports

For each closed critical issue, check whether an incident report already exists in the `lucos` repo at `docs/incidents/`. Search by looking for the issue URL or issue title in existing reports:

```bash
# List existing incident reports
ls ~/sandboxes/lucos/docs/incidents/*.md

# Search for references to the issue URL or repo+number in existing reports
grep -rl "lucas42/{repo}/issues/{number}" ~/sandboxes/lucos/docs/incidents/
```

If a matching incident report already exists, skip that issue -- no action needed.

## Step 3: Write the incident report

For each critical issue that has no corresponding incident report:

1. **Gather context**: Read the full issue body, all comments, and any linked PRs (check for `Closes #N` / `Fixes #N` references and PR cross-references in the timeline). Piece together the timeline, root cause, and resolution from the available information.

2. **Write the report**: Create a new file following the template at `docs/incidents/TEMPLATE.md`. The file naming convention is `YYYY-MM-DD-short-description.md`, where the date is the date of the incident (not today's date). Use lowercase words separated by hyphens for the description.

3. **Fill in the template** using information gathered from the issue and its linked PRs:
   - **Summary**: What happened, what the impact was, how it was resolved
   - **Timeline**: Reconstruct from issue timestamps, comments, and PR merge times
   - **Root cause**: Technical explanation drawn from the issue discussion
   - **Resolution**: The specific fix applied, referencing PRs/commits
   - **Follow-up actions**: Link to any open issues raised as a result. If any follow-up actions do not yet have a tracked issue, raise one and link it in the table
   - If information for a section is not available from the issue or its comments, say so explicitly (e.g. "Timeline details not available from the issue discussion") rather than inventing details

4. **Reference the source issue**: Include a link to the original critical issue near the top of the report (e.g. in the summary or as a metadata field) so there is a clear audit trail.

5. **Use fully-qualified cross-repo references.** Because incident reports live in the `lucos` repo, bare `#N` references resolve to `lucos` issues -- not the repo where the incident occurred. Always use the `lucas42/repo_name#N` format for issue and PR references (e.g. `lucas42/lucos_contacts#42`, not `#42`). This is the general rule from CLAUDE.md but is especially easy to get wrong in incident reports, where nearly every reference points to a different repo.

## Step 4: Raise a PR

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

## Step 5: Notify the team after merge

Once the incident report PR is merged or closed, broadcast a notification to all teammates with a link to the report so they can learn from the outcomes:

```
SendMessage (type: broadcast):
  "Incident report published: docs/incidents/{filename}.md
   Source issue: https://github.com/lucas42/{repo}/issues/{number}
   Summary: {one-line summary of what happened and the root cause}
   Read the full report at: https://github.com/lucas42/lucos/blob/main/docs/incidents/{filename}.md"
```

This ensures all agents -- architect, developer, sysadmin, security, and issue manager -- can absorb lessons learned and update their own memory or practices as needed. Use `broadcast` for this notification since incident learnings are relevant to the entire team.
