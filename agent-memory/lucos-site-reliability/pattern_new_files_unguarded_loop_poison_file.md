---
name: pattern-new-files-unguarded-loop-poison-file
description: lucos_media_import new_files.py scan loop has no try/except — one unreadable file aborts the run; os.walk ordering makes it look like "directories don't import". Missed dirs are permanent.
metadata:
  type: project
---

`lucos_media_import` **`src/new_files.py` lines 45-46** run `scan_insert_file(file)` in a bare loop with **no exception handling**. `src/import.py` wraps the *identical* call in try/except + `errorCount`. That asymmetry is the bug: **one unreadable file kills the entire per-minute scan**, silently dropping everything queued behind it.

**Why it presents as "loose files import, albums/directories don't"** (2026-08-07, 3 albums / 41 tracks lost):
- `os.walk` is top-down and yields a directory's **own files before descending into subdirectories**. So all loose files in `bandcamp/` were queued in `recent_files` ahead of all album-subdirectory files.
- A **0-byte** `Bardix le Gaulois - Acte II - Escale à Lutèce.mp3` (accented duplicate stub beside the real 12MB `...Escale a Lutece.mp3`) got past `taglib` but raised `EOFError` in `acoustid.fingerprint_file()` → `logic.py` line 54 → process died mid-list.
- Result: 5/5 loose tracks imported, 0/41 album tracks. The directory distinction is an **artifact of walk ordering**, not directory handling. Don't chase the directory theory.

**Misses are PERMANENT.** `isRecent()` = 2-minute ctime window; `dirs[:] = [d for d in dirs if isRecent(root, d)]` prunes the walk. One minute later the album dirs were already stale → no later scan revisits them. Same applies to `raise Exception("Empty Track")` / `duration < 1` in `logic.py`.

⚠️ **Do NOT assume the weekly `import.py` full scan is the backstop** — I asserted this twice (report + ticket) before checking, and it was false. `import.py` iterates `sorted(os.listdir(...))` and Python sorts **uppercase before lowercase**, so it always dies (per #173) at the case boundary: as of 2026-08-07, 15 capitalised dirs DONE, **11 lowercase dirs NEVER reached** — incl. `bandcamp`, `iTunes`, `classical`, `artists`, `qobuz`. Deterministic starvation, same tail every week. Check `/var/state/import_checkpoint.json` `completed_dirs` against the sorted top-level listing before claiming any dir is covered. Evidence recorded on #173.

**Silent failure:** the crash also skips the trailing `updateScheduleTracker(...)`, so **neither success nor failure** is posted. Adding the try/except makes `errorCount` non-zero and the *existing* schedule-tracker call fires a real alert — no new monitoring needed.

**Diagnosis recipe:** `docker logs lucos_media_import --timestamps --since <T>Z` (⚠️ **use the `Z` suffix** — `--since`/`--until` are interpreted as *local* time (BST) otherwise, silently returning the wrong hour). Look for a traceback between `Starting new_files scan` lines; count `grep -c trackAdded`. Then `find "/medlib/ceol srl/<dir>" -printf "%T+ %C+ %y %s %p\n"` inside the container to spot 0-byte / tiny non-hidden files. macOS copies leave `._*` AppleDouble sidecars + `.DS_Store`; a `._X` sibling's ctime == the moment `X` finished copying, which is handy for reconstructing the copy timeline.

**Read-only reproduction (safe, no API write):** `logic.scan_file(path)` does tags+fingerprint only; `scan_insert_file` = `scan_file` + `insertTrack`. So `scan_file` is the probe, `scan_insert_file` is the commit. Run via
`docker exec lucos_media_import sh -c 'cd /usr/src/app && PYTHONPATH=/usr/src/app pipenv --quiet run python -u /tmp/script.py'`
(⚠️ `PYTHONPATH` is required — running a script from `/tmp` puts `/tmp` on `sys.path[0]`, so `import logic` fails. Fingerprinting ~40 NFS tracks takes >2min → run backgrounded.)

**Targeted re-import path** (avoids the long full scan): drive `logic.scan_insert_file()` over the specific files with the above harness. `insertTrack` sends `If-None-Match: "*"` so it won't clobber existing tracks. ⛔ `import.py` is NOT usable for a targeted re-import — it takes **no path argument** and checkpoints per **top-level** dir, so targeting anything under `bandcamp/` rescans all of `bandcamp`.

The NFS mount is `ro` from the container, so poison files **cannot be deleted by us** — flag to lucas42. Left in place, a 0-byte file will make the Thursday `import.py` run post `success=False` → `all_files` check goes red. [[pattern_media_import_fullscan_killed_by_redeploy]]
