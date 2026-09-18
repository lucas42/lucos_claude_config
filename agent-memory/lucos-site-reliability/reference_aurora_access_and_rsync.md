---
name: aurora-access-and-rsync
description: aurora QNAP: the agent has NO deliberate access. Don't borrow the lucos_backups container's key (lucas42, 2026-09-18); ask lucas42. rsync 3.0.7 + hardlinks confirmed.
metadata:
  type: reference
---

**⚠️ GATEWAY IS xwing, NOT avalon (verified live 2026-09-16).** `lucos_configy` `config/hosts.yaml` gives aurora `ssh_gateway: xwing`, `domain: aurora.lan`, `ipv4: 192.168.8.143` — and `ssh-keyscan aurora.lan` run *on xwing* returns `SSH-2.0-OpenSSH_7.6`. lucas42/lucos#296's Step 5 said "only reachable via avalon"; that was wrong and is now corrected. **But reachability splits in two:** the network path is xwing→aurora and needs no avalon, while the only credential that authenticates lives in the `lucos_backups` container on avalon. So during a total avalon outage aurora is *reachable but not usable* — tracked as lucas42/lucos#301.

**⛔ DO NOT use the `lucos_backups` container's key to reach aurora (lucas42, 2026-09-18, lucas42/lucos#301).** I did this for ad-hoc checks on 2026-06-09 and 2026-09-16 by running Fabric's `Host("aurora")` inside the container. lucas42: *"I'd prefer agents avoid using credentials they've stealthily gained access to; and we build processes on deliberately granted permissions."* He has his own access to aurora and would rather be asked. **To check anything on aurora, ask lucas42.** A deliberate policy (lucos-agent read access to backups on all backup-storing hosts) is being designed on lucas42/lucos#301 with lucos-security; use it once it exists.

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

Context: ADR-0002 (lucas42/lucos_backups#319) chose rsync `--link-dest` hardlink
snapshots for the photos volume, container-delivered source-side rsync (no host
binary on avalon), per-volume opt-in. restic-over-SFTP was the fallback, not needed.
aurora is BusyBox QTS 4.3.3, no Docker (ADR-0001), backup_root `/share/backups/`.
