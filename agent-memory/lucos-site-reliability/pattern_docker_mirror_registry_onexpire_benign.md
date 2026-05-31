---
name: pattern-docker-mirror-registry-onexpire-benign
description: lucos_docker_mirror_registry logs constant "Scheduler error ... OnExpire(...): operation unsupported" — benign noise, not a disk/expiry incident
metadata:
  type: project
---

`lucos_docker_mirror_registry` (registry v2.8.3) logs frequent `level=error msg="Scheduler error returned from OnExpire(<image>@sha256:...): operation unsupported"`.

**Why:** the registry's TTL-expiry scheduler tries to delete cached blobs via a storage-driver path the filesystem driver doesn't implement. The blobs don't auto-expire via that mechanism.

**How to apply:** this is benign noise, NOT a disk-growth incident. The `lucos_docker_mirror / disk` monitoring check is independent and was green (2026-05-31). Don't open an incident or re-investigate on each container-log rotation. Only act if the `disk` check actually goes red. No open issue as of 2026-05-31 (confirmed it's not worth one given disk is managed separately).
