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
3. **Escalate priority if needed.** If the failure represents an active outage or data risk (e.g. backups not running, a service completely down), message `team-lead` to request Priority = High or Critical on the issue. Do not leave active failures at default priority.
4. **Attempt immediate remediation for service-down scenarios.** If a service is down and a restart could restore it, try `docker compose restart <service>` on the production host before raising the issue.
5. **For CI failures: manually re-run the failed workflows directly.** CI failures do NOT self-heal unless something triggers a new run (a commit, a schedule, or a manual re-run). Do not assume self-healing will occur. You MUST: (a) fetch the most recent failed workflow ID for each affected repo, (b) trigger re-runs yourself via the CircleCI v2 API using the user-scoped token documented in `~/.claude/agents/sre-circleci-api.md` (`POST /api/v2/workflow/{id}/rerun` with `{"from_failed": true}`), and (c) confirm in your report that re-runs have been triggered. CircleCI re-runs are in your domain directly — no sysadmin hop required. **A CI failure is not resolved until CI is green — documenting the root cause is necessary but not sufficient.** If you see `Permission denied`, first sanity-check the token via `/api/v2/me` — the likely cause is an empty `$TOKEN` from grepping the wrong env var name (should be `CIRCLECI_API_TOKEN`, not `KEY_CIRCLECI`).

A monitoring check that has been failing for days without investigation or escalation is a process failure. The purpose of ops checks is to catch and act on problems — not to passively observe them.

**Never dismiss failures as "transient" without detail.** When reporting unhealthy or unknown systems, always include:
- The specific system names that are alerting
- The root cause of each failure (not just "transient" or "rate limit")
- What will cause the alert to clear (e.g. "the next audit sweep will re-populate the cache", "the rate limit resets at HH:MM")
- When that is expected to happen (a concrete time or timeframe, not "should self-heal")

"Transient" is not an explanation — it's a prediction that the problem will go away on its own. State what the problem is, why you believe it will resolve, and when. If you don't know when, that's worth saying explicitly.

**Never report a check as green, resolved, or clear without verifying by querying the actual source of truth (the monitoring dashboard, the CircleCI API, etc.) immediately before reporting.** Predicted state is not verified state. If you have taken actions that should result in a check going green, wait for the action to complete, then query the dashboard and report what the dashboard actually shows — including any additional failures the dashboard reports, not just the ones you were addressing. A system is not resolved until the monitoring API says it is.

---

### Check 2: Loganne Alert History

Fetch recent Loganne events and look for flappy or persistent monitoring alerts that warrant investigation.

```bash
source ~/sandboxes/lucos_agent/.env && KEY=$(grep KEY_LUCOS_LOGANNE ~/sandboxes/lucos_agent/.env | cut -d'"' -f2) && curl -s -H "Authorization: Bearer $KEY" "https://loganne.l42.eu/events?limit=50"
```

Filter the results to events where `source == "lucos_monitoring"`. Look back over the last 24 hours (or since the last ops check run).

#### What to look for

**Flappy alerts** — a system that has fired any `monitoringAlert` / `monitoringRecovery` cycle. Even a single short flap is signal: it produced an alert, which means it crossed the threshold the monitoring system uses to wake people up. Repeated flaps amplify the problem; isolated flaps still represent a fragile check or a real (but brief) failure that wants explaining.

