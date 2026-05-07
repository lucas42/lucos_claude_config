# Sysadmin Ops Checks

**9 checks total — you MUST run all 9. See the completion manifest at the bottom.**

Check `ops-checks.md` in your agent memory at the start of each run to determine which checks are due. Update it after each check. If a check is skipped because it is not yet due, note this explicitly in your output so the dispatcher can see what was and wasn't run.

**Active hosts**: Read `~/sandboxes/lucos_configy/config/hosts.yaml` to get the list of hosts. Skip any with `active: false`.

**Salvare connectivity**: `salvare.s.l42.eu` is IPv6-only (AAAA record, no A record). The agent VM does not have IPv6 (vzNAT is IPv4-only), so direct SSH to `salvare.s.l42.eu` will always fail with "No address associated with hostname". This is not a DNS incident — it is expected. Always connect to salvare via xwing as a jump host: `ssh -J xwing.s.l42.eu salvare.s.l42.eu`. Do not report a failed DNS lookup for salvare as a finding.

**Always check, never assume.** Every ops check must be based on what you observe *right now*, not on what failed in a previous session. If a host was unreachable last time, try it again — the problem may have been fixed. When reporting findings, clearly distinguish between "I checked and it failed" vs "I did not check". Never report a stale assumption as a current finding.

**Scope boundary**: Ops checks are observation, hygiene, and issue-raising. Active incident response belongs to lucos-site-reliability. If something is critically broken (service down, data at risk), flag it for the dispatcher to invoke SRE — do not attempt to fix it yourself.

**Duplicate prevention**: Before raising any issue, always search for existing open issues:
```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-system-administrator \
  "search/issues?q=repo:lucas42/{repo}+is:issue+is:open+{search_terms}"
```

Also scan the 10 most recent open issues in the target repo to catch issues filed by other agents using different terminology:
```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-system-administrator \
  "search/issues?q=repo:lucas42/{repo}+is:issue+is:open+sort:created-desc&per_page=10"
```
If you find an existing issue that covers the same root cause, comment on that issue with any new information rather than filing a duplicate.

**Triage approach**:
- Trivial fix, no downtime risk: fix immediately and note it in `ops-checks.md`
- Bigger problem, or preventive measure: raise a GitHub issue on the appropriate repo
- Critical / service at risk: flag for the dispatcher to invoke `lucos-site-reliability`

When raising issues, include: which host(s) affected, what was observed, when it was first noticed, and what the risk is if left unaddressed.

**Issue lifecycle — closing issues**: When you confirm during an ops check that a previously tracked issue has been resolved and the fix is verified (e.g. a previously unhealthy container is now healthy, a previously failing service is now working), post a closing comment summarising what was fixed and close the issue. Do not leave issues open after you have verified the fix is in place. This applies both to issues you raised yourself and to issues raised by other agents that you can confirm are resolved.

---

## Every Run (1 check)

### Check 1: Container Status

SSH into each active host and run **two** commands — one for crashed containers, one for unhealthy containers (both can have problems; unhealthy containers still show "Up" so the first command misses them):

```bash
# Crashed/stopped containers
ssh <host> "docker ps -a --format 'table {{.Names}}\t{{.Status}}' | grep -v 'Up '"

# Unhealthy containers (still running but healthcheck failing)
ssh <host> "docker ps --format 'table {{.Names}}\t{{.Status}}' | grep 'unhealthy'"
```

Any container showing `Exited`, `Restarting`, or `(unhealthy)` is a concern. Observe and raise a GitHub issue on the relevant repo if not already tracked. Do not restart containers yourself — that's incident response.

If a crash-looping container might have an application-level root cause (e.g. an unhandled exception rather than resource exhaustion), note this in the issue body for lucos-site-reliability to cross-check.

---

## Weekly (4 checks)

### Check 2: Syslog Review

SSH into each active host:

```bash
ssh <host> "journalctl --since '7 days ago' -p err..emerg --no-pager | tail -100"
```

