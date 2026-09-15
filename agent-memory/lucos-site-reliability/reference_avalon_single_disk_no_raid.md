---
name: reference-avalon-single-disk-no-raid
description: avalon = OVH dedicated server on ONE spinning HDD (HGST HUS726020AL 2TB 7200rpm), NO RAID; disk-failure triage via sysfs ioerr_cnt + /proc/diskstats without root
metadata:
  type: reference
---

**avalon's storage (verified 2026-09-14 from sysfs):** a single physical HDD, `sda` = HGST HUS726020AL (2TB, 7,200rpm, `rotational=1`), with **no RAID** (`/proc/mdstat` has no arrays, and `sda` is the only block device). It's an OVH dedicated server in France, 178.32.218.44, Debian bookworm. Every avalon service and database volume lives on that one spindle. A failing disk means data at risk plus an estate-wide outage, and replacing it means a rebuild. Only lucas42 has OVH manager access.

**Healthy baseline:** about 20ms average per read (lifetime `/proc/diskstats`).

**2026-09-14 incident (lucas42/lucos#294):** reads averaged 4–10s each, only ~2–8 operations completed per second, I/O pressure `some` was 99.9%, and `ioerr_cnt` rose 6 in 8s.

**Triage without root, and without extra disk I/O:**
- `grep " sda " /proc/diskstats` twice, N seconds apart. Latency = Δ read-ms (field 7) ÷ Δ reads (field 4); same for writes (fields 11 and 8).
- `/sys/block/sda/device/{ioerr_cnt,iorequest_cnt,iodone_cnt}`: a rising `ioerr_cnt` means a failing device.
- `/proc/pressure/{io,memory}` and the per-cgroup `memory.pressure` / `memory.current`.

`ps`, `df`, `lsblk` and `dmesg` all hang on a stalled disk: `ps` blocks on `/proc/*/cmdline` of D-state processes. Use `/proc/*/stat` plus `/proc/*/wchan` instead. Don't leave hung probes behind; mine added three D-state `ps` processes.

**Tell-tale that separates a failing device from overload:** I/O pressure near 100% while throughput is tiny. An overloaded disk is busy *and* moving data.

**Backups for avalon:** tarballs go to xwing (`/srv/backups/host/avalon/volume/`) and salvare. Photos go ONLY to aurora (incremental; `skip_backup_on_hosts: salvare, xwing`), and aurora is only reachable via avalon's lucos_backups container. So verifying photos backups depends on avalon being up.

**Confirmed failed (2026-09-15, SMART read in rescue mode):** serial **K5H8E1BA**, 75,190 power-on hours; Current_Pending_Sector 29, Offline_Uncorrectable 109, Reallocated 1, ATA error count 15,558 (UNC). **The overall verdict still said PASSED**, so never trust that verdict alone. `smartctl` IS available in OVH rescue mode. The error log's lifetime hours wrap at 65,536.
