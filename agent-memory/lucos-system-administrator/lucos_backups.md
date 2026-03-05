# lucos_backups — Architecture & How It Works

## Deployment model

`lucos_backups` runs as a **single container on avalon only**. It SSHes into all configured hosts (avalon, xwing, salvare) to perform all backup and prune operations. You do NOT need a `lucos_backups` container on each host — one central instance handles everything.

Do not raise issues about xwing/salvare lacking a `lucos_backups` container. This is by design.

## Container environment variables

- `PORT` — web server port
- `SSH_PRIVATE_KEY` — ed25519 private key for the `lucos-backups` system user (stored in lucos_creds, with `=` padding replaced by `~` due to lucos_creds limitation)
- `GITHUB_KEY` — GitHub personal access token for backing up repos
- `SCHEDULE_TRACKER_ENDPOINT` — URL of lucos_contacts schedule tracker endpoint

No `env_file`, no `volumes:` section — this container has no persistent volumes of its own (config is fetched from configy.l42.eu at startup and cached in `config.yaml` inside the container).

## Architecture: what gets backed up and how

### Docker volumes (per host)
- `Host.getVolumes()` SSHes into a host and runs `docker volume ls --format json`
- Each volume is archived locally on its source host: `docker run --rm --volume NAME:/raw-data alpine tar -czf /srv/backups/local/volume/NAME.DATE.tar.gz .`
- The resulting tarball is then `scp`'d to ALL other hosts: `/srv/backups/host/SOURCE_HOST/volume/NAME.DATE.tar.gz`
- Volumes with `skip_backup: true` in volumes.yaml are skipped

### One-off files
- Files in `/srv/backups/local/one-off/` on each host (writable by the host's regular user group)
- Copied to `/srv/backups/host/SOURCE_HOST/one-off/` on all other hosts
- NOT versioned — only backed up if the file doesn't already exist at the destination

### GitHub repositories
- Listed via GitHub API (`/user/repos?affiliation=owner`)
- Downloaded as tarball to `/srv/backups/external/github/repository/NAME.DATE.tar.gz` on ALL hosts
- Authenticated via GitHub API redirect (5-minute expiry URL)

## Cron schedule (inside container)

- **03:25** daily: `create-backups.py` — creates archives and distributes to other hosts
- **04:49** daily: `prune-backups.py` — prunes old backups on ALL hosts per retention policy
- **Every hour at :07**: POST to `/refresh-tracking` — re-reads backup state from all hosts
- **Every hour at :03**: POST to `/refresh-config` — re-fetches volumes/hosts config from configy.l42.eu

## SSH authentication

The container loads `SSH_PRIVATE_KEY` into an SSH agent on startup via `init-agent.sh`:
```sh
echo "$SSH_PRIVATE_KEY" | sed 's/~/=/g' | ssh-add -
```
(the `~` → `=` conversion undoes the lucos_creds encoding). The `lucos-backups` system user must be set up on each host via `init-host.sh` before it will work.

## Directory structure on hosts

```
/srv/backups/
  local/
    volume/          <- archives created locally from volumes on this host
    one-off/         <- one-off files to be backed up (group-writable)
  host/
    HOSTNAME/        <- backup copies received from other hosts
      volume/
      one-off/
  external/
    github/
      repository/    <- GitHub repo tarballs
```

## Retention policy (Backup.toKeep() in backup.py)

- < 1 week: keep all instances
- 1–5 weeks: keep instances where `day % 6 == 0` (every 6th day)
- 5 weeks–1 year: keep the 6th of each month
- > 1 year: keep the 6th of January each year
- Single instances (one-off files) are always kept

## Tracking vs Config refresh

Two separate refresh cycles:
- **Config** (hourly): fetches volumes/hosts config from `configy.l42.eu` — determines what volumes *should* exist
- **Tracking** (hourly): SSHes into each host to see what volumes *do* exist and what backup files are present

The web UI and `/_info` both serve data from the last tracking run (in-memory `latestInfo`).

## Health checks in /_info

- `volume-config`: volumes found on hosts but NOT in lucos_configy → unregistered volumes
- `volume-host`: volumes in lucos_configy but NOT found on any host → configured but absent
- `data-age`: whether tracking data is more than 2 hours old
- `host-tracking-failures`: whether any host's tracking failed on last run
- `disk-space-HOSTNAME`: per-host disk usage in `/srv/backups/` at > 95%

## Volume registration in lucos_configy

Every named Docker volume must be in `lucos_configy/config/volumes.yaml`. The `lucos_backups` tracking checks against this. The yaml format:
```yaml
VOLUME_NAME:
    description: Human-readable description
    recreate_effort: automatic|small|tolerable|considerable|huge|remote
    skip_backup: true  # optional, omit if backup is needed
```
Volume names in the yaml must match Docker's name exactly (which is `<compose_project>_<volume_name>`).

Remote-mounted NAS volumes (lucos_private_medlib, lucos_static_media_public, lucos_media_import_media) have `recreate_effort: remote` and `skip_backup: true`.

## Prune script behaviour

`prune-backups.py` SSHes into ALL configured hosts (avalon, salvare, xwing) and prunes `/srv/backups/` on each. It does NOT only prune the host where `lucos_backups` is deployed. Evidence: prune logs show `Host: salvare.s.l42.eu` and `Host: xwing.s.l42.eu` being visited.

## Known issues (as of 2026-03-05)

- **#34**: `getBackups()` times out on xwing — 1,373 files, `find ... -exec du -sh {} \;` runs du once per file, too slow for 10s timeout
- **#4**: Backup/prune scripts still fail hard when a host is down (tracking is more resilient, but scripts are not)

## Historical context

- `lucos_photos_qdrant_data` was an orphaned volume that appeared after the Qdrant-to-pgvector migration (lucos_photos#36 removed the service from docker-compose, lucos_configy#34 removed it from volumes.yaml). The orphan volume remained on avalon until lucos_photos#76 cleaned it up. It should NOT have been raised as a backups issue — the correct fix was removing the orphan, not registering it. When encountering unknown volumes in volume-config failures, first check whether they are migration orphans before raising issues about registering them.

## What lucos_backups is NOT responsible for

- It does NOT need to run on every host — central deployment on avalon handles all hosts
- It does NOT monitor the backup files themselves beyond enumerating them for the UI
- It does NOT check whether individual backups are valid/restorable (issue #5 covers this gap)
