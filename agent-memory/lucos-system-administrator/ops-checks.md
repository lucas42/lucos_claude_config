# Ops Checks Last Run

Tracks when each check was last run. Format: `check_name: YYYY-MM-DD`

A check is due if it has no entry here, or if the elapsed time since last_run meets or exceeds its frequency.

```
container_status: 2026-03-15
resource_checks: 2026-03-12
syslog_review: 2026-03-12
software_updates: 2026-03-12
docker_image_staleness: 2026-03-12
backup_verification: 2026-03-12
certificate_expiry: 2026-03-12
sandbox_drift: 2026-03-12
```

## Known Limitations

- Journal logs on xwing and salvare are inaccessible without sudo (no sudo available in non-interactive SSH). Syslog review only covers avalon fully.
- Docker image staleness query needs single-quoted heredoc style — shell escaping is tricky over SSH.

## Run Log

### 2026-03-05 (FIRST RUN — all checks due)

**Container status**: xwing has `lucos_media_import_test` in Exited (0) state, 10 days old — likely an intentional one-shot test container, not a crashloop concern. Avalon and salvare clean.

**Resources**:
- avalon: swap nearly exhausted (508Mi/511Mi), 3.1Gi real memory available. Disk 46% (fine). Issue raised: lucos_agent_coding_sandbox#16
- xwing: memory fine (474Mi available of 906Mi total). Disk 35% (fine). Journal inaccessible.
- salvare: disk at **95%** (2.9G free of 58G). Memory fine. Journal inaccessible. Issues raised: lucos_agent_coding_sandbox#14 (disk), lucos_agent_coding_sandbox#15 (security patches)

**Syslog**:
- avalon: clean (no errors in past 7 days)
- xwing: journal inaccessible (no sudo)
- salvare: journal inaccessible (no sudo)

**Updates**:
- avalon: Docker 26.x → 29.x pending (not security-tagged). Issue raised: lucos_agent_coding_sandbox#17
- xwing: clean
- salvare: large security patch backlog including openssh, sudo, systemd, libc6, kernel. Issue raised: lucos_agent_coding_sandbox#15

**Image staleness**:
- avalon: `lucos_locations_otrecorder` image from 2025-08-12 (6+ months stale). Issue raised: lucos_agent_coding_sandbox#20
- xwing: all images recent (most from 2026-03-04)
- salvare: all images recent

**Backups**:
- avalon: lucos_backups running and completing successfully (config fetch + tracking completed today)
- xwing: NO lucos_backups container found
- salvare: NO lucos_backups container found
- Issue raised: lucos_backups#32

**Certs**:
- avalon (l42.eu): expires 2026-04-20 (46 days — warning)
- xwing (4 domains: nas.l42.eu, private.l42.eu, staticmedia.l42.eu, xwing.s.l42.eu): all expire 2026-04-06 (32 days — warning). Issue raised: lucos_agent_coding_sandbox#18

**Sandbox drift**: 2 local commits unpushed, 2 remote commits undeployed. Issue raised: lucos_agent_coding_sandbox#19

### 2026-03-05 (FOURTH RUN — container status only, all other checks current)

**Container status**:
- avalon: clean
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), now 11 days old — still a one-shot test container, not a concern

**Closed issues noted**:
- lucos_agent_coding_sandbox#14 (salvare disk): CLOSED — salvare disk now 73% (16G free, was 95%). Significant space freed.
- lucos_agent_coding_sandbox#18 (xwing cert): CLOSED — cert still expires 2026-04-06 (32 days). Issue closed as acknowledged, not yet renewed. Worth re-checking next week.
- lucos_agent_coding_sandbox#19 (sandbox drift): CLOSED — drift resolved.

**Note**: xwing router container is named `router`, not `lucos_router_nginx`.

### 2026-03-05 (SIXTH RUN — container status only, all other checks current)