Look for recurring errors, OOM kills, hardware warnings, or anything unexpected. Raise issues for patterns worth investigating.

---

### Check 3: Software/OS Updates

SSH into each active host:

```bash
ssh <host> "apt list --upgradable 2>/dev/null"
```

Distinguish:
- **Security patches** (`-security` in the origin): raise a GitHub issue immediately on `lucas42/lucos_agent_coding_sandbox` flagging which host and which packages need patching. Mark as urgent.
- **Routine updates**: note in memory and raise a lower-priority issue if the backlog is growing.

Do not run `apt upgrade` yourself — that's a change with downtime risk and needs to go through the normal process.

---

### Check 4: Resource Checks

SSH into each active host and check:

- **Memory**: `free -h` — flag if available memory is consistently low
- **Disk space**: `df -h` — flag any filesystem above 80% used. If a filesystem is above 80%, **investigate the cause before raising the issue**: run `du -h --max-depth=2 / --exclude=/proc --exclude=/sys --exclude=/dev 2>/dev/null | sort -rh | head -20` to identify the largest directories, then drill down further as needed. Include the breakdown (top consumers by path and size) in the issue body, along with your assessment of whether the growth is expected (e.g. backup accumulation during retention window) or unexpected (e.g. runaway logs, orphaned Docker layers). Do not raise a "disk is full" issue without this analysis — repeated issues closed without root cause identified are noise.
- **IOPS/load**: `uptime` and `iostat -x 1 3` if available — flag sustained high load
- **Journal/log size**: `journalctl --disk-usage` — flag if approaching problematic sizes

Trivial hygiene fixes (e.g. clearing a tmp dir that obviously accumulated junk) can be done immediately if they carry no downtime risk. Anything more significant: raise a GitHub issue on `lucas42/lucos_agent_coding_sandbox` or the relevant repo.

If resource findings might have an application-level root cause, flag this in the issue body for lucos-site-reliability to cross-check.

---

### Check 5: Sandbox Drift

Check for drift between the live VM environment and the `lucos_agent_coding_sandbox` codebase, in **both directions**:

1. **Manual snowflakes on the VM** — things installed or configured by hand that aren't reflected in `lucos_agent_coding_sandbox`. SSH config, installed packages, cron jobs, custom scripts. Compare against `~/sandboxes/lucos_agent_coding_sandbox/`.
2. **Committed changes not yet applied** — changes pushed to `lucos_agent_coding_sandbox` that haven't been applied to the live VM yet.

```bash
cd ~/sandboxes/lucos_agent_coding_sandbox && git log --oneline origin/main..HEAD
cd ~/sandboxes/lucos_agent_coding_sandbox && git fetch && git log --oneline HEAD..origin/main
```

Raise a GitHub issue on `lucas42/lucos_agent_coding_sandbox` for any drift found. The goal is zero manual snowflakes — if you had to rebuild from scratch at 3am, it should all be in the repo.

---

---

## Daily (1 check)

### Check 6: Repos Dashboard Convention Review

Review the lucos_repos convention dashboard for failing checks:

```bash
curl -s https://repos.l42.eu/api/status | python3 -c "
import json, sys
data = json.load(sys.stdin)
for repo_name, repo_data in data['repos'].items():
    for conv_name, check in repo_data.get('conventions', {}).items():
        if check.get('pass') == False:
            print(f\"{repo_name}  {conv_name}  {check.get('detail', '')}\")
" | sort
```

**API structure note:** Each repo in `data['repos']` has top-level keys `type`, `conventions`, and `compliant`. The individual convention results are nested under `conventions` — do not iterate the repo object directly or you'll be looping over the wrong level.

For each failing convention:

