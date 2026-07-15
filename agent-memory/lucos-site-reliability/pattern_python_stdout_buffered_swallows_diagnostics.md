---
name: pattern-locations-info-server-stdout-swallowed
description: Long-lived Python services started without -u/PYTHONUNBUFFERED block-buffer stdout, so print() diagnostics NEVER reach docker logs (lucos_locations#103)
metadata:
  type: pattern
---

**A `print()` in a long-lived Python container process is invisible unless stdout is unbuffered.** Python block-buffers stdout when it is not a TTY (i.e. always, under docker). The buffer (~8KB) only flushes when full or **at process exit** — and a `serve_forever()` process never exits. So the diagnostics are written and silently discarded, forever.

**Found:** 2026-07-15 ops checks, `lucos_locations` otfrontend. Monitoring recorded the `location-freshness` debug `"Failed to fetch last recorded location data from the recorder"` — a string emitted **only** from the `except` branch of `get_location_age_seconds()`, which also does `print(f"Error fetching location data: {e}")`. Yet `docker logs | grep -ci "Error fetching location data"` = **0**, over a window fully covered by the container (`StartedAt` 07-10, `restarts=0` — so NOT [[pattern-container-restart-log-buffer-artifact]]). Filed **lucos_locations#103** (P3). Cause: `startup.sh` runs `python3 /app/info_server.py &` with no `-u` and no `PYTHONUNBUFFERED`.

**The tell:** monitoring/Loganne has evidence of an error path firing, but `docker logs` has zero matching lines *and* the container hasn't restarted. Before blaming a missing log statement or a phantom event — check the buffering.

**Verify it in ~30s (direct evidence, don't just assert it):**
```sh
docker exec <c> sh -c 'ls -l /proc/<pid>/fd/1'   # -> pipe:[...] = not a TTY
docker exec <c> sh -c 'python3 -c "import sys; print(sys.stdout.isatty(), sys.stdout.line_buffering, file=sys.stderr)" | cat'
#   stdout -> False False  == BLOCK-buffered (swallowed)
#   stderr -> False True   == line-buffered (these lines DO appear)
# Demo the swallow: an early print + sleep, both lines land at the SAME time (at exit):
docker exec <c> sh -c 'python3 -c "import time; print(\"EARLY\"); time.sleep(3); print(\"LATE\")" | while read -r l; do echo "$(date +%H:%M:%S) $l"; done'
```

**Why stderr looks fine:** stderr is line-buffered, which is why nginx errors and BrokenPipe tracebacks always show up. Only `print()`-to-stdout vanishes. This asymmetry is what makes it so easy to miss — the container *looks* like it's logging normally.

**Fix:** `ENV PYTHONUNBUFFERED=1` in the Dockerfile (preferred — survives someone changing how the script is invoked) or `python3 -u`. One line, no runtime cost, no maintenance tax.

**Generalise:** any lucos Python service started without `-u`/`PYTHONUNBUFFERED` has the same silent-swallow. Worth a grep when a Python service "isn't logging what the code says it logs". Same family as arachne#735 (a probe that discards its own measurement) — [[feedback-diagnose-through-to-root-cause]]: when the next step is "read the log that should exist", first prove the log *can* exist.
