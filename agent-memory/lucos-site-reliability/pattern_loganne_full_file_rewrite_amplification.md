---
name: pattern-loganne-full-file-rewrite-amplification
description: lucos_loganne rewrites its whole ~24MB events.json on every state change (≤1/s), so any event stream becomes ~10–24MB/s of disk writes on avalon — the hidden disk cost of bulk jobs that emit events
metadata:
  type: pattern
---

lucos_loganne persists by `fs.writeFile(STATE_FILE, JSON.stringify(events))`: the whole 10,000-event array (~24MB) on every change, throttled to at most once a second (`SAVE_THROTTLE_MS`). A steady trickle of events therefore costs ~10MB/s of writes, and any burst costs ~24MB/s.

Measured 2026-10-12 during the lucos_photos Takeout trial import: loganne wrote 9–12MB/s and saved every 1–2s, driven by lucos_photos `photoAdded`/`photoProcessed`/`profilePhotoUpdated`. It was the biggest writer on avalon's single HDD, and was still at 9MB/s after the uploads stopped. Its 3-day average was ~0.2MB/s. The photos worker's own IO was ~0.14MB/s; its 29% PSI was contention from loganne.

**How to apply:** when a bulk job's disk cost doesn't add up, check loganne's cgroup `io.stat` first. Treat loganne as part of the job's load when gauging harm to other services. Filed as lucas42/lucos_loganne#651 (2026-10-12): 30s throttle + SIGTERM flush. See [[pattern-avalon-disk-io-throttle-cgroup]].
