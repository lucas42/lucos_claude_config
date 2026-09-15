---
name: project-avalon-disk-failure-2026-09
description: avalon's single-disk failure incident (2026-09-14) — state, deadlines, and where the rebuild runbook lives
metadata:
  type: project
---

avalon (OVH/Kimsufi, 178.32.218.44, single HGST spinning disk, no RAID) started failing 2026-09-14 ~07:55 UTC (disk latency ~500x normal, ~2 IOPS). Escalated to lucos-site-reliability same day. Host wedged ~19:21 UTC, rebooted into OVH rescue mode ~22:38 UTC by lucas42. As of 2026-09-15, waiting on OVH to replace the disk — no guaranteed-SLA support (Kimsufi), so no ETA. lucas42's framing: tidy up so a **future session with no memory of this incident** can execute the rebuild cold.

**Why:** confirmed root cause is hardware (SMART: 29 pending sectors, 109 offline-uncorrectable, climbing I/O error counter), not something fixable in software. avalon hosts ~20 services including `lucos_dns` (primary), `lucos_configy`, `lucos_creds`, `lucos_router`, `lucos_backups` (sole estate-wide backup orchestrator) — so this is a full-estate-impact incident, not just avalon's own services.

**Key artefacts (all still relevant when this resumes):**
- Full incident thread: lucas42/lucos#294
- **Rebuild/restore runbook** (mine, filed 2026-09-15): lucas42/lucos#296 — host provisioning, DNS ordering (incl. the configy/DNS chicken-and-egg if avalon's IP changes on rebuild), CI redeploy order/priorities, volume restore summary, open questions for lucas42 (same IP/hardware? RAID this time?)
- **Data restore source of truth**: `/home/lucos-agent/emergency-backups-2026-09-14/README.md` on xwing AND salvare (identical, 700-perm, lucos-agent-only). Written by lucos-site-reliability. Covers per-volume restore source, verification, and the `lucos_media_metadata_api_db` special case (`media.final.sqlite`, hand-repaired from 14 bad disk sectors, do NOT use the plain rescue tarball — it's ~96% zero-filled). Do not re-derive restore procedure from scratch — read this file.
- **DNS hard deadline: 2026-10-12 07:09:51 UTC.** Secondary (`dns2.l42.eu`, xwing) last synced with avalon's primary at 2026-09-14 07:09:51 UTC; SOA expire is 28 days. Past the deadline, all of `l42.eu`/`s.l42.eu`/`lukeblaney.co.uk`/`rowanblaney.co.uk`/`tfluke.uk` stop resolving estate-wide. Derivation posted as a comment on lucos#294. Confirmed (2026-09-14/15) the secondary itself is healthy and answering correctly in the meantime — this is a future deadline, not a current outage.
- Host-level config captured from the rescue mount (not CI-managed, per ADR-0008): `/etc/docker/daemon.json` (ipv6 fixed-cidr-v6 2001:41d0:8:dc2c::1/64, live-restore true, registry mirror docker.l42.eu), account UIDs (lucas=1001, docker-deploy=1002, lucos-agent=1003, lucos-backups=999), authorized_keys for root/lucas/debian/docker-deploy/lucos-backups/lucos-agent, sudoers (lucas + debian NOPASSWD only), netplan/sysctl. No user crontabs existed. SSH host keys and /etc/shadow deliberately not preserved (fine — fresh host keys expected, access is key-based).

**No full-disk image was taken** — lucas42's explicit decision once targeted volume copies were verified. Anything not in the emergency-backups dir or the regular nightly backups is gone; the README's "Deliberately NOT copied" table lists what and why (photos originals — re-sync from Android app; arachne fuseki index — regenerable; worlds web_storage — covered by the 09-13 nightly).

**Open questions for lucas42** (listed in #296, not decided by the team): same hardware/IP vs moving services elsewhere; RAID or second disk this time.

**Ops-checks note**: SRE's live-monitoring watch on avalon was stopped once rescue work paused for the disk-replacement wait — ping lucos-site-reliability when avalon is confirmed back before resuming normal ops checks against it. Routine ops-check coverage of avalon is effectively suspended until then.

**Status as of 2026-09-15**: waiting on OVH. Runbook (#296) and data (emergency-backups dir) are the two things a resuming session needs; both are cross-referenced from lucos#294.
