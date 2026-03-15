# SRE Ops Checks

**6 checks total — you MUST run all 6. See the completion manifest at the bottom.**

Check your ops-checks memory file (`ops-checks.md`) at the start of each run to determine which checks are due. Update it after each check. If a check is skipped because it is not yet due, note this explicitly in your output.

**Duplicate prevention**: Before raising any issue, always search for existing open issues in the target repo that cover the same problem. Also check your memory for known issues or previously flagged findings:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-site-reliability \
  "search/issues?q=repo:lucas42/{repo}+is:issue+is:open+{search_terms}"
```

If you find an existing issue that covers the same root cause, comment on that issue with any new information rather than filing a duplicate. Also scan the 10 most recent open issues in the target repo to catch issues filed by other agents using different terminology:

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-site-reliability \
  "search/issues?q=repo:lucas42/{repo}+is:issue+is:open+sort:created-desc&per_page=10"
```

---

## Every Run (2 checks)

### Check 1: Monitoring API

Fetch `https://monitoring.l42.eu/api/status` and inspect the response.

- Look at individual check details, not just the top-level `healthy` boolean
- Pay attention to the `unknown` count — a service that can't be reached is a potential incident, not just a gap
- Cross-reference any failures against your memory for known false negatives before raising a new issue

**Action required on failures.** Reporting "all healthy" or listing failures in a summary table is not sufficient. When any check is failing, unhealthy, or unknown, you MUST:

1. **Investigate the root cause.** SSH into the relevant host, check container logs, inspect the environment, and determine why the check is failing. A monitoring check that reports failure is a symptom — your job is to find the cause.
2. **Raise or update a GitHub issue.** If no open issue covers the problem, raise one with the root cause, impact, and suggested fix. If an existing issue already covers it, comment with any new findings.
3. **Escalate priority if needed.** If the failure represents an active outage or data risk (e.g. backups not running, a service completely down), message `lucos-issue-manager` to request `priority:high` or `priority:critical` on the issue. Do not leave active failures at default priority.
4. **Attempt immediate remediation for service-down scenarios.** If a service is down and a restart could restore it, try `docker compose restart <service>` on the production host before raising the issue.

A monitoring check that has been failing for days without investigation or escalation is a process failure. The purpose of ops checks is to catch and act on problems — not to passively observe them.

---

### Check 2: Incident Report Coverage

Verify that every resolved critical incident has a corresponding incident report in the `lucos` repo. Critical incidents deserve post-mortems — they are how the team learns and prevents recurrence.

#### Step 1: Find recently closed critical issues

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-site-reliability \
  "search/issues?q=org:lucas42+is:issue+is:closed+label:priority:critical+sort:updated-desc&per_page=20"
