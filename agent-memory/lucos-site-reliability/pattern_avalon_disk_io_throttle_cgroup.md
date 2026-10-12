---
name: pattern-avalon-disk-io-throttle-cgroup
description: Throttling bulk disk work on avalon — ionice is a no-op (mq-deadline); docker --device-*-bps/iops (cgroup v2 io.max) works; ⚠️ the capped job inflates host PSI itself, so gauge OTHER cgroups' io.pressure
metadata:
  type: pattern
---

avalon has a single rotational disk (sda, 7200rpm HGST) with the `mq-deadline` scheduler, so **`ionice` does nothing**. What works: run the bulk job in a container with `--device-read-bps /dev/sda:10mb --device-write-bps /dev/sda:10mb --device-read-iops /dev/sda:100 --device-write-iops /dev/sda:100 --memory 512m`. cgroup v2 + ext4 means io.max throttles buffered writes too. `--memory` bounds the dirty page cache so writeback can't queue one huge flush.

Verified 2026-10-11 with a positive control: capped direct read 10.2MB/s vs 52MB/s uncapped; capped write+fdatasync 8.1MB/s. Read back the cap at `/sys/fs/cgroup/system.slice/docker-<id>.scope/io.max`.

**Gauge — NOT host-wide PSI while a capped job runs.** A task waiting on its own io.max cap counts as an IO stall, so the capped job inflates `/proc/pressure/io` by itself (2026-10-11 23:15: host avg60 31%, extract cgroup 30%, every other container <1%). Measure harm as the busiest *other* container's `/sys/fs/cgroup/system.slice/docker-<id>.scope/io.pressure` (stop if avg60 >10 twice). Host PSI is fine as a baseline when nothing capped is running: Quiet avalon reads `some avg10` 1–9%. An uncapped 36GB `tar -xzf` pushed it to ~95% and timed out several `/_info`s. A lucos_photos deploy (multi-GB image pull) alone pushed it to 53%. See [[pattern-image-pull-tail-stalls-avalon-processes]].

**Why:** the 2026-10-11 Takeout extraction storm (lucas42/lucos_photos#577, runbook PR #586).
**How to apply:** any multi-GB copy, extract or scan on avalon → capped container, never bare; and don't overlap it with a lucos_photos deploy.

**Caps don't cover everything (2026-10-12 full-import stall):**
- avalon runs about 1.9GB of swap on the same single disk, so memory pressure turns into IO stalls for idle services. lucos_campaigns_db and lucos_worlds_db were mostly swapped out. repos, creds and campaigns `/_info` all timed out while every other container's IO PSI stayed under 10.
- The photos worker copies uploads into originals with `shutil.move` across volumes, i.e. a full uncapped copy, which bursts on videos.
- So bound the worker's *duty cycle* (an upload rate limit), not the uploader's reads. Treat multi-service fetch-info failures as the real signal.
