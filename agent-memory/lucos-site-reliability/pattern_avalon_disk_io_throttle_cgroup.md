---
name: pattern-avalon-disk-io-throttle-cgroup
description: Throttling bulk disk work on avalon — ionice is a no-op (mq-deadline); docker --device-*-bps/iops (cgroup v2 io.max) works, verified 2026-10-11
metadata:
  type: pattern
---

avalon has a single rotational disk (sda, 7200rpm HGST) with the `mq-deadline` scheduler, so **`ionice` does nothing**. What works: run the bulk job in a container with `--device-read-bps /dev/sda:10mb --device-write-bps /dev/sda:10mb --device-read-iops /dev/sda:100 --device-write-iops /dev/sda:100 --memory 512m`. cgroup v2 + ext4 means io.max throttles buffered writes too. `--memory` bounds the dirty page cache so writeback can't queue one huge flush.

Verified 2026-10-11 with a positive control: capped direct read 10.2MB/s vs 52MB/s uncapped; capped write+fdatasync 8.1MB/s. Read back the cap at `/sys/fs/cgroup/system.slice/docker-<id>.scope/io.max`.

**Gauge:** `/proc/pressure/io`. Quiet avalon reads `some avg10` 1–9%. An uncapped 36GB `tar -xzf` pushed it to ~95% and timed out several `/_info`s. A lucos_photos deploy (multi-GB image pull) alone pushed it to 53%. See [[pattern-image-pull-tail-stalls-avalon-processes]].

**Why:** the 2026-10-11 Takeout extraction storm (lucas42/lucos_photos#577, runbook PR #586).
**How to apply:** any multi-GB copy, extract or scan on avalon → capped container, never bare; and don't overlap it with a lucos_photos deploy.