```

#### Step 2: Check for existing incident reports

For each closed critical issue, check whether an incident report already exists in the `lucos` repo at `docs/incidents/`. Search by looking for the issue URL or issue title in existing reports:

```bash
# List existing incident reports
ls ~/sandboxes/lucos/docs/incidents/*.md

# Search for references to the issue URL or repo+number in existing reports
grep -rl "lucas42/{repo}/issues/{number}" ~/sandboxes/lucos/docs/incidents/
```

If a matching incident report already exists, skip that issue — no action needed.

#### Step 3: Write the incident report

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

5. **Use fully-qualified cross-repo references.** Because incident reports live in the `lucos` repo, bare `#N` references resolve to `lucos` issues — not the repo where the incident occurred. Always use the `lucas42/repo_name#N` format for issue and PR references (e.g. `lucas42/lucos_contacts#42`, not `#42`). This is the general rule from CLAUDE.md but is especially easy to get wrong in incident reports, where nearly every reference points to a different repo.

#### Step 4: Raise a PR

Create a branch, commit the new incident report(s), and open a PR on the `lucos` repo:

```bash
cd ~/sandboxes/lucos
git checkout -b incident-report-{short-description}
git -c user.name="lucos-site-reliability[bot]" \
    -c user.email="264646982+lucos-site-reliability[bot]@users.noreply.github.com" \
    add docs/incidents/{filename}.md
git -c user.name="lucos-site-reliability[bot]" \
    -c user.email="264646982+lucos-site-reliability[bot]@users.noreply.github.com" \
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

After opening the PR, follow the PR review loop defined in `pr-review-loop.md` — message the `lucos-code-reviewer` teammate and drive the review to completion before reporting back.

---

## Rotating (1 check — run every time, covering 3-5 containers per run)

### Check 3: Container Log Review

SSH into production hosts and review logs for a rotating selection of containers. Track in `ops-checks.md` when each container was last reviewed so you cover them all over time.

**Before selecting containers:**
1. List all running containers on the production host
2. Compare against tracking data in `ops-checks.md`
3. Prioritise containers with the oldest `last_reviewed` date
4. Any container not reviewed in 60+ days: flag explicitly in your output as **overdue**
5. Any container not reviewed in 30+ days: prioritise in this run's selection
6. New containers (not yet in tracking data): review on their first or second rotation

Aim to review **3-5 containers per run**.

Lookback window: review logs since the last time you reviewed that container (check `ops-checks.md`).

```bash
ssh avalon "docker logs --since <last-reviewed-timestamp> <container_name> 2>&1 | tail -200"
```

Focus on:
- Stack traces and unhandled exceptions
- Repeated error patterns (especially ones accelerating over time)
- Misconfiguration warnings (e.g. missing env vars, failed connections at startup)

This is complementary to sysadmin crash detection — you're looking at logs in *running* containers, not just crash reports.

After reviewing, update `ops-checks.md` with the date for each container you checked, using format `container_name: YYYY-MM-DD`.

---

## Monthly (3 checks)

### Check 4: CI Status

Scan for repos where CI has been red for an extended period (more than a few days). A repo with persistently failing CI is a reliability risk — broken CI means unreviewed changes and delayed deployments.

Check `ops-checks.md` for `ci_status` last_run date; skip if less than a month ago.

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-site-reliability \
  "orgs/lucas42/repos?per_page=50"
```

Then check recent CircleCI status for repos that look active. Raise a P3 issue for any repo with CI red for more than a week.

After completing, update `ci_status` in `ops-checks.md` with today's date.

---

### Check 5: `/_info` Endpoint Quality

Hit `/_info` directly on each monitored service to verify the response is well-formed and contains the expected fields (`system`, `checks`, `metrics`, `ci`, `title`, etc.).

Check `ops-checks.md` for `info_endpoint_quality` last_run date; skip if less than a month ago.

Services to check are listed in the monitoring API response (`monitoring.l42.eu/api/status`). For each system hostname, fetch `https://<hostname>/_info` and verify the JSON structure matches the expected schema.

Raise a P3 issue for any service with a malformed or missing `/_info` response.

After completing, update `info_endpoint_quality` in `ops-checks.md` with today's date.

---

### Check 6: External Dependency Health

Verify reachability of external services that lucos depends on but does not control.

Check `ops-checks.md` for `external_deps` last_run date; skip if less than a month ago.

```bash
# Let's Encrypt — expect 200
curl -s -o /dev/null -w "%{http_code}" https://acme-v02.api.letsencrypt.org/directory

# Docker Hub — expect 401 (unauthenticated but reachable)
curl -s -o /dev/null -w "%{http_code}" https://registry.hub.docker.com/v2/

# CircleCI — expect 401 (reachable)
curl -s -o /dev/null -w "%{http_code}" https://circleci.com/api/v2/me

# GitHub API — expect 200
curl -s -o /dev/null -w "%{http_code}" https://api.github.com/zen
```

Only raise a P3 issue if a dependency appears genuinely degraded or its API has changed in a way that could affect lucos operations. A transient non-200 on a single run is not worth escalating.

After completing, update `external_deps` in `ops-checks.md` with today's date.

---

## Completion Manifest

After completing your ops checks run, output a table like this:

| Check | Status | Notes |
|---|---|---|
| 1. Monitoring API | Done / Skipped (not due) | Brief finding or "all healthy" |
| 2. Incident Report Coverage | Done / Skipped (not due) | N critical issues checked, N reports needed |
| 3. Container Log Review | Done | N containers reviewed: name1, name2, ... |
| 4. CI Status | Done / Skipped (not due) | — |
| 5. `/_info` Endpoint Quality | Done / Skipped (not due) | — |
| 6. External Dependency Health | Done / Skipped (not due) | — |

**Do not skip any row in this table.** If a check was not run, say why ("not due — last run YYYY-MM-DD"). This table is the audit trail that confirms all 6 checks were considered.
