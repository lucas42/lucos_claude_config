---
name: pattern-locations-silent-data-gap
description: lucos_locations (OwnTracks) silently stops recording when the phone stops publishing; /_info only checks TLS so a data stall stays green
metadata:
  type: pattern
---

**lucos_locations = OwnTracks** on avalon: phone app → MQTT/TLS :8883 → `lucos_locations_mosquitto` → `lucos_locations_otrecorder` (stores in `store` vol) → `lucos_locations_otfrontend` (map + `/_info` + proxies recorder HTTP API). Recorder HTTP API on :8083.

**Silent-gap failure mode (recurring):** data just stops and NOTHING alerts, because `/_info` only has the `mosquitto-tls` check (cert expiry). A data stall from any other cause stays green.
- 2025 (issue #5): weeks of data lost to an **expired TLS cert**, unnoticed → the tls check was added after.
- 2026-06-29 (this investigation): phone (`cheetah`/user `lucas`/device `viper`) stopped publishing 16:37Z; server fully healthy; unnoticed 3 days. **Client-side** (phone stopped), not a server fix.

**Diagnosis method (fast + authoritative):**
- Last stored point: `docker exec lucos_locations_otrecorder curl -s http://127.0.0.1:8083/api/0/last` → read `tst`/`isotst`.
- On disk: `/store/rec/<user>/<device>/YYYY-MM.rec` mtime (monthly files); a missing current-month file = nothing recorded this month.
- Who's publishing: `docker logs lucos_locations_mosquitto | grep 'New client connected' | grep -v lucos-healthcheck` — phone = `cheetah`. Zero non-healthcheck connects since the gap = client stopped (not a server rejection: rejections would still show connection *attempts*).
- Rule out HTTP-mode: otfrontend nginx log for `/owntracks/pub` POSTs (none = not HTTP mode either).
- healthcheck client connects every ~10s = TLS listener + broker healthy.

**Fix for the class = data-freshness check** (issue #91, raised 2026-07-02): extend `otfrontend/info_server.py` `/_info` with `location-freshness` = `now - max(tst)` from recorder `/api/0/last`, threshold ~24–36h, low severity. Monitor the OUTCOME not each cause. Cheap, single-service, no rollout — clears the impact/effort bar (silent + partially unrecoverable data loss). Threshold must tolerate a stationary/asleep/off-grid human.
