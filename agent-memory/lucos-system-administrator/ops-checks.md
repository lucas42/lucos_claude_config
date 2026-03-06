# Ops Checks Last Run

Tracks when each check was last run. Format: `check_name: YYYY-MM-DD`

A check is due if it has no entry here, or if the elapsed time since last_run meets or exceeds its frequency.

```
container_status: 2026-03-06  # second run same day — arachne ingestor/triplestore/search exited (expected: restart:no, one-shot containers)
resource_checks: 2026-03-05
syslog_review: 2026-03-05
software_updates: 2026-03-05
docker_image_staleness: 2026-03-05
backup_verification: 2026-03-05
certificate_expiry: 2026-03-05
sandbox_drift: 2026-03-05
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

---

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
