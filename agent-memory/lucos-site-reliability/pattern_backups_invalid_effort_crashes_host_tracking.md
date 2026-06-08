---
name: pattern-backups-invalid-effort-crashes-host-tracking
description: lucos_backups host-tracking-failures "<host>: 'low'" = invalid recreate_effort value in configy volumes.yaml KeyErrors the whole host's getData()
metadata:
  type: project
---

`lucos_backups` `volume-host` + `host-tracking-failures` red with debug like
`Hosts which failed tracking: avalon.s.l42.eu: 'low'` (the quoted word is the
`repr` of a Python `KeyError`) = a docker volume on that host has a
`recreate_effort` value in `lucos_configy/config/volumes.yaml` that is NOT a key
in lucos_backups `src/effort_labels.yaml`.

**Why:** `Volume.__init__` (src/classes/volume.py) does an unguarded
`effort_labels[effort_id]`. An unknown id throws `KeyError`, which propagates up
through `Host.getData()` (src/classes/host.py:200, re-raises) and aborts ALL data
retrieval for that host → every volume on that host drops out of tracking
(volume-count plummets), other hosts unaffected. Backups themselves keep running
(create-backups/data-age stay green) — it's a tracking/visibility failure = P2.

**Valid effort ids:** small, considerable, huge, automatic, tolerable, remote,
unknown. Auto-regenerated caches use `automatic` (e.g. lucos_docker_mirror_cache).

**Diagnostic:** backups log on the host running lucos_backups (avalon) shows
`** Error ** Problem retrieving data from <host>: '<bad-value>'` every 5 min.
Then `grep "recreate_effort: <bad-value>" lucos_configy/config/volumes.yaml`.

**Fix:** correct the configy value (config-as-code PR). Won't clear until merged
→ config-sync propagates volumes.yaml → next tracking run.

First hit 2026-06-09: `lucos_dns_configy-sync-cache` had `recreate_effort: low`
→ avalon tracking down. Fixed low→automatic in lucas42/lucos_configy#220.
Hardening (graceful fallback to unknown + per-volume error isolation so one bad
volume doesn't nuke the host) filed as lucas42/lucos_backups#316.
