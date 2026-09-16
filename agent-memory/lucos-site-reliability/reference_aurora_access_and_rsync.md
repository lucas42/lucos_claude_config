---
name: aurora-access-and-rsync
description: aurora QNAP is not reachable by the agent SSH key directly; reach it via the lucos_backups container's fabric/ProxyJump path. rsync 3.0.7 + hardlinks confirmed.
metadata:
  type: reference
---

**⚠️ GATEWAY IS xwing, NOT avalon (verified live 2026-09-16).** `lucos_configy` `config/hosts.yaml` gives aurora `ssh_gateway: xwing`, `domain: aurora.lan`, `ipv4: 192.168.8.143` — and `ssh-keyscan aurora.lan` run *on xwing* returns `SSH-2.0-OpenSSH_7.6`. lucas42/lucos#296's Step 5 said "only reachable via avalon"; that was wrong and is now corrected. **But reachability splits in two:** the network path is xwing→aurora and needs no avalon, while the only credential that authenticates lives in the `lucos_backups` container on avalon. So during a total avalon outage aurora is *reachable but not usable* — tracked as lucas42/lucos#301.

**WORKING RECIPE (used 2026-09-16 to verify post-rebuild backups):** run it through the tool's own Fabric path rather than hand-rolling ssh — a hand-rolled `-J` hits `Host key verification failed` at the jump hop, because the flag doesn't reach the gateway connection:
```sh
docker exec lucos_backups sh -c 'cd /usr/src/app && . scripts/init-agent.sh >/dev/null 2>&1; pipenv run python -c "
from classes.host import Host
h = Host(\"aurora\")
print(h.connection.run(\"ls /share/backups/host/avalon/volume/ | wc -l; df -h /share/backups | tail -1\", hide=True, warn=True).stdout)
"'
```
`Host(name)` reads hosts.yaml and builds the gateway Connection itself. 2026-09-16 result: 23 archives dated that day, `/dev/md0` 3.6T, 1007G free, 73% used.

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