**Closed issues reviewed** (learnings absorbed):
- lucos_backups#32 (xwing/salvare no backups): CLOSED as not_planned — single `lucos_backups` on avalon SSHes into ALL hosts to back up volumes. See `lucos_backups.md`.
- lucos_backups#33 (salvare prune not running): CLOSED as not_planned — prune script iterates all hosts via SSH. Note: xwing prune times out (1,373 files, `du -sh` per file) — separate issue warranted if backlog grows.
- lucos_agent_coding_sandbox#15 (salvare security patches): CLOSED — lucas42 ran upgrade manually. All security patches cleared. Unattended-upgrades tracked in #21.
- lucos_agent_coding_sandbox#18 (xwing cert): CLOSED as not_planned — `update-domains.sh` cron in `router` container runs daily at 22:16. At 31 days, cert is within auto-renewal window.
- lucos_backups#35 (qdrant volume not in configy): CLOSED — resolved.
- lucos_backups#36 (/_info missing start_url): CLOSED — resolved.
- lucos_deploy_orb#10 (docker image prune on deploy): CLOSED — implemented. Deploy orb now prunes dangling images after each deploy.
- lucos_agent#11 (scripts split between repos): CLOSED — intentional: `lucos_agent` = GitHub API auth; `lucos_claude_config/scripts/` = self-referential Claude env maintenance.

**Container status**:
- avalon: clean
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 11 days old — one-shot test container, not a concern

**Xwing cert check**: All 4 certs expire 2026-04-06 (31 days). `update-domains.sh` cron runs daily at 22:16 — auto-renewal expected. No issue raised.

### 2026-03-05 (SIXTH RUN — container status only, all other checks current)

**Container status**:
- avalon: clean
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), still 11 days old — one-shot test container, still not a concern

**Xwing cert check** (spot check): Still same cert, expires 2026-04-06. Not yet within 30-day renewal window. Auto-renewal cron running daily — no action needed.

### 2026-03-06 (container status + xwing cert spot-check; all other checks not yet due)

**Container status**:
- avalon: `lucos_comhra_agent` and `lucos_comhra_llm` both Exited (255) — stopped simultaneously at 12:24:24 UTC. Not OOM. No matching deploy. Issue raised: lucos_comhra#2
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 11+ days old — one-shot test container, not a concern

**Xwing cert spot-check**: nas.l42.eu still notAfter=Apr 6. At 31 days. Tonight's cron run (22:16) may or may not trigger (threshold is <30 days). 2026-03-07 should be first run at 29 days that triggers renewal. If cert still unrenewed by 2026-03-09, raise issue.

### 2026-03-06 (SECOND RUN same day — container status + cert spot-check)

**Container status**:
- avalon: `lucos_arachne_ingestor`, `lucos_arachne_triplestore`, `lucos_arachne_search` all Exited (255) ~50 mins ago. Investigated: all three have `restart: no` policy — confirmed one-shot containers that run to completion and exit. Ingestor log shows full successful ingestion run. NOT a concern.
- `lucos_arachne_web` and `lucos_arachne_explore` both up. Web tier is healthy.
- comhra containers: back up (was down in previous run). Issue #2 closed.
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 11 days — one-shot test container, not a concern

**Xwing cert spot-check**: notAfter=Apr 6 2026 (31 days from today). No renewal yet — expected, cron triggers at <30 days. Re-check 2026-03-09 if still unrenewed.

**Key learning**: arachne ingestor, triplestore, and search are all `restart: no` one-shot containers. Do not raise issues for these appearing in `Exited` state.

### 2026-03-06 (THIRD RUN same day — container status + cert spot-check)

**Container status**:
- avalon: clean (all services up)
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 11 days — one-shot test container, not a concern

**Xwing cert spot-check**: notAfter=Apr 6 2026 (31 days from today). Still not within 30-day renewal window — tomorrow night's cron run (2026-03-07 at 22:16 UTC) should be at 29 days and trigger renewal. Re-check 2026-03-09 if still unrenewed.

### 2026-03-06 (FOURTH RUN same day — container status + cert spot-check)

**Container status**:
- avalon: clean
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 11 days — one-shot test container, not a concern

**Xwing cert spot-check**: notAfter=Apr 6 2026. Still 31 days out. Tonight's cron (22:16 UTC) is right on the 30-day boundary — may or may not trigger. Tomorrow's run at 29 days should definitely trigger. Re-check 2026-03-09 if still unrenewed.

### 2026-03-06 (FIFTH RUN same day — container status + cert spot-check)

**Container status**:
- avalon: clean (all containers up)
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 12 days old — one-shot test container, not a concern

