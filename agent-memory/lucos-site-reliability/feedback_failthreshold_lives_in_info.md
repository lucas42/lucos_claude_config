---
name: failThreshold lives in /_info, not lucos_monitoring
description: Per-system check thresholds (failThreshold, etc.) are declared by each service in its /_info response — lucos_monitoring holds no system-specific config
type: feedback
---

System-specific check thresholds (failThreshold and any equivalents) belong in the service's `/_info` response, not in lucos_monitoring config. lucos_monitoring is generic — it holds no system-specific logic.

**Why:** lucas42 corrected this 2026-05-05 when I proposed raising a `failThreshold` issue against lucos_monitoring. Quoting: "the failThreshold config comes from the /_info endpoint, so it'll need to be raised against [the service] - we don't hold any system-specific logic in lucos_monitoring." Architectural rule: each system owns config that's specific to its own checks.

**How to apply:** When proposing changes to per-check thresholds, check suppression behaviour, or any per-system tuning of monitoring sensitivity, raise the issue against the **service repo** (whose `/_info` declares the check) — not against lucos_monitoring.

**Exception:** Generic checks that lucos_monitoring runs on every system from the outside (e.g. `fetch-info`, `tls-certificate`, `circleci`) — those *are* lucos_monitoring's own logic. PR lucos_monitoring#195 added `failThreshold: 2` to those because they're cross-cutting probes. The dividing line: if the check name appears in the service's own `/_info` response (like `empty-queue` does for media_manager), config belongs there. If lucos_monitoring synthesises the check itself, config lives in lucos_monitoring.

**Related fix-shape rule:** When a service-specific check is flapping during a known-good transient state, the cleanest fix is usually inside the service's `/_info` handler — refining the check's `ok` semantics so that the transient state isn't reported as a fault in the first place. Example (lucos_media_manager#239): `empty-queue` reports `ok: true` while a fetcher thread is alive, because "queue is empty but being repopulated" is intended behaviour. Smaller diff than tweaking thresholds, doesn't mask real faults.
