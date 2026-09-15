---
name: pattern-backups-rsync-binary-missing-from-image
description: lucos_backups needs NO rsync on any host. copyTo() is scp (openssh-client); the photos incremental path runs rsync inside the lucos_backups image via `docker run`. This is the history of the 40-minute host-side rsync episode (#311 → reverted by #315) and its debugging lesson.
metadata:
  type: project
---

# lucos_backups: no source host needs rsync (current design, checked 2026-09-15)

**Current state on lucos_backups main, read from `src/classes/host.py` on 2026-09-15:**
- **Regular off-host copy:** `copyTo()` uses **`scp`** from the source host (host.py ~L262–269). It needs only openssh-client on the host.
- **Incremental strategy** (`lucos_photos_photos` only, ADR-0002): `rsyncVolumeSnapshot()` runs rsync **inside a container** on the source host, via `docker run` against the versioned lucos_backups image. That image's Dockerfile has `apk add … rsync`. The docstring says so: "so nothing is installed on the host". ADR-0002 §C1 records it as the deliberate response to #311.
- **Host prerequisites for backups:** Docker, plus `lucos_backups/init-host.sh`, which creates the `lucos-backups` user and its known_hosts, bind-mounted read-only for the incremental path. **No rsync binary on any host.**

⚠️ **This note's old title and description ("rsync runs on the SOURCE HOST") described the design as it stood before #315, in the present tense.** The body already recorded the revert, but the headline didn't. On 2026-09-15 I relayed that headline to team-lead as a live rebuild risk for avalon (lucos#296). The sysadmin had to disprove it: lucas42/lucos#296 comment 5688773150. **Before relaying a note as current fact, read the body, then check the code on origin/main.**

## History: 2026-06-08, a 40-minute episode

- lucos_backups#311 (merged 19:14:51Z) switched `copyTo()` from scp to host-side rsync over Fabric (`self.connection.run("rsync …")`). avalon had no rsync, so every avalon-source copy failed with `sh: 1: rsync: not found`.
- #313 added rsync to the container Dockerfile. That was the wrong layer: the copy ran on the host, so the fix changed nothing.
- **#315 (merged 19:54:25Z) reverted to scp**, raised the per-copy cap for large volumes instead, and removed rsync from the image. lucas42's policy: **don't provision extra binaries on hosts.** It was verified green on build 1.1.4 with a full ad-hoc create-backups run. rsync later came back in the image for the incremental path only, and it runs in a container (above).

## Durable lessons

1. **For a binary missing in code that runs commands over Fabric/SSH, find where the command executes** before you pick a layer. `self.connection.run` means the remote host; `docker run` means the image. Read the invocation, and don't trust `which` in whichever place is handy. In 2026-06 both the container and avalon lacked rsync, so the container check looked consistent and was still the wrong answer.
2. **A `/_info` green would never have caught this.** Backups is a cron path, and only an ad-hoc end-to-end run surfaces it.
3. **When you append a resolution to a note, update its title, description and index line in the same pass.** Otherwise the headline keeps asserting the superseded state.

See [[pattern_incremental_rsync_container_proxyjump_hostkey]] for the in-container rsync path's own host-key and ProxyJump bugs.