Flappy systems may indicate:
- An intermittent dependency (network, upstream service)
- A service with a fragile healthcheck or tight timeout
- A resource exhaustion cycle (OOM → restart → recover → repeat)
- A check that fires during a known-acceptable window (e.g. a dependency's deploy) without using the suppression tools provided

**Persistent alerts** — a system with a `monitoringAlert` event and no subsequent `monitoringRecovery`. These may represent an ongoing failure that Check 1 (Monitoring API) should already surface, but the Loganne history provides context on how long the system has been failing.

#### Do not accept flaps as "expected" or "known pattern"

If a flap is acceptable (i.e. the underlying condition is benign and we don't want to wake anyone up for it), then it must be **suppressed using the available tools** — not tolerated as noise. The lucos monitoring service supports several mechanisms:

- **Deploy-window suppression** — alerts on a system are suppressed while that system is being deployed. Already on by default for the deploying system itself.
- **`dependsOn` on checks** — a check declared as `dependsOn: <other_system>` is suppressed when the depended-on system is in its deploy window. This is the right fix for cross-service probes that flap during dependency deploys (e.g. weightings probing media-api during a media-api deploy). Check is declared in the service's own `/_info` payload alongside `techDetail` and `ok`.
- **`failThreshold` per check** — number of consecutive failed polls required before a check goes unhealthy. Use this to ride out tight-timeout transients. Default is 1; bump to 2+ for checks with sub-second timeouts that occasionally lose a race. Declared in `/_info` alongside the check.
- **Warm-up alert skipping** — `lucos_monitoring` skips alerts on the first poll after its own restart, so its cold-state cache misses don't cascade.

If you find a flap and conclude it's a class of failure that's *acceptable*, the response is to **use one of the tools above to suppress it**, not to write it off as known. If there's no tool that fits the situation, **raise a ticket on `lucos_monitoring`** describing the pattern and proposing a new mechanism (or extension to an existing one). "We've seen this before" is not a disposition.

#### Action

For every flap (any monitoringAlert/Recovery cycle) and every persistent alert in the lookback window:

1. Check for an existing open issue on the affected service or `lucos_monitoring` covering the same root cause; comment with new data if so, otherwise file new.
2. **Diagnose the root cause** — SSH in, read logs, inspect timing against deploy events. If you can't diagnose because logs were rotated or the container has been replaced, **the next step is to add more logs** (file a small issue on the affected service requesting diagnostic log lines around the failing check). Don't shrug and move on.
3. **Pick a remediation** from the tools above and either fix it directly (it's usually a small `/_info` payload change) or file an issue with a precise proposal. If none of the tools fit, file an issue on `lucos_monitoring` proposing the missing mechanism.
4. If the pattern suggests a systemic reliability problem (cascade, resource exhaustion, recurring deploy-side breakage), escalate the priority and flag for deeper investigation.

A flap that recurs across ops-check runs without progress is itself a process failure — note it explicitly in the completion manifest if you're seeing the same pattern you saw last time.

---

### Check 3: Incident Report Coverage

Verify that every significant resolved incident has a corresponding incident report in the `lucos` repo. Significant incidents deserve post-mortems — they are how the team learns and prevents recurrence.

**Signal source: Loganne, not the project board.** The previous version of this check queried the GitHub Projects v2 board for items with Priority = Critical and state = CLOSED. That doesn't work: the board is configured to auto-remove items once they're marked Done, so the query returns zero closed items regardless of how many critical incidents we've had. We use Loganne's `monitoringAlert` / `monitoringRecovery` history instead — it captures *what actually went wrong in production*, which is a better backing-truth than *what someone happened to label as Critical*. Incident reporting at resolution time (per [`references/incident-reporting.md`](../references/incident-reporting.md)) is the primary mechanism; this check is the safety net.

#### Step 1: Find recent significant outages from Loganne

Fetch monitoring events over the past 30 days and pair `monitoringAlert` → `monitoringRecovery` per affected system. Outages lasting longer than 30 minutes are the threshold for "worth a closer look" — adjust if you're seeing too many or too few candidates. Shorter alert/recovery cycles are almost always deploy-window blips or single-poll glitches and don't need post-mortems.

```bash
source ~/sandboxes/lucos_agent/.env && KEY=$(grep KEY_LUCOS_LOGANNE ~/sandboxes/lucos_agent/.env | cut -d'"' -f2)
curl -s -H "Authorization: Bearer $KEY" "https://loganne.l42.eu/events?limit=2000" | python3 -c "
import json, sys
from datetime import datetime, timezone, timedelta
from collections import defaultdict

data = json.load(sys.stdin)
events = data.get('events', data) if isinstance(data, dict) else data
if isinstance(events, dict): events = events.get('events', [])

cutoff = datetime.now(timezone.utc) - timedelta(days=30)
threshold = timedelta(minutes=30)

per_system = defaultdict(list)
for e in events:
    t = e.get('type')
    if t not in ('monitoringAlert', 'monitoringRecovery'): continue
    try:
        ts = datetime.fromisoformat((e.get('date') or e.get('time') or '').replace('Z', '+00:00'))
    except: continue
    if ts < cutoff: continue
    hr = e.get('humanReadable', '')
    # 'N failing check(s) on lucos X (host)' or 'All checks healthy on lucos X (host)'
    if ' on ' in hr:
        sysname = hr.split(' on ', 1)[1].split(' (', 1)[0].strip()
        # Loganne renders the system display name with spaces; normalise back to
        # the underscore form used by repo/container names (e.g. lucos_loganne).
        sysname = sysname.replace(' ', '_')
    else:
        continue
    per_system[sysname].append((ts, t, hr))

print(f'Outages >{int(threshold.total_seconds()/60)} minutes in last 30 days:')
for system, evs in sorted(per_system.items()):
    evs.sort()
    last_alert = None
    for ts, t, hr in evs:
        if t == 'monitoringAlert':
            last_alert = ts
        elif t == 'monitoringRecovery' and last_alert:
            dur = ts - last_alert
            if dur > threshold:
                print(f'  {ts.strftime(\"%Y-%m-%d\")} {system}: {dur} (alert {last_alert.strftime(\"%H:%M\")}Z -> recovery {ts.strftime(\"%H:%M\")}Z)')
            last_alert = None
    if last_alert is not None and (datetime.now(timezone.utc) - last_alert) > threshold:
        print(f'  {last_alert.strftime(\"%Y-%m-%d\")} {system}: UNRECOVERED alert (started {last_alert.strftime(\"%H:%M\")}Z) — check Loganne directly')
"
```

Note: monitoringAlertSuppressed events (deploy-window suppression) are intentionally excluded — they're not real outages. If you suspect a long outage during a planned deploy, check Loganne directly with a wider event-type filter.

#### Step 2: Check for existing incident reports

For each outage from step 1, check whether an incident report in the `lucos` repo at `docs/incidents/` mentions the affected system around that date.

**Refresh the local checkout first.** `~/sandboxes/lucos` is frequently several commits behind `origin/main`, so a raw `ls` of the local `docs/incidents/` can report a report as missing when it was merged hours ago — leading you to write a duplicate. Always pull (or query GitHub) before trusting the listing:

```bash
git -C ~/sandboxes/lucos pull --ff-only -q   # or: gh-as-agent ... "repos/lucas42/lucos/contents/docs/incidents"
ls ~/sandboxes/lucos/docs/incidents/*.md

# Find reports mentioning a specific system
grep -ril "<system_name>" ~/sandboxes/lucos/docs/incidents/

# Or filter by date in the filename (incident reports follow YYYY-MM-DD-summary.md)
ls ~/sandboxes/lucos/docs/incidents/2026-05-*.md
```

If a matching report already covers the outage, skip — no action needed.

#### Step 3: Judge each uncovered outage before writing

Not every >30-minute outage warrants a full post-mortem. Apply judgement:

- **Always write a report** for: user-visible service degradation, data loss or corruption risk, external impact (e.g. a service that integrations depend on going down), and any incident where the team learned something non-obvious from the resolution.
- **Probably skip** for: internal-only event-bus delays that self-cleared (e.g. webhook-delivery backlog that drained on its own), single-check transients on a non-critical scheduled job, and outages whose root cause is "we already had an incident report for this exact pattern last week."
- **If unsure, write a brief one.** Even a short report — root cause, fix, timeline — is better than no record.

For each that does need a report, follow [`references/incident-reporting.md`](../references/incident-reporting.md) to draft, raise a PR, and notify the team after merge.

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
