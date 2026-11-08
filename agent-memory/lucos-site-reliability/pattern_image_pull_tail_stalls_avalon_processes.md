---
name: pattern-image-pull-tail-stalls-avalon-processes
description: Large image pulls (lucos_photos_worker 3.48GB) stall other processes on avalon during layer extraction; JVM safepoint logs detect it; JDK HttpClient connectTimeout excludes DNS; ROOT CAUSE = no CI layer cache + ARG VERSION first (lucos_photos#668)
metadata:
  type: project
---
On 2026-09-29 the lucos_media_manager fetch failed with `HttpConnectTimeoutException` 38s after it started, during the final ~90s of a lucos_photos deploy's `Pull container(s)` step. The network was fine: other containers' traffic flowed normally. The JVM itself was stalled, with time-to-safepoint 133ms against a 0.006ms median. lucas42/lucos_media_manager#302.

**Why:** extracting a 3.48GB image's layers on avalon (single disk, 7.8GB RAM, swap in use) stalls unrelated processes for about a minute. The mechanism is unverified: no sysstat, and the journal needs `adm`.

**How to apply:**
- For a one-off timeout on avalon, line it up against CircleCI deploy `Pull` step timings (v1.1 job steps) before blaming the network.
- Stall detectors: media_manager's safepoint log (`Reaching safepoint`), and stretched intervals between Docker healthcheck log lines. Ignore lucos_backups' hourly `:06` stretches, which are its own backup job.
- JDK 25 `java.net.http`: the DNS lookup happens in `Http1Exchange`'s constructor, *before* the connect timer is registered, so `connectTimeout` covers the TCP connect only.

**Root cause (2026-11-08):** every photos release ships ~1.7GB of *unchanged* layers (pip 760MB, model 631MB, api pip 165MB). Two causes: the orb uses a fresh buildx builder with no cache, and `ARG VERSION` sits right after `FROM`. Both need fixing (lucas42/lucos_photos#668). Hit campaigns.l42.eu the same day (pull 23:00:47–23:04:43). The pull's IO is charged to `containerd.service`, not to any docker scope, so per-container io.stat shows nothing.
