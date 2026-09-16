---
name: project-avalon-disk-failure
description: "avalon's disk failed 2026-09-14 (P1, lucos#294); rebuilt on Debian Trixie overnight 2026-09-15/16 — estate restored, open items tracked on lucos_mail#79, lucos_dns#135"
metadata: 
  node_type: memory
  type: project
  originSessionId: 62c49c10-849c-44f7-bb03-e762ea998642
  modified: 2026-09-16T02:21:46.149Z
---

**Incident:** lucas42/lucos#294. avalon (OVH/Kimsufi, 178.32.218.44, single disk, no RAID) failed 2026-09-14. Data rescued to `~lucos-agent/emergency-backups-2026-09-14/` on xwing and salvare; its **README.md is the restore guide**. **Standing rule (lucas42, 2026-09-16): nothing is deleted from that directory until everything is restored and verified, and for a while after** — including `rescue/avalon-ssh-host-keys/`.

**Rebuild, 2026-09-15/16** (runbook lucas42/lucos#296, kept current by the sysadmin):
- lucas42 provisioned the host himself from his own `~/docker-host-setup.md`, on **Debian Trixie**, same IP, **freshly generated SSH host keys** (the rescued ones were never installed). #296's Step 1 is NOT a record of what was done.
- **Port 53 gotcha, now in Step 1:** systemd-resolved's stub listener holds 53 and blocks the DNS container; `DNSStubListener=no` + symlink `/etc/resolv.conf` → `/run/systemd/resolve/resolv.conf`. The setting may be absent, commented, or `yes`. It also caused container name-resolution failures.
- **Bootstrap order that actually works:** lucos_creds first (only service with the `LUCOS_DEPLOY_ENV_BASE64` bypass), then configy, docker_mirror, dns, router, firewall, monitoring, loganne, aithne, everything else, arachne last. `init-host.sh` needs creds up. Nothing else can deploy or build while creds is down — lucas42/lucos#299 (Ready, docs-only per his decision) and lucas42/lucos_deploy_orb#188 (High; mirror probe misreads a refused connection).
- **Restore gotchas:** rescue tarballs keep the full original path (`<vol>/_data/...`) unlike nightlies; `mv` globs skip dotfiles; `restore-volume.sh`'s `docker compose up --no-start` breaks on multi-service compose files; a container can be "healthy" yet unreachable.
- Deploys queue because the pipeline **deliberately limits concurrent deploys per node** (`serial-group: deploy-avalon`), not CircleCI capacity.

**Open after the rebuild:** lucas42/lucos_mail#79 (Critical — production SMTP down, dovecot version error on an unchanged image, unexplained), lucas42/lucos_dns#135 (Critical — the xwing DNS secondary has been unable to write zone files since ~26 Aug, serving five zones from memory only), lucas42/lucos_media_linuxplayer#146, lucas42/lucos_monitoring#312 + #300, lucas42/lucos_root#158. The `weighting` integrity check on media_metadata_api should clear when `lucos_media_weightings/all-tracks` next runs; if not it's a real restore defect.

**Still owed:** the incident report PR lucas42/lucos#297 (draft, SRE), converting its follow-up table into tickets, lucas42's decision on re-running `lucos_firewall`'s deploy pipeline, and the `/triage` pass that the 2026-09-14 routine never ran.