**Xwing cert spot-check**: notAfter=Apr 6 2026 (still 31 days). Tonight's cron at 22:16 UTC may or may not trigger at 30 days. Tomorrow night (2026-03-07 at 22:16) should be at 29 days and trigger renewal. Re-check 2026-03-09 if still unrenewed.

### 2026-03-07 (container status only + cert spot-check; all other checks not yet due)

**Container status**:
- avalon: clean (no non-running containers)
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 12 days old — one-shot test container, not a concern

**Xwing cert spot-check**: notAfter=Apr 6 2026 — exactly 30 days from today. Tonight's cron at 22:16 UTC is right on the 30-day threshold; may or may not trigger. Tomorrow night (2026-03-08 at 22:16) will be at 29 days and should definitely trigger renewal. Re-check 2026-03-09 if still unrenewed.

### 2026-03-07 (SECOND RUN — container status + cert spot-check; weekly/monthly checks not yet due)

**Container status**:
- avalon: clean
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 12 days old — one-shot test container, not a concern

**Xwing cert spot-check**: notAfter=Apr 6 2026 (still not renewed). Today is exactly 30 days out. Tonight's cron at 22:16 UTC may or may not fire at exactly 30 days; 2026-03-08 cron will be at 29 days and should trigger. Re-check 2026-03-09 as previously flagged.

### 2026-03-06 (SIXTH RUN same day — container status + cert spot-check)

**Container status**:
- avalon: clean
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 12 days old — one-shot test container, not a concern

**Xwing cert spot-check**: notAfter=Apr 6 2026 (31 days). Tonight's cron may or may not trigger at the 30-day mark. 2026-03-07 cron at 22:16 should be first run clearly inside the renewal window. Re-check 2026-03-09 if still unrenewed.

### 2026-03-07 (THIRD RUN — container status + cert spot-check; weekly/monthly checks not yet due)

**Container status**:
- avalon: clean (no non-running containers)
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 12 days old — one-shot test container, not a concern

**Xwing cert spot-check**: RENEWED. notAfter=Jun 5 2026 (90 days). Certbot ran successfully, likely around 07:00 UTC today when the cert hit 30 days out. Cert concern fully resolved — no further spot-checks needed until next rotation.

---

### 2026-03-07 (FOURTH RUN — container status only; weekly/monthly checks not yet due)

**Container status**:
- avalon: clean
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 12 days old — one-shot test container, not a concern

**Xwing cert**: Renewed (confirmed in third run today) — notAfter=Jun 5 2026. No further tracking needed this cycle.

### 2026-03-07 (FIFTH RUN — container status only; weekly/monthly checks not yet due)

**Container status**:
- avalon: clean
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 12 days old — one-shot test container, not a concern

**Xwing cert**: Renewed (confirmed in third run today) — notAfter=Jun 5 2026. No further tracking needed this cycle.

### 2026-03-07 (SIXTH RUN — container status only; weekly/monthly checks not yet due)

**Container status**:
- avalon: clean
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 12 days old — one-shot test container, not a concern

### 2026-03-07 (SEVENTH RUN — container status only; weekly/monthly checks not yet due)

**Container status**:
- avalon: clean
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 12 days old — one-shot test container, not a concern

### 2026-03-07 (EIGHTH RUN — container status only; weekly/monthly checks not yet due)

**Container status**:
- avalon: clean
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 12 days old — one-shot test container, not a concern

---

### 2026-03-08 (checks 1–5 due; 6–8 not yet due — last run 3 days ago)

**Container status**:
- avalon: `lucos_arachne_triplestore` Exited (137) — SIGKILL, OOM kill by kernel. Fuseki (`startup.sh: Killed fuseki-server`). restart: no so stayed down. Commented on lucos_arachne#62. Also: swap at 505Mi/511Mi.
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 13 days old — one-shot test container, not a concern

**Resources**:
- avalon: swap 505Mi/511Mi (98%) — refilled within 2 days of 2026-03-06 reboot. Issue raised: lucos_agent_coding_sandbox#25. Memory fix (#58) deployed but underlying capacity insufficient.
- xwing: memory OK (472Mi available of 906Mi). Disk 28% (fine).
- salvare: memory fine (3.3Gi available of 3.7Gi). Disk 75% (42G used of 58G, 14G free — recovering from 95% in March).

