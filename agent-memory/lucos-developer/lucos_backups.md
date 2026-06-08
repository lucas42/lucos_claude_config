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

## copyTo() uses scp with raised timeout

As of PR #315, `Host.copyTo()` uses `scp` with `timeout=7200` (2 hours). The original 600s cap killed the 6.6 GB `lucos_photos_photos` transfer.

**CRITICAL:** `connection.run()` executes the copy command **on the source host's shell** via Fabric SSH — NOT inside the backup Docker container. This means the binary must be installed on the source host (e.g. avalon), not just in the image. `scp` comes from `openssh-client` which is present everywhere. **Never switch to a binary that requires host-level installation** (e.g. rsync, rclone) without confirming it's on all backup source hosts — the image Dockerfile is irrelevant for host-side commands.

## References

- [[lucos-configy-null-fields]] — optional fields serialize as explicit null; use `dict.get(k) or default` for Option<T>, `dict.get(k, default)` for `#[serde(default)] bool`
