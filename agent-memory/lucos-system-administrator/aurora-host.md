---
name: aurora host — QNAP NAS operational notes
description: Details about the aurora.local NAS host: hardware, userland, SSH user setup, and what cannot be scripted
type: project
---

aurora.local is a **QNAP NAS**, not a Synology or generic Linux box.

- Kernel: 3.4.6 armv5tel
- Userland: busybox (no GNU coreutils, no shadow-utils)
- User homes: `/share/homes/$user` (not `/home/$user`, not Synology's `/var/services/...`)
- SSH gateway: xwing (`ssh -J xwing aurora.local`)
- Backup root: `/share/backups/`
- `is_storage_only: true` in `lucos_configy/config/hosts.yaml` — does NOT run Docker

## What you cannot do on aurora

- `useradd` / `usermod` are NOT installed — shadow-utils aren't available
- Do not attempt to run init-host.sh as-is; it won't work on busybox

## lucos-backups user on aurora

The `lucos-backups` user, `~/.ssh/`, and `authorized_keys` were all set up out-of-band manually years ago.
The `init-host.sh` script in lucos_backups has never been run end-to-end on aurora.

lucos_backups#268 tracks making init-host.sh portable for busybox/non-`/home` hosts.
lucos_backups#269 is the PR implementing it.

## How aurora's backups were broken (2026-05-09 incident)

SSH key rotation for the `lucos-backups` user broke because:
1. The authorized_keys file had to be updated manually (no automated provisioning)
2. The user home is at `/share/homes/lucos-backups`, not `/home/lucos-backups`

Incident report: https://github.com/lucas42/lucos/blob/main/docs/incidents/2026-05-09-backups-ssh-key-rotation.md
