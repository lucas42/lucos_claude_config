---
name: aurora-access-and-rsync
description: aurora QNAP is not reachable by the agent SSH key directly; reach it via the lucos_backups container's fabric/ProxyJump path. rsync 3.0.7 + hardlinks confirmed.
metadata:
  type: reference
---

**Reaching aurora (the QNAP NAS backup destination):** the agent SSH key is
NOT in aurora's `lucos-backups` authorized_keys, so `ssh xwing "ssh aurora.local …"`
fails `Permission denied (publickey)`. Both site-reliability and sysadmin hit this
2026-06-09. To run a command on aurora, route through the **lucos_backups container
on avalon** — it holds the `SSH_PRIVATE_KEY` and reaches aurora via Fabric over the
xwing→aurora.lan ProxyJump (the same path the real backup uses, so it's a
like-for-like check). A direct agent key on aurora is a separate, not-yet-made
decision; raise only if ad-hoc aurora checks become frequent.

**Verified aurora facts (2026-06-09, for ADR-0002 step-zero; re-confirmed live same day):**
- `rsync` **3.0.7** present (protocol 30). Old (2009) but supports `--link-dest`,
  `--partial`, `--append-verify` (all predate it).
- Backup root **`/share/backups/`** is a **local `/dev/md0` RAID filesystem** (954.4G
  free, 74% used of 3.6T) — NOT an SMB/NFS mount, so real hardlinks work (link count
  test = 2) and rsync `--link-dest` won't silently degrade to full copies.
- aurora is `armv5tel` (QTS kernel 3.4.6) — restic/borg static-binary arch is awkward,
  a minor extra nail in the rsync-over-restic decision (restic-over-SFTP wasn't
  arch-blocked though, since restic would run source-side).
- rsync works over the xwing→aurora ProxyJump key chain.
- **How to re-run the check** (read-only): `docker exec -i lucos_backups sh -c "cat >
  /tmp/c.py"` a script using `classes.host.Host("avalon").connection.run("ssh <args>
  <aurora.domain> <cmd>")`, then exec with the agent set up: `eval $(ssh-agent -s);
  echo "$SSH_PRIVATE_KEY"|ssh-add -; cd /usr/src/app && pipenv run python3 /tmp/c.py`.
  Plain `pipenv run python3 -` interactive fails: no ssh-agent (only the long-running
  server process has one via init-agent.sh), and yaml/fabric need pipenv. Use
  `sys.path.insert(0,"/usr/src/app")` if running a /tmp script.

Context: ADR-0002 (lucas42/lucos_backups#319) chose rsync `--link-dest` hardlink
snapshots for the photos volume, container-delivered source-side rsync (no host
binary on avalon), per-volume opt-in. restic-over-SFTP was the fallback, not needed.
aurora is BusyBox QTS 4.3.3, no Docker (ADR-0001), backup_root `/share/backups/`.
