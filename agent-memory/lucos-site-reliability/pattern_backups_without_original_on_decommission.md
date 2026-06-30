---
name: pattern-backups-without-original-on-decommission
description: lucos_backups backup-without-original check no longer fires on decommissioned retained backups (RESOLVED PR #360); if it reds now it's a GENUINE unexpected deletion of a configy-declared volume
metadata:
  type: project
---

**RESOLVED 2026-06-30:** lucos_backups#359 fix shipped as PR #360 (merged 01:15:35Z, check recovered 01:18Z). The check `techDetail` now reads "...no longer present on their source host **but are still declared in configy**" — i.e. it only flags volumes still in configy. So **decommissioning a system no longer reds this check.** If `backup-without-original` reds now, the named volume IS still in configy → it's a GENUINE unexpected deletion / failed restore → investigate, don't dismiss as decommission. The 2026-06-29 23:07→2026-06-30 01:18 flap was the lucos_authentication decommission tripping the OLD logic, cleared by the #360 deploy. Historical context below.

---

`lucos_backups` `/_info` `backup-without-original` check went red (and **never self-cleared**, pre-#360) when a system was decommissioned but its backups were intentionally retained.

**Why:** the check (`src/utils/tracking.py`) flags any backup of type volume/volume-snapshot whose `(source_host, name)` key isn't in `live_volume_keys` (= volumes physically present on hosts). Archival tears down the source volume AND removes it from configy `volumes.yaml`, but lucas42's standing steer is to KEEP backups of decommed systems (archival checklist line 143: "storage is cheap, regret is expensive"). So the retained copies have no live original → permanent alert. First hit: `avalon/lucos_authentication_config` after lucos_authentication decommission (lucas42/lucos_authentication#143), red on 2026-06-30, copies on all 4 hosts.

**Self-contradiction it exposes:** archival checklist line 110 says backups health check should show NO missing-volume warnings post-archival; line 143 says keep the backups. Current code makes both impossible at once (only delete-the-data satisfies 110).

**How to apply:** if `backup-without-original` is red and the debug names a volume belonging to a **decommissioned** system, it's this — benign, don't re-investigate, don't blame the decommission as a mistake. Recommended fix (tracked **lucas42/lucos_backups#359**, owner lucos-developer): only flag if the volume is still declared in configy (`... and backup["name"] in getVolumesConfig()`) — configy-absence becomes the decommission signal; preserves accidental-deletion/failed-restore detection (those stay in configy). Until #359 lands, every future decommission re-reds this check. Verify #359 still open before citing.
