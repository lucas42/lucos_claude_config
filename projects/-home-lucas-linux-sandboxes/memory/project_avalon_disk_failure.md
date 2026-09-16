---
name: project-avalon-disk-failure
description: "avalon's disk failed 2026-09-14 (lucos#294); rebuilt on Trixie and fully recovered by 2026-09-16 — durable lessons, plus the open tickets it left behind"
metadata: 
  node_type: memory
  type: project
  originSessionId: 62c49c10-849c-44f7-bb03-e762ea998642
  modified: 2026-09-16T23:01:15.092Z
---

**Incident:** lucas42/lucos#294, report merged at `docs/incidents/2026-09-14-avalon-disk-failure.md`. Rebuild runbook lucas42/lucos#296. **Resolved 2026-09-16**: 55/55 systems healthy, every volume restored and verified, photo library whole at 2,253 items.

## The lesson that cost the most

**Check whether a backup exists before deciding it doesn't.** #296 recorded a decision not to restore `lucos_photos_photos`, re-syncing from the Android app instead. Aurora held a **complete 2026-09-14 snapshot** the whole time. Nobody looked, because **incremental snapshots live under `<backup_root>/host/<source>/volume-snapshots/<volume>/<date>/`, not beside the tar archives** — a `find` for `*photos_photos*` tarballs returns one 87-byte file from March and looks like a failing backup. That premise cost a 10-hour resync, a server bug hunt, and two volume swaps to undo.

**A volume's absence from the tar rotation is not evidence.** `configy/config/volumes.yaml` gives `lucos_photos_photos` `backup_strategy: incremental` with `skip_backup_on_hosts: [salvare, xwing]` — so no tarball on those hosts is correct, not broken.

## Durable rebuild facts

- **Port 53:** systemd-resolved's stub listener holds it and blocks the DNS container. `DNSStubListener=no` + `/etc/resolv.conf` → `/run/systemd/resolve/resolv.conf`. Now in #296 Step 1.
- **Bootstrap order:** lucos_creds first (only service with the `LUCOS_DEPLOY_ENV_BASE64` bypass), then configy, mirror, dns, router, firewall, monitoring, loganne, aithne, rest, arachne last. Nothing deploys or builds while creds is down — lucas42/lucos#299, lucas42/lucos_deploy_orb#188.
- **`init-host.sh` needs creds up**, so it does not belong in host provisioning.
- **Swap:** a fresh OVH Trixie install has a 512MB *partition*, not a swapfile; add a swapfile alongside it.
- **Restore gotchas:** rescue tarballs keep the full original path, unlike nightlies; `mv` globs skip dotfiles; `restore-volume.sh`'s `docker compose up --no-start` breaks on multi-service compose files; a cross-volume `mv` is a real copy, not a rename, even on one filesystem.
- **Deploys queue** because the pipeline deliberately limits concurrent deploys per node, not through lack of CI capacity.

## Recovering consistently (lucas42's diagnosis, 2026-09-16)

When files and database are restored from different points and processing runs in between, they diverge — and repair work never fully reconciles them. **Restore both volumes from the same moment and they are consistent by construction.** Doing that here removed 769 phantom persons and 732 orphans at a stroke, cost no manual curation, and left every row with its file. The three photos newer than the snapshot were then pushed back through the normal upload endpoint server-side (EXIF supplies `taken_at`, so dates survive) in about twenty seconds, rather than a ~10-hour phone resync.

**A force resync re-transfers everything**: the server hashes the streamed body and only then checks for a duplicate, so there is no cheap offer.

## Open afterwards

lucas42/lucos_deploy_orb#193 (Critical — deploy resolves the newest tag, not the checked-out commit; caused the mail outage by substituting an untested image), lucas42/lucos_dns#135 (Critical — xwing's DNS secondary cannot write zone files, served five zones from memory throughout), lucas42/lucos_mail#81, lucas42/lucos_photos #527/#528/#529/#530/#531, lucas42/lucos_dns#136, lucas42/lucos#300–304, lucas42/lucos_monitoring#312/#313, lucas42/lucos_root#158, lucas42/lucos_media_metadata_api#340.

Two volumes remain moved-aside on avalon pending lucas42's decision: `lucos_photos_photos_moved-aside-2026-09-16` and `lucos_photos_postgres_data_moved-aside-2026-09-16`. Neither is declared in configy, so neither is backed up.
