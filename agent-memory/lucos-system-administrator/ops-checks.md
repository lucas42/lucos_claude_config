# Ops Checks Last Run

Tracks when each check was last run. Format: `check_name: YYYY-MM-DD`

A check is due if it has no entry here, or if the elapsed time since last_run meets or exceeds its frequency.

```
container_status: 2026-03-05
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

**Issues raised**:
- lucos_agent_coding_sandbox#14: salvare disk at 95%
- lucos_agent_coding_sandbox#15: salvare security patch backlog (urgent)
- lucos_agent_coding_sandbox#16: avalon swap exhausted
- lucos_agent_coding_sandbox#17: avalon Docker 26.x → 29.x
- lucos_agent_coding_sandbox#18: xwing cert expiry 6 Apr (32 days)
- lucos_agent_coding_sandbox#19: sandbox drift (bidirectional)
- lucos_agent_coding_sandbox#20: lucos_locations_otrecorder image stale (Aug 2025)
- lucos_backups#32: no lucos_backups on xwing or salvare
