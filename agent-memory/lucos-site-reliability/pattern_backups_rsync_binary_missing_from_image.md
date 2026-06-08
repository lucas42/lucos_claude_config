---
name: pattern-backups-rsync-binary-missing-from-image
description: lucos_backups scp→rsync swap (#311) shipped without adding rsync to the Alpine image — `rsync: not found` broke ALL volume off-host copies, not just the targeted ones
metadata:
  type: project
---

# lucos_backups: command-swap without the binary in the image

On 2026-06-08, lucos_backups#311 switched the off-host volume copy from `scp` to
`rsync -az --partial --timeout=300` (to fix the `lucos_photos_photos` 600s-timeout
in #309). The code shipped and deployed (image `1.1.2`, 19:16) but **the rsync
binary was never added to the image**. lucos_backups base is `python:3.14.5-alpine`;
Dockerfile installs `apk add sed curl openssh-client` — no rsync. `scp` was present
(openssh-client), rsync was not.

**Diagnostic signature:** `sh: 1: rsync: not found` →
`backupToAll failed for N host(s): aurora, salvare, xwing` on the **first** volume,
then every subsequent volume. So the blast radius is the **whole estate's off-host
replication**, not just the volume the fix targeted. Local archives (tar step) still
succeed — it's lost off-host redundancy, not total data loss. P2, worsening (every
run fails until rsync installed).

**Fix:** add `rsync` to the apk line (`apk add sed curl openssh-client rsync`),
redeploy, re-run create-backups.

**Remote-end note:** rsync must exist on both ends. xwing (3.4.1) and salvare (3.2.7)
have it; aurora (QNAP NAS, aurora.lan) was unverified — host-level/sysadmin check.

**Why this matters / how to apply:**
- **A `/_info` green would never have caught this** — backups is a cron path; the bug
  only surfaced on an actual end-to-end run. Reinforces the ad-hoc-rerun-is-authoritative
  rule. The whole point of the ad-hoc verify was to catch exactly this.
- When reviewing/verifying any fix that **swaps a shell command for one with a different
  binary dependency**, the first question is "is the new binary in the image?" — Alpine
  ships almost nothing; `which <binary>` in the container is a 5-second check.
- See [[pattern_backups_empty_repo_fails_run]] and [[pattern_loganne_client_level_required_arg]]
  for other deterministic-won't-self-clear create-backups failures.
