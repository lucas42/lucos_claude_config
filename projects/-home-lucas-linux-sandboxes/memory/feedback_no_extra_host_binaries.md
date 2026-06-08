---
name: feedback-no-extra-host-binaries
description: lucas42 prefers not installing extra binaries on hosts; favour tools already supported estate-wide
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b015b004-ba6f-4643-9a45-91fe3740c990
---

When a fix would require installing a new binary/package on production hosts, lucas42's strong preference is **not to** — favour a tool already supported everywhere instead.

Concrete case (2026-06-08): `lucos_backups` PR #311 switched the off-host copy from `scp` to `rsync` to fix a 6.6 GB photos-volume copy timeout. `copyTo()` runs the copy **host-side** (Fabric SSH to the source host), so rsync had to be present on every *source* host — avalon lacked it. The proposed fix was "install rsync on avalon"; lucas42 rejected it: *"No, we're not installing extra binaries on every host. Let's rollback the rsync decision. Go back to scp — that's already supported everywhere."* The timeout was then re-solved scp-compatibly (raise/parameterise the per-copy wall-clock cap).

**Why:** every extra host binary is provisioning drift — another thing to install on a rebuild, keep patched, and reason about across heterogeneous hosts (e.g. avalon vs QNAP aurora). `scp`/`openssh-client` is already everywhere; reusing it keeps hosts uniform and avoids per-host provisioning.

**How to apply:** before proposing a fix that adds a host-level dependency, check whether an already-present tool does the job. If a new binary genuinely seems necessary, surface the host-provisioning cost explicitly and get lucas42's nod first — don't assume "just install it" is acceptable. Prefer solving within the existing toolset (timeouts, flags, app-layer changes) over new host software. Related: [[feedback-dont-shift-work-to-coordinator]].
