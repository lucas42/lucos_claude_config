---
name: lucos-backups
description: Key architecture notes and gotchas for lucos_backups implementation work
metadata:
  type: project
---

## Architecture

- **Language**: Python. Tests in `src/tests/`. Run with `cd src && pipenv run python3 -m pytest tests/`.
- **Entry**: `src/scripts/create-backups.py`. Key classes: `classes/volume.py`, `classes/host.py`, `classes/shell.py`.
- **Config is NOT in git**: `src/config.yaml` is gitignored. It is fetched at runtime from lucos_configy (`https://configy.l42.eu/volumes` + `/hosts`). Editing the local `config.yaml` is not a code change — use it for local testing only.

## Critical: Adding a new volume config field

Requires changes in **two repos**:
1. **lucos_configy**: add field to `Volume` struct in `api/src/data.rs` with `#[serde(default)]`, update `all.rs` RDF export, set value in `config/volumes.yaml`. Test with `docker run ... cargo test`.
2. **lucos_backups**: read the field in `classes/volume.py` (already uses `.get("field", default)` pattern).

**Why:** configy Rust API only serializes fields declared in the struct. Unknown YAML fields are silently dropped by serde.

## copyTo() uses rsync (not scp)

As of PR #311, `Host.copyTo()` uses `rsync -az --partial --timeout=300 -e 'ssh ...'` with `timeout=None` on `connection.run()`. Rationale: scp's `timeout=600` killed mid-transfer for large volumes (6.6 GB photos volume). rsync's `--timeout` is idle I/O timeout, not wall-clock. **rsync runs on the source host (avalon), not in the Docker container** — the container just SSH-instructs the host.

## tolerate_live_file

`Volume.tolerate_live_file` (bool, default False): when True, `archiveLocally()` uses `warn=True` and tolerates tar exit code 1 (file changed while reading). Set on `lucos_media_manager_stateFile` in lucos_configy (PR #218).

## References

- [[lucos-configy-null-fields]] — optional fields serialize as explicit null; use `dict.get(k) or default` for Option<T>, `dict.get(k, default)` for `#[serde(default)] bool`
