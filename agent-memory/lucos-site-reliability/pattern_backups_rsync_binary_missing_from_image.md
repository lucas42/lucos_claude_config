---
name: pattern-backups-rsync-binary-missing-from-image
description: lucos_backups scp→rsync swap (#311) needs rsync on the SOURCE HOST (runs via Fabric SSH), not the container — `rsync: not found` because avalon has no rsync; #313's Dockerfile fix was the wrong layer
metadata:
  type: project
---

# lucos_backups: rsync runs on the source HOST (Fabric), not in the container

On 2026-06-08, lucos_backups#311 switched the off-host volume copy from `scp` to
`rsync -az --partial --timeout=300` (to fix the `lucos_photos_photos` 600s-timeout
in #309). After deploy it failed with `sh: 1: rsync: not found`.

**CRITICAL ARCHITECTURE POINT — where rsync actually runs:** `classes/host.py:copyTo()`
runs the rsync via `self.connection.run("rsync …")`, where `self.connection` is a
**Fabric SSH connection to the SOURCE host** (`fabric.Connection(host=self.domain,
user="lucos-backups")`). So for an avalon volume the rsync executes **on avalon's host
shell**, NOT in the lucos_backups container. The container's PATH/binaries are
irrelevant to the copy step.

**Root cause:** **avalon (the busiest source host) has no rsync installed.** Old scp
worked because avalon has scp (openssh-client). Source-host rsync status (2026-06-08):
avalon = NONE (the gap), xwing 3.4.1, salvare 3.2.7, aurora 3.0.7. Volumes on
xwing/salvare/aurora copy fine; only **avalon-source** volumes fail (most services).

**The wrong fix (#313):** added `rsync` to the Alpine Dockerfile
(`apk add … rsync`). Container then HAD rsync 3.4.3 and the run STILL failed — proving
the copy never runs in the container. Harmless dead weight; not the fix.

**The right fix:** install rsync on **avalon** (host-level, **sysadmin** territory). No
redeploy needed — the running container picks it up on the next Fabric `run`. Then
re-run create-backups.

**Two debugging traps I hit here:**
1. `which rsync` **in the container** is the wrong place to check — the copy runs on the
   source host via Fabric. For lucos_backups copy failures, check `which rsync` **on the
   source host** (avalon/xwing/salvare/aurora), not the container.
2. Both the container AND avalon happened to lack rsync initially, so the container check
   gave a coincidentally-consistent wrong answer. The container-fix changing nothing was
   the disambiguator — **read the invocation code** (`self.connection.run` = host-side)
   before fingering a layer.

**Why this matters / how to apply:**
- **A `/_info` green would never have caught this** — backups is a cron path; only an
  actual end-to-end ad-hoc run surfaces it. Reinforces ad-hoc-rerun-is-authoritative.
- For a binary-dependency failure in code that runs commands over Fabric/SSH, the binary
  must exist **on the host the command targets**, not where the Python runs.
- See [[pattern_backups_empty_repo_fails_run]] and [[pattern_loganne_client_level_required_arg]]
  for other deterministic-won't-self-clear create-backups failures.
