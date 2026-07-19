---
name: pattern-hung-python-process-no-pyspy-use-faulthandler
description: py-spy/gdb are NOT installed on prod hosts or in containers and CapAdd is empty (no CAP_SYS_PTRACE) — to dump a hung Python process use pre-armed faulthandler + SIGUSR1, not py-spy
metadata:
  type: pattern
---

**`py-spy dump --pid <pid>` is not executable on this estate.** Do not record or follow it as a hang-diagnostic procedure — you will discover the gap mid-incident.

Verified on avalon 2026-07-19 (`lucos_photos_worker`):

- `which py-spy gdb` on the **host** → both absent
- `which py-spy` **inside the container** → absent
- `docker inspect ... HostConfig.CapAdd` → empty, so **no `CAP_SYS_PTRACE`**; py-spy fails from inside the container even if installed
- installing a profiler on prod mid-incident is a new host dependency needing lucas42's sign-off (see [[feedback_no_extra_host_binaries]]), and a bad use of a 180s window

**What actually works — stdlib `faulthandler`, but it must be armed in advance:**

```python
import faulthandler, signal
faulthandler.register(signal.SIGUSR1)   # non-fatal: dumps all thread stacks, process continues
```

Then, while the process is still hung:

```bash
docker kill -s USR1 <container>
docker logs --tail 100 <container>
```

Synergy worth remembering: faulthandler writes to **stderr**, and on this estate Python stdout is block-buffered in containers and silently swallows diagnostics while stderr reaches `docker logs` fine — see [[pattern_python_stdout_buffered_swallows_diagnostics]].

`PYTHONFAULTHANDLER=1` alone is **not** enough — it only fires on fatal signals/crashes, never on a hung-but-alive process.

**Status:** nothing is armed anywhere yet. Filed lucas42/lucos_photos#481 to add it to the photos worker. Until that merges, a recurrence of the 2026-07-18 work-horse hang is undiagnosable by construction.

**Context:** the 2026-07-18 hang is still **unexplained**. lucas42/lucos_photos#477's fork-from-threaded-parent logging-deadlock hypothesis was refuted (Python 3.14's logging registers `os.register_at_fork` handlers that reset the lock in the child). One explanation is refuted, not replaced — don't treat "zero log output before timeout" as evidence of deadlock-on-first-log-call. Related open defect in the same worker: lucas42/lucos_photos#475 (`with_scheduler=False` retry abandonment), see [[pattern_rq_scheduler_disabled_silently_drops_retries]].
