---
name: project-avalon-disk-failure-294
description: ACTIVE INCIDENT lucas42/lucos#294 — avalon's single disk failed 2026-09-14; data rescued to xwing+salvare; waiting on OVH swap then rebuild; draft report lucos#297; what to do when avalon returns
metadata:
  type: project
---

**State as of 2026-09-15 ~01:15 UTC: avalon is DOWN, waiting on OVH/Kimsufi to replace its failed disk (no support SLA, could take a while). All critical data has been rescued and verified.** The canonical current-state summary is the body of lucas42/lucos#294. Re-read it before acting; it will have moved on.

**Where things are:**
- **Data:** `~lucos-agent/emergency-backups-2026-09-14/` on **xwing (original) and salvare (copy)**, both mode 700, sha256-verified. **`README.md` there is the restore guide:** which file per volume, how each copy was taken and verified, what wasn't copied, and checksums.
  - media_metadata: restore `rescue/media.final.sqlite` as `media.sqlite` (no -wal/-shm, owner 1001:1001). **Never restore** the damaged `.tar.gz`.
  - worlds: the rescue copy has lucas42's edits to 00:16:29Z on 09-14. Images come from the 09-13 nightly `web_storage` backup (all references verified present).
  - **SSH host keys (PRIVATE):** `rescue/avalon-ssh-host-keys/`, copied 2026-09-15. **DECIDED 2026-09-15** (lucas42, on the architect's advice on #296): keep the hostname avalon and the same IP, and **reuse the ed25519/ecdsa/rsa pairs; don't install DSA.** **The host keys are NOT rotated** (per #298). Security's rotation follow-ups are lucas42/lucos#298 (creds server_key + aithne store, Blocked on #296) and lucas42/lucos_creds#565 (data_key tooling), both rows in #297. **Delete the dir on BOTH xwing and salvare once the keys are installed and an existing client connects with no warning.** That's a #297 follow-up row.
  - **A credential-exposure disposition is recorded privately, not in this repo.**
- **Host:** in OVH rescue mode, `/dev/sda2` mounted `ro,norecovery` at `/mnt`, **left mounted on purpose** until OVH swaps the disk. Reach it with `ssh -i ~/.ssh/id_ed25519_lucos_agent -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@178.32.218.44`. By IP, not `avalon.s.l42.eu`, so the rescue host key isn't saved against avalon's name.
- **salvare** (IPv6-only from the sandbox, and its name was flaky tonight): `ssh -i ~/.ssh/id_ed25519_lucos_agent -o IdentitiesOnly=yes -o HostKeyAlias=salvare.s.l42.eu -J xwing.s.l42.eu lucos-agent@2a01:4b00:8598:5a00:f669:f6da:e174:624b`.
- **Incident report:** DRAFT PR **lucas42/lucos#297**, branch `incident-report-avalon-disk-failure`, worktree `~/sandboxes/.worktrees/lucos-incident-avalon`. Resolution, end time and verification are TBD. Keep it in draft until resolved, then notify the 6 teammates on the draft, fold in their responses, and only then mark ready → review → merge (`references/incident-reporting.md`).
- **Rebuild procedure:** **lucas42/lucos#296** (sysadmin's runbook; Awaiting Decision / Critical / owner lucas42; item 2 covers RAID). **Disk layout decided: stays SINGLE-DISK for now (year-long contract, revisit at renewal)**, per lucas42 on #296. Recorded in #297 and commented on docker_health#118. Linked in #294 and #297. Sysadmin will ask SRE for the data-restore specifics.
- **Follow-ups filed (triaged 2026-09-15):** lucas42/lucos_backups#415 (15:25 vs 03:25): **Needs Analysis / Medium / OWNER ME, deliberately HELD until avalon is back. Don't start early.** Before Ready, its body must settle the fork I left open: a persistent `last_success` marker vs taking the 15:25 decision off the marker entirely. It is NOT a lucas42 decision; #225 plus his own statement already settle 03:25-primary. lucas42/lucos#295 (alert chain on avalon): Awaiting Decision / Low. lucas42/lucos_docker_health#118 (disk health): Awaiting Decision / Medium. a comment on lucas42/lucos#290 (the 4h20m gap; trigger 2 met; alert emails verified sent: 223 `status=sent`).
- **DNS deadline:** avalon is the primary for 5 zones (l42.eu, s.l42.eu, lukeblaney.co.uk, rowanblaney.co.uk, tfluke.uk). They **expire at 2026-10-12 07:09:51 UTC** unless a primary is back. No issue, by lucas42's decision (he expects the rebuild in days).
- **Deferred:** ops Checks 3 and 4 from 2026-09-14 (they wait until avalon is back). lucos_backups#344's switch-on also needs the rebuilt avalon (it's Blocked on docker_health#117 anyway).

**When avalon is back:**
1. Help sysadmin restore per the README.
2. Verify end to end, including a **triggered `create-backups` run** (a green `/_info` isn't enough).
3. Fill in #297's Resolution section and run its review steps.
4. Update #294.
5. Re-run the deferred ops checks.

Lessons from tonight are in [[reference-avalon-single-disk-no-raid]], [[pattern-piped-copy-receiver-cannot-detect-truncation]] and [[pattern-docker-pause-reports-unhealthy]], plus instruction commits 0406391 and f431318.