- **Trivial to fix** (e.g. a missing config file, a simple workflow update, a label that needs adding): fix it directly — commit, push, then verify the fix using the ad-hoc rerun endpoint:
  ```
  POST https://repos.l42.eu/api/rerun?repo=lucas42/{repo}&convention={convention}
  ```
  **After fixing any branch-protection-related convention** (e.g. `valid-required-status-checks`, `codeql-required-for-auto-merge`, `dependabot-required-checks-satisfiable`, `circleci-jobs-in-required-checks`), rerun **all conventions for that repo** — not just the one you fixed. These conventions are tightly coupled: fixing one frequently breaks another. Verify with:
  ```
  POST https://repos.l42.eu/api/rerun?repo=lucas42/{repo}
  ```
  If a new failure appears, fix it in the same pass rather than leaving it for the next 6-hour sweep.
  
  **Note:** `/api/rerun` updates convention results but does **not** satisfy the `last-audit-completed` monitoring check. If monitoring is alerting on a failed sweep (e.g. after a rate limit error), trigger a full sweep instead:
  ```
  POST https://repos.l42.eu/api/sweep
  ```
  No query parameters. Returns 202; sweep runs in the background. Returns 409 if already in progress. The sweep waits for rate limits to reset (up to 5 min) rather than aborting.
- **Complex or systemic** (e.g. the same convention failing across many repos suggesting a design problem, a convention that requires application code changes, or a fix with unclear side effects): note it in the ops check summary for the dispatcher. Do not raise GitHub issues — the audit sweep handles issue creation automatically.

Do not fix violations that touch application logic or security configuration — note those in the summary for routing to the appropriate specialist.

**Investigating CircleCI required check coherence:** If you manually inspect a `required-status-checks-coherent` result and find "no CircleCI check runs" on recent commits/PR SHAs, check whether there are any open PRs on that repo. If there are **no open PRs**, checking PR-head SHAs will always return zero results — that's not evidence the check is stale, it just means no PR branches have been pushed recently. Instead, check the commit SHA statuses on recent main branch commits:
```bash
~/sandboxes/lucos_agent/gh-as-agent --app lucos-system-administrator \
  "repos/lucas42/{repo}/commits/main/statuses" --jq '[.[] | .context] | unique'
```
If the check name appears there consistently, it's working. The convention tool checks commit SHAs (not PR SHAs), which is why it may correctly report pass even when you see no PR-head runs. Trust the convention tool over an absence of PR-head runs when there are no open PRs.

Also note: CircleCI strips the orb prefix from job names when constructing GitHub status context names. A job defined as `lucos/build-multiplatform` in the config is reported as `ci/circleci: build-multiplatform` to GitHub — this is correct, not a mismatch.

---

## Monthly (3 checks)

### Check 7: Backup Verification

SSH into each active host and verify that lucos_backups is actually completing runs, not just that volumes exist:

```bash
ssh <host> "docker logs lucos_backups --since 48h 2>&1 | tail -50"
```

Look for evidence of successful backup runs and any errors. A volume being declared is not the same as a backup completing. If backup runs are missing or failing, raise a GitHub issue on `lucas42/lucos_backups` immediately — this is exactly the kind of slow-burn risk that bites you after a ransomware event.

Note: `lucos_backups` runs as a single container on avalon and handles all hosts. Do not raise issues about other hosts lacking a lucos_backups container — that is by design.

---

### Check 8: Certificate Expiry

TLS termination happens in the `lucos_router` container, which runs on the production hosts. Note: on both avalon and xwing the container is named `lucos_router`. Check certificate expiry for all domains served:

```bash
ssh <host> "docker exec lucos_router sh -c 'for f in /etc/letsencrypt/live/*/cert.pem; do echo \"=== \$f ===\"; openssl x509 -noout -dates -in \$f; done'"
```

**Renewal context**: certbot renews certificates when they are under 30 days from expiry. lucos_monitoring fires an alert when certificates are under 20 days from expiry. Do not raise issues for certificates expiring in more than 30 days — that is the normal operating window before certbot has triggered.

