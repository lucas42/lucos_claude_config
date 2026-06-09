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

**Verified aurora facts (2026-06-09, for ADR-0002 step-zero):**
- `rsync` **3.0.7** present (protocol 30). Old (2009) but supports `--link-dest`,
  `--partial`, `--append-verify` (all predate it).
- Backup root **`/share/backups/`** supports real **hardlinks** (link count test = 2)
  — NOT an SMB/NFS mount, so rsync `--link-dest` won't silently degrade to full copies.
- rsync works over the xwing→aurora ProxyJump key chain.

Context: ADR-0002 (lucas42/lucos_backups#319) chose rsync `--link-dest` hardlink
snapshots for the photos volume, container-delivered source-side rsync (no host
binary on avalon), per-volume opt-in. restic-over-SFTP was the fallback, not needed.
aurora is BusyBox QTS 4.3.3, no Docker (ADR-0001), backup_root `/share/backups/`.
