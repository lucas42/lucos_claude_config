---
name: project-avalon-disk-failure
description: "avalon's single disk failed 2026-09-14 (P1, lucos#294) — data rescued to xwing+salvare, waiting on OVH disk swap, then rebuild; DNS zone expires 2026-10-12"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4bbebe53-ef86-40fb-8a57-6a86d4578b63
  modified: 2026-09-15T01:05:07.472Z
---

**Incident:** lucas42/lucos#294 (Critical, Owner lucas42). avalon (OVH/Kimsufi, 178.32.218.44) runs on ONE spinning disk, no RAID: HGST HUS726020ALA610, serial K5H8E1BA. It started failing ~07:55Z on 2026-09-14 (SMART: 29 pending, 109 offline-uncorrectable, 15,558 ATA errors). avalon services were down/degraded all day, and monitoring (which runs on avalon) went blind with it.

**State as of 2026-09-15 ~00:15Z:**
- avalon is booted into OVH rescue mode, disk mounted read-only at /mnt (left mounted on purpose). lucas42 updated the Kimsufi ticket asking for a disk replacement (text recorded on lucos#294). No support SLA, so the reply may take days.
- **All critical data rescued and verified** into `~lucos-agent/emergency-backups-2026-09-14/` on **xwing** (original) and **salvare** (checksum-verified copy). Dir mode 700, readable only by lucos-agent, so lucas42 needs root to use it. Its **README.md** is the restore guide: which file per volume, what not to restore (the damaged media_metadata tar.gz), the media_metadata recovery (restore `media.final.sqlite`), what was deliberately not copied.
- lucas42 decided: no full-disk image; lucos_photos_photos recovered via an Android resync instead; worlds images not needed.
- **DNS deadline:** the secondary (dns2.l42.eu on xwing) serves all 5 avalon-primary zones until **2026-10-12 07:09:51 UTC** and then goes dark. The zone is frozen (no record changes possible) until the lucos_dns primary is back, so bring it up first if the rebuild changes the IP.

**Rebuild runbook: lucas42/lucos#296** (Awaiting Decision, Critical, Owner lucas42). lucas42 answered on 2026-09-15:
- **No RAID or second disk.** He's in a year-long Kimsufi contract, so the rebuild stays single-disk; revisit at renewal. That makes lucos_docker_health#118 (disk-health check) more valuable.
- **The IP is whatever Kimsufi gives**, which only affects the DNS step.
- **The hostname is still his to decide:** keep `avalon` (Step 3) or pick a new one (Step 3a migration). lucos-architect recommends keeping `avalon`.
- **Also still his to decide (deferred to the ticket on 2026-09-15):** does the old disk count as exposed once OVH takes it?
  - lucos-architect says no: it's within OVH trust, so reuse the old SSH host keys.
  - lucos-security says yes: rotate the host keys, creds' `server_key` and aithne's store; accept the creds `data_key` risk with a tooling follow-up; optionally wipe before the swap.
  - The wipe option lapses once OVH swaps the disk.
- **Old SSH host keys** (ed25519/ecdsa/rsa; not DSA) are saved in `rescue/avalon-ssh-host-keys/` on xwing and salvare, verified against known_hosts. Delete that folder on both hosts if the decision is fresh keys.

Step 1 was trimmed after comparing it with his own `~/docker-host-setup.md` and with Debian defaults.

**Handover commissioned 2026-09-15:** SRE drafts the incident report as a DRAFT PR (to finish after the rebuild) and files follow-ups. Sysadmin files a rebuild/restore runbook issue. Check both landed and are boarded.

**When avalon, or its replacement, is back:**
- SRE's avalon watch is STOPPED, so nobody will notice automatically. Ping lucos-site-reliability for the end-to-end verification (including a real triggered backup run), then finishing the incident report, then their deferred ops checks 3 & 4.
- The 2026-09-14 `/routine` never ran its Phase 2 triage (paused for the incident). Run `/triage` then.
- Related parked work: lucos_backups#344 is Blocked on lucos_docker_health#117 (Ready/High, not yet dispatched).