- **Under 20 days**: urgent — monitoring should have fired; something is seriously wrong
- **20–30 days**: warning — certbot should have renewed by now but hasn't; investigate
- **Over 30 days**: normal — do not raise an issue; certbot will handle it in due course

Raise cert issues on `lucas42/lucos_router`, not `lucos_agent_coding_sandbox`.

---

### Check 9: Docker Image Staleness

SSH into each active host and check when running containers were last built:

```bash
ssh <host> "docker ps --format '{{.Names}}\t{{.Image}}' | while read name image; do echo \"$name: $(docker inspect --format '{{.Created}}' $image 2>/dev/null || echo 'unknown')\"; done"
```

Services that haven't been rebuilt in more than 60 days may be running outdated base images. However, **before raising an issue, verify there is actually a newer version available upstream**. A production image that is 70 days old is not stale if the upstream Docker Hub image hasn't been updated in 70 days either.

**Verification step for third-party images** (images not built locally — no `build:` directive in `docker-compose.yml`):
```bash
curl -s "https://hub.docker.com/v2/repositories/{org}/{image}/tags/{tag}" | python3 -c "
import sys, json; data=json.load(sys.stdin); print(f\"last_updated: {data['last_updated']}\")"
```
Compare the Docker Hub `last_updated` date against the production image creation date. If they match (or are within a day or two of each other), the image IS the latest available — **do not raise an issue**. The upstream simply hasn't published anything newer.

If the production image IS older than the latest Docker Hub tag, then raise a staleness issue — something is blocking the pull (broken Dependabot config, CI failure, etc.) and warrants investigation.

For **locally-built images** (those with a `build:` directive), the 60-day threshold applies directly — these are rebuilt on every deploy, so an old build indicates missed deployments or broken CI.

Frame staleness issues as operational hygiene (stale builds accumulate drift from upstream, miss improvements and bug fixes), not as CVE findings — specific vulnerability tracking is lucos-security's responsibility via Dependabot alerts.

**Where to file:** Raise the issue on the repo that **owns the image** — e.g., a stale `lucos_locations_otrecorder` image goes on `lucos_locations`, a stale `lucos_photos_postgres` image goes on `lucos_photos`. Do **not** file on `lucos_agent_coding_sandbox` — that repo is for VM provisioning concerns only.

---

## Frequency Tracking

Track last run dates in `ops-checks.md`:

```
container_status: YYYY-MM-DD
syslog_review: YYYY-MM-DD
software_updates: YYYY-MM-DD
resource_checks: YYYY-MM-DD
sandbox_drift: YYYY-MM-DD
repos_dashboard: YYYY-MM-DD
backup_verification: YYYY-MM-DD
certificate_expiry: YYYY-MM-DD
docker_image_staleness: YYYY-MM-DD
```

A check is due if there is no entry or if elapsed time meets or exceeds the frequency. **If previously flagged**: re-run that specific check regardless of schedule.

---

## Completion Manifest

After completing your ops checks run, output a table like this:

| Check | Frequency | Status | Notes |
|---|---|---|---|
| 1. Container Status | Every run | Done | Brief finding or "all containers up" |
| 2. Syslog Review | Weekly | Done / Skipped (not due) | — |
| 3. Software/OS Updates | Weekly | Done / Skipped (not due) | — |
| 4. Resource Checks | Weekly | Done / Skipped (not due) | — |
| 5. Sandbox Drift | Weekly | Done / Skipped (not due) | — |
| 6. Repos Dashboard | Daily | Done / Skipped (not due) | — |
| 7. Backup Verification | Monthly | Done / Skipped (not due) | — |
| 8. Certificate Expiry | Monthly | Done / Skipped (not due) | — |
| 9. Docker Image Staleness | Monthly | Done / Skipped (not due) | — |

**Do not skip any row in this table.** If a check was not run, say why ("not due — last run YYYY-MM-DD"). This table is the audit trail that confirms all 9 checks were considered.