**Syslog**:
- avalon: only lucos-agent sudo failures from March 6 reboot sequence. No hardware errors.
- xwing: journal inaccessible (no sudo) — known limitation
- salvare: journal inaccessible (no sudo) — known limitation

**Software updates**:
- avalon: no upgradable packages (clean)
- xwing: libc6, openssl, kernel (6.12.47→6.12.62), Docker 29.1.3→29.3.0 pending. Issue raised: lucos_agent_coding_sandbox#24
- salvare: kernel (6.12.25→6.12.62) and raspi-utils pending — minor, not security-tagged `-security`

**Sandbox drift**: no local unpushed commits, no remote commits to pull — clean.

**Issues raised**:
- lucos_agent_coding_sandbox#24: xwing OS updates pending (libc6, openssl, kernel)
- lucos_agent_coding_sandbox#25: avalon swap exhausted again (98%, 2 days post-reboot)

**Issues commented on**:
- lucos_arachne#62: OOM kill context added (Exited 137, confirmed kernel kill of Fuseki)

**Issues raised**:
- lucos_agent_coding_sandbox#14: salvare disk at 95%
- lucos_agent_coding_sandbox#15: salvare security patch backlog (urgent)
- lucos_agent_coding_sandbox#16: avalon swap exhausted
- lucos_agent_coding_sandbox#17: avalon Docker 26.x → 29.x
- lucos_agent_coding_sandbox#18: xwing cert expiry 6 Apr (32 days)
- lucos_agent_coding_sandbox#19: sandbox drift (bidirectional)
- lucos_agent_coding_sandbox#20: lucos_locations_otrecorder image stale (Aug 2025)
- lucos_backups#32: no lucos_backups on xwing or salvare
- lucos_repos#38: crash-loop due to x509 cert failure inside container (stale CA bundle)
- lucos_comhra#2: lucos_comhra_agent + lucos_comhra_llm down on avalon (simultaneous exit 255, 2026-03-06)

### 2026-03-09 (container status only; weekly checks last ran 2026-03-08; monthly checks last ran 2026-03-05 — none due)

**Container status**:
- avalon: all containers Up. `lucos_arachne_triplestore` is back up (was OOM-killed 2026-03-08). `lucos_arachne_web` is showing as "unhealthy" (542 consecutive healthcheck failures) — root cause: Docker healthcheck uses `wget http://localhost/_info` but nginx only binds IPv4 (`0.0.0.0:80`), not IPv6 (`[::]:80`). `localhost` resolves to `::1` first in the container, causing "Connection refused". Service externally healthy (lucos_monitoring gets HTTP 200 every minute). Commented on lucos_arachne#87 with diagnosis and fix recommendation.
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 2 weeks old — one-shot test container, not a concern

**Note**: lucos_arachne ingestor/triplestore/search all showing "Up" this run (previously `restart: no` one-shots). May have been redeployed since the OOM-kill incident.

### 2026-03-09 (SECOND RUN — container status only; all weekly/monthly checks ran 2026-03-08 or later, not due)

