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

**⛔ ESTATE SURVEY ALREADY DONE 2026-07-15, ALL HOSTS — DO NOT RE-RUN IT. Blast radius is exactly ONE service (locations_otfrontend = #103). No estate-wide problem, no ticket.**

**Host coverage (state only what was actually probed — ssh-production.md rule):**
- **avalon, xwing, salvare** — live-probed 2026-07-15, output captured. These are the only container-running hosts.
- **xwing** (9 containers): only `lucos_media_import` has Python — it's a **cron container** (pid1 `startup.sh`, pid21 `/usr/sbin/cron`, pid22 `cat`), so python **exits every run and flushes at exit**. `PYTHONUNBUFFERED` unset yet diagnostics verifiably arriving (`Starting new_files scan` every ~60s). **No impact.** Other 8: python=none (docker_health_app is Go/scratch).
- **salvare** (3 containers): zero Python (linuxplayer, firewall = python=none; docker_health_app Go/scratch).
- **virgon-express**: `active: false` in hosts.yaml (physically disconnected) — not probed, correctly.
- **aurora**: `is_storage_only: true`, `serves_http: false`, and runs **no Docker** (ADR-0001 + verified 2026-06-09) ⇒ cannot host a containerised Python service. Not live-probed this session; resting on those two documented sources, not a fresh sweep.

**⚑ A `ps | grep python` sweep MISSES cron containers** — no python process is running between invocations, so the container looks Python-free. `lucos_media_import` didn't appear in the avalon-style sweep at all; it only surfaced via `command -v python`. Use `command -v python` to enumerate, `ps` to classify. (This is also why the first xwing pass wrongly returned "zero Python".)

**Key structural fact: scheduled/cron Python is IMMUNE to this bug.** Exit ⇒ flush. Only a never-exiting process (`serve_forever()`, gunicorn) can swallow indefinitely. So the affected set is "long-lived Python servers", not "Python".

avalon's 7 long-lived-Python containers (ground truth via `docker exec ps` + `docker inspect` env, not stale checkouts):

| service | mechanism | impact |
|---|---|---|
| arachne_ingestor, media_weightings | `python -u server.py` | ✅ none |
| eolas_app, contacts_app | `PYTHONUNBUFFERED=1` (gunicorn) | ✅ none |
| **locations_otfrontend** | none | ⚠️ **real swallowed diagnostic = #103** |
| lucos_backups | none — but its ONE print (`src/server.py:311`) passes `flush=True`, and it's a startup banner not a diagnostic | ✅ none |
| docker_mirror_info | none — but `info/app.py` has **zero** `print(` calls | ✅ none |

(aithne / docker_health_app / root_app / oauth2_proxy are Go/scratch — no `sh`, not Python. A `docker exec ... ps` on them returns an OCI error whose text can pollute a grep — filter it.)

**Do NOT propose a lucos_repos convention check for this.** There is no single correct rule to encode: `-u`, `PYTHONUNBUFFERED=1`, call-site `flush=True`, **and "it's a cron container that flushes at exit"** are all valid and all in live use. A checker would have to encode ≥4 mechanisms or permanently false-positive on backups, docker_mirror_info **and media_import** — all zero-impact. Failure-mode impact (nil beyond #103) vs build+maintain cost (per-repo config + forever false-positive triage) ⇒ **accept the risk**. Asked and answered — see [[feedback-ask-what-problem-before-accepting-scope]]; this was a near-repeat of the lucos_backups#345 estate-audit-for-a-non-problem.

**Still generally true:** when a Python service "isn't logging what the code says it logs", check buffering before hunting a missing log statement. Same family as arachne#735 (a probe that discards its own measurement) — [[feedback-diagnose-through-to-root-cause]]: when the next step is "read the log that should exist", first prove the log *can* exist.
