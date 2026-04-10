# SRE Ops Checks

**7 checks total — you MUST run all 7. See the completion manifest at the bottom.**

Check your ops-checks memory file (`ops-checks.md`) at the start of each run to determine which checks are due. Update it after each check. If a check is skipped because it is not yet due, note this explicitly in your output.

**Investigate before filing.** When you discover a problem during ops checks, do not file an issue with a hypothesis and "suggested investigation" steps. Instead, do the investigation yourself — SSH in, check logs, inspect config, test connectivity, whatever it takes to identify the root cause. If the investigation requires expertise outside your domain (e.g. application code changes, architectural decisions), ask the relevant teammate to investigate and report back before filing. The issue you file should contain a clear diagnosis with evidence, not a list of things someone else should try. If the fix is trivial (e.g. a config typo, a missing alias), go ahead and fix it or ask the appropriate teammate to fix it. Otherwise, ensure the issue contains enough detail that whoever picks it up can start implementing immediately with no further investigation needed.

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

## Every Run (3 checks)

### Check 1: Monitoring API

Fetch `https://monitoring.l42.eu/api/status` and inspect the response.

- Look at individual check details, not just the top-level `healthy` boolean
- Pay attention to the `unknown` count — a service that can't be reached is a potential incident, not just a gap
- Cross-reference any failures against your memory for known false negatives before raising a new issue

**Action required on failures.** Reporting "all healthy" or listing failures in a summary table is not sufficient. When any check is failing, unhealthy, or unknown, you MUST:

1. **Investigate the root cause.** SSH into the relevant host, check container logs, inspect the environment, and determine why the check is failing. A monitoring check that reports failure is a symptom — your job is to find the cause.
2. **Raise or update a GitHub issue.** If no open issue covers the problem, raise one with the root cause, impact, and suggested fix. If an existing issue already covers it, comment with any new findings.
3. **Escalate priority if needed.** If the failure represents an active outage or data risk (e.g. backups not running, a service completely down), message `team-lead` to request `priority:high` or `priority:critical` on the issue. Do not leave active failures at default priority.
4. **Attempt immediate remediation for service-down scenarios.** If a service is down and a restart could restore it, try `docker compose restart <service>` on the production host before raising the issue.
5. **For CI failures: manually re-run the failed workflows.** CI failures do NOT self-heal unless something triggers a new run (a commit, a schedule, or a manual re-run). Do not assume self-healing will occur. You MUST: (a) fetch the most recent failed workflow ID for each affected repo, (b) message `lucos-system-administrator` to trigger re-runs via the CircleCI v2 API (`POST /api/v2/workflow/{id}/rerun` with `{"from_failed": true}`), and (c) confirm in your report that re-runs have been triggered. **A CI failure is not resolved until CI is green — documenting the root cause is necessary but not sufficient.**

A monitoring check that has been failing for days without investigation or escalation is a process failure. The purpose of ops checks is to catch and act on problems — not to passively observe them.

**Never dismiss failures as "transient" without detail.** When reporting unhealthy or unknown systems, always include:
- The specific system names that are alerting
- The root cause of each failure (not just "transient" or "rate limit")
- What will cause the alert to clear (e.g. "the next audit sweep will re-populate the cache", "the rate limit resets at HH:MM")
- When that is expected to happen (a concrete time or timeframe, not "should self-heal")

"Transient" is not an explanation — it's a prediction that the problem will go away on its own. State what the problem is, why you believe it will resolve, and when. If you don't know when, that's worth saying explicitly.

---

### Check 2: Loganne Alert History

Fetch recent Loganne events and look for flappy or persistent monitoring alerts that warrant investigation.

```bash
source ~/sandboxes/lucos_agent/.env && KEY=$(grep KEY_LUCOS_LOGANNE ~/sandboxes/lucos_agent/.env | cut -d'"' -f2) && curl -s -H "Authorization: Bearer $KEY" "https://loganne.l42.eu/events?limit=50"
```

Filter the results to events where `source == "lucos_monitoring"`. Look back over the last 24 hours (or since the last ops check run).

#### What to look for

**Flappy alerts** — a system that has fired multiple `monitoringAlert` / `monitoringRecovery` cycles in a short period. More than 2–3 oscillations within a few hours is worth investigating. Flappy systems may indicate:
- An intermittent dependency (network, upstream service)
- A service with a fragile healthcheck or tight timeout
- A resource exhaustion cycle (OOM → restart → recover → repeat)

**Persistent alerts** — a system with a `monitoringAlert` event and no subsequent `monitoringRecovery`. These may represent an ongoing failure that Check 1 (Monitoring API) should already surface, but the Loganne history provides context on how long the system has been failing.

#### Action

For any flappy or persistent alert not already covered by a known open issue:
1. Check for an existing issue using the duplicate prevention queries above
2. If none exists, raise a GitHub issue on the relevant repo with: the system name, the alert pattern observed (timestamps, number of cycles), and the risk if left unaddressed
3. If the pattern suggests a systemic reliability problem, flag for deeper investigation

---

### Check 3: Incident Report Coverage

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

#### Step 3: Write reports for uncovered issues

For each critical issue that has no corresponding incident report, follow the process in [`references/incident-reporting.md`](../references/incident-reporting.md) to write the report, raise a PR, and notify the team after merge.

---

## Rotating (1 check — run every time, covering 3-5 containers per run)

### Check 4: Container Log Review

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

### Check 5: CI Status

Scan for repos where CI has been red for an extended period (more than a few days). A repo with persistently failing CI is a reliability risk — broken CI means unreviewed changes and delayed deployments.

Check `ops-checks.md` for `ci_status` last_run date; skip if less than a month ago.

```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-site-reliability \
  "orgs/lucas42/repos?per_page=50"
```

Then check recent CircleCI status for repos that look active. Raise a P3 issue for any repo with CI red for more than a week.

After completing, update `ci_status` in `ops-checks.md` with today's date.

---

### Check 6: `/_info` Endpoint Quality

Hit `/_info` directly on each monitored service to verify the response is well-formed and contains the expected fields (`system`, `checks`, `metrics`, `ci`, `title`, etc.).

Check `ops-checks.md` for `info_endpoint_quality` last_run date; skip if less than a month ago.

Services to check are listed in the monitoring API response (`monitoring.l42.eu/api/status`). For each system hostname, fetch `https://<hostname>/_info` and verify the JSON structure matches the expected schema.

Raise a P3 issue for any service with a malformed or missing `/_info` response.

After completing, update `info_endpoint_quality` in `ops-checks.md` with today's date.

---

### Check 7: External Dependency Health

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
| 2. Loganne Alert History | Done | N monitoring events reviewed, N flappy/persistent alerts found |
| 3. Incident Report Coverage | Done / Skipped (not due) | N critical issues checked, N reports needed |
| 4. Container Log Review | Done | N containers reviewed: name1, name2, ... |
| 5. CI Status | Done / Skipped (not due) | — |
| 6. `/_info` Endpoint Quality | Done / Skipped (not due) | — |
| 7. External Dependency Health | Done / Skipped (not due) | — |

**Do not skip any row in this table.** If a check was not run, say why ("not due — last run YYYY-MM-DD"). This table is the audit trail that confirms all 7 checks were considered.