**Container status**:
- avalon: mostly clean. `lucos_arachne_web` still showing `(unhealthy)` — the localhost/IPv6 healthcheck issue (lucos_arachne#91) is still open and unresolved, but service is externally healthy. All other containers up.
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 2 weeks old — one-shot test container, not a concern

**No new issues raised.** Existing tracked issues: lucos_arachne#91 (healthcheck IPv6 fix), lucos_agent_coding_sandbox#24 (xwing updates), lucos_agent_coding_sandbox#25 (avalon swap).

### 2026-03-09 (THIRD RUN — container status with improved unhealthy check; all other checks not due)

**PROCEDURE IMPROVEMENT**: Added `grep 'unhealthy'` to container status check. Previous `grep -v 'Up '` was missing containers that are Up but (unhealthy).

**Container status**:
- avalon crashed/stopped: clean
- avalon unhealthy: `lucos_arachne_web` (known #91), `lucos_repos_app` (5,611 failures — wget missing from container), `lucos_backups` (5,622 failures — localhost/IPv6 issue), `lucos_comhra_agent` (18,671 failures — localhost/IPv6 issue)
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 2 weeks — one-shot, not a concern; no unhealthy containers

**Issues raised**:
- lucos_backups#49: healthcheck IPv6 localhost false-negative (fix: use 127.0.0.1)
- lucos_comhra#9: healthcheck IPv6 localhost false-negative (fix: use 127.0.0.1)
- lucos_repos#99: healthcheck broken — wget not installed in container image

**Ops-checks improvement**: Updated `~/.claude/agents/sysadmin-ops-checks.md` to add unhealthy container check. Committed to lucos_claude_config (90cc6b5).

---

### 2026-03-10 (checks 1–5 due; 6–8 not due — last run 2026-03-05)

**Container status**:
- avalon crashed/stopped: clean
- avalon unhealthy: `lucos_arachne_web` (known #91 — subsumed by #87), `lucos_backups` (known #49), `lucos_comhra_agent` (known #9) — all existing tracked issues, no new issues raised
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 2+ weeks — one-shot test container, not a concern; no unhealthy containers

**Resources**:
- avalon: memory 4.4Gi used, 3.2Gi available — healthy. Swap 829Mi/4.5Gi (18%) — healthy (was 98%, now resolved with 4.5GB swap). Disk 10% (fine). Load 0.63. Journal 17.8M (fine).
- xwing: 468Mi available of 906Mi. Disk 31% (fine). Swap 254Mi/905Mi (28%).
- salvare: 3.3Gi available of 3.7Gi. Disk 81% (45G of 58G) — up from 75% last week. Approaching the 80% threshold but not there yet.

**Syslog** (avalon only — xwing/salvare journal inaccessible without sudo):
- avalon: only lucos-agent sudo failures (reboot attempt 2026-03-06, apt upgrade attempt, dd/swapfile attempt 2026-03-08, find commands 2026-03-09) — all expected from agent ops work. No hardware errors, no OOM kills in past 7 days.

**Software updates**:
- avalon: no upgradable packages — clean
- xwing: Docker 29.1.3→29.3.0, libc6, openssl, kernel 6.12.47→6.12.62 still pending (tracked in #24). No security-origin tags. Commented on #24 with updated package list.
- salvare: kernel 6.12.25→6.12.62 and raspi-utils pending — routine, no security tags.

**Sandbox drift**: lucos_agent_coding_sandbox has one remote commit (Android SDK 36, PR #27) not in local checkout — but `git pull` showed already up to date. The commit is a lima.yaml provisioning change only (new VM creation), no live VM action required. No drift issue raised.

**Issues commented on**:
- lucos_agent_coding_sandbox#24: updated xwing package status

**Notes**:
- salvare disk at 81% — watch trend. Was 75% last week. If it hits 85% next check, raise an issue.

### 2026-03-10 (SECOND RUN — container status only; weekly checks ran earlier today, monthly checks last ran 2026-03-05 — not yet due)

**Container status**:
- avalon crashed/stopped: clean
- avalon unhealthy: `lucos_arachne_web` (known #87/#91), `lucos_backups` (known #49), `lucos_comhra_agent` (known #9) — all existing tracked issues. NEW: `lucos_photos_api` (unhealthy, up only 8 minutes — recently redeployed, healthcheck failing with `wget: not found`, exit 127)
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 2 weeks old — one-shot test container, not a concern; no unhealthy containers

**Issue raised**:
- lucos_photos#127: healthcheck broken — wget not installed in container image

### 2026-03-12 (ALL 8 checks due)

**Container status**:
- avalon crashed/stopped: clean
- avalon unhealthy: `lucos_backups` (known #49), `lucos_comhra_agent` (known #9). `lucos_arachne_web` no longer showing unhealthy — may have been fixed.
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 2+ weeks — one-shot test container, not a concern; no unhealthy containers

**Resources**:
- avalon: 3.6Gi available of 7.6Gi. Swap 1.6Gi/4.5Gi (36%) — healthy. Disk 11%. Load 0.97 (fine).
- xwing: 403Mi available of 906Mi. Swap 373Mi/905Mi (41%). Disk 38%. Load average 3.38–3.52 — elevated on a low-resource machine running 35 days. Worth monitoring.
- salvare: disk at **95%** again (53G/58G, 3G free) — was 81% on 2026-03-10. Issue raised: lucos_agent_coding_sandbox#28.

**Syslog** (avalon only):
- All errors are lucos-agent sudo failures from prior ops work (reboot attempts, apt upgrade, dd/swapfile, find commands). All expected. No hardware errors, no OOM kills.

**Software updates**:
- avalon: clean, no upgradable packages.
- xwing: Docker 29.1.3→29.3.0 + buildx + compose-plugin, libc6, openssl, kernel 6.12.47→6.12.62 still pending (all previously tracked in #24). Commented on #24.
- salvare: kernel 6.12.25→6.12.62, libc6, openssl (via rpt1+deb13u1), raspi-utils pending. No security-tagged packages.

**Sandbox drift**: clean — no local unpushed commits, no remote commits to pull.

**Backups**: lucos_backups running correctly on avalon. Config fetch + tracking both completed successfully in the last 48h. No issues.

**Certificates**:
- xwing: all 4 domains renewed 2026-03-07, notAfter=Jun 5 2026 (85 days). Fine.
- avalon: most domains expire Apr 20–22 (39–41 days). `schedule-tracker.l42.eu` expires Apr 11 (30 days exactly). Certbot should auto-renew imminently.
- Stale/dead certs present in avalon letsencrypt (router.l42.eu 2019, speak.l42.eu 2022, googlecontactsync.l42.eu 2023, valen.* 2021) — these are for decommissioned services. Not actively served, not a security concern, but worth noting as clutter.
- avalon router container name is `router` (not `lucos_router_nginx`).

**Image staleness**:
- avalon: `lucos_locations_otrecorder` still from 2025-08-12 (7 months stale). All other images from Feb–Mar 2026. Issue #20 remains open.
- xwing/salvare: image staleness query returns "unknown" — docker inspect on pulled images doesn't have local build dates. Known limitation.

**Issues raised/commented**:
- lucos_agent_coding_sandbox#28: salvare disk 95% again
- lucos_agent_coding_sandbox#24: commented with updated xwing package list + Docker updates

### 2026-03-11 (container status only; weekly checks last ran 2026-03-10, monthly checks last ran 2026-03-05 — none due)

**Container status**:
- avalon crashed/stopped: clean
- avalon unhealthy: `lucos_arachne_web` (known #87/#91), `lucos_backups` (known #49), `lucos_comhra_agent` (known #9) — all existing tracked issues
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 2+ weeks — one-shot test container, not a concern; no unhealthy containers

**Note**: `lucos_photos_api` is now showing (healthy) on avalon — looks like a new image was deployed. Commented on lucos_photos#127 noting recovery. Issue-manager to close if confirmed.

### 2026-03-13 (container status only; all weekly/monthly checks ran 2026-03-12 — not due)

**Container status**:
- avalon crashed/stopped: clean
- avalon unhealthy: `lucos_comhra_agent` (known lucos_comhra#9 — IPv6/localhost healthcheck). `lucos_backups` now showing (healthy) — IPv6 fix (lucos_backups#49) has been deployed.
- salvare: clean
- xwing: `lucos_media_import_test` Exited (0), 2 weeks old — one-shot test container, not a concern; no unhealthy containers

### 2026-03-14 (container status only; all weekly checks last ran 2026-03-12 — not due; monthly checks last ran 2026-03-12 — not due)

**Container status**:
- avalon crashed/stopped: clean
- avalon unhealthy: none detected
- salvare: clean; no unhealthy containers
- xwing: `lucos_media_import_test` Exited (0) — one-shot test container, not a concern; no unhealthy containers

**Notable**: `lucos_comhra_agent` (known lucos_comhra#9) no longer appearing unhealthy — may have been fixed or redeployed. Worth checking next run.

### 2026-03-15 (container status only; all weekly checks last ran 2026-03-12 — not due; monthly checks last ran 2026-03-12 — not due)

**Container status**:
- avalon crashed/stopped: clean
- avalon unhealthy: none
- salvare: clean; no unhealthy containers
- xwing: `lucos_media_import_test` Exited (0) — one-shot test container, not a concern; no unhealthy containers

**Notable**: `lucos_comhra_agent` absent from unhealthy list for second run in a row — likely fix (lucos_comhra#9) has been deployed. Will stop tracking as an ongoing concern unless it reappears.
