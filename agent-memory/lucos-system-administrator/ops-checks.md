# Ops Checks Last Run

Tracks when each check was last run. Format: `check_name: YYYY-MM-DD`

A check is due if it has no entry here, or if the elapsed time since last_run meets or exceeds its frequency.

```
container_status: never
resource_checks: never
syslog_review: never
software_updates: never
docker_image_staleness: never
backup_verification: never
certificate_expiry: never
sandbox_drift: never
```

## Run Log

<!-- Add entries in reverse chronological order (most recent first) -->
<!-- Format:
### YYYY-MM-DD

**Container status**: [findings or "clean"]
**Resources**: [findings or "clean" or "not due"]
**Syslog**: [findings or "clean" or "not due"]
**Updates**: [findings or "clean" or "not due"]
**Image staleness**: [findings or "clean" or "not due"]
**Backups**: [findings or "clean" or "not due"]
**Certs**: [findings or "clean" or "not due"]
**Sandbox drift**: [findings or "clean" or "not due"]
**Issues raised**: [list or "none"]
-->
