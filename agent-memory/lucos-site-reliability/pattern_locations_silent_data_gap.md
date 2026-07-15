---
name: pattern-locations-silent-data-gap
description: lucos_locations (OwnTracks) silently stops recording when the phone stops publishing; /_info only checks TLS so a data stall stays green
metadata:
  type: pattern
---

**lucos_locations = OwnTracks** on avalon: phone app → MQTT/TLS :8883 → `lucos_locations_mosquitto` → `lucos_locations_otrecorder` (stores in `store` vol) → `lucos_locations_otfrontend` (map + `/_info` + proxies recorder HTTP API). Recorder HTTP API on :8083.

**✅ SOLVED as of #91 (closed) — the `location-freshness` check now EXISTS and is PROVEN.** `/_info` exposes `location-freshness` (ok/red) + metric `location-data-age-seconds`. Threshold `LOCATION_FRESHNESS_THRESHOLD_SECONDS = 30*60*60` (30h) in `otfrontend/info_server.py`. It is **fail-closed** (`age_seconds is not None and age < THRESHOLD` ⇒ a failed recorder fetch reds the check, no fail-open). **First real firing 2026-07-15**: caught a genuine ~31h42m client gap in 30h (vs 3.5d unnoticed in 06-29, weeks in #5). Fired at 108034s = 34s after crossing threshold. Do NOT re-raise "we need freshness monitoring" — it's built and it works.

**Silent-gap failure mode (historical, pre-#91):** data just stops and NOTHING alerts, because `/_info` only had the `mosquitto-tls` check (cert expiry). A data stall from any other cause stayed green.
- 2025 (issue #5): weeks of data lost to an **expired TLS cert**, unnoticed → the tls check was added after.
- 2026-06-29 (this investigation): phone (`cheetah`/user `lucas`/device `viper`) stopped publishing 16:37Z; server fully healthy; unnoticed ~3.5 days. **Client-side**, two stacked sub-causes: (1) device-side DNS **"Unknown host"** resolving `locations.l42.eu` even though our authoritative DNS + public resolver both returned it cleanly (so NOT our DNS — verify apex `l42.eu` SOA + a public resolver before blaming infra); then (2) after DNS cleared, a **duplicate MQTT client-ID session** flapping connect/disconnect every ~126s so the outbound queue never drained. **Fix = force-stop + relaunch OwnTracks** (not just "reconnect") to kill the zombie session.

**Diagnosis method (fast + authoritative):**
- Last stored point: `docker exec lucos_locations_otrecorder curl -s http://127.0.0.1:8083/api/0/last` → read `tst`/`isotst`.
- On disk: `/store/rec/<user>/<device>/YYYY-MM.rec` mtime (monthly files); a missing current-month file = nothing recorded this month.
- Who's publishing: `docker logs lucos_locations_mosquitto | grep 'New client connected' | grep -v lucos-healthcheck` — phone = `cheetah`. Zero non-healthcheck connects since the gap = client stopped (not a server rejection: rejections would still show connection *attempts*).
- Rule out HTTP-mode: otfrontend nginx log for `/owntracks/pub` POSTs (none = not HTTP mode either).
- healthcheck client connects every ~10s = TLS listener + broker healthy.
- **Duplicate-session flap signature:** broker logs `Client cheetah already connected, closing old connection` + `New client connected ... as cheetah` repeating at a fixed ~2min interval; on the phone's OwnTracks debug log the send loop only logs `Resetting message send loop wait` with `current queueLength` climbing and ZERO publish lines. The `192.168.176.1` (bridge gateway) `unexpected eof while reading` TLS errors are internal probe noise, NOT the phone — the phone appears as its real public IP (e.g. `77.96.90.125`).

**Fix for the class = data-freshness check** — issue #91, raised 2026-07-02, **SHIPPED + CLOSED**. Monitor the OUTCOME not each cause; threshold tolerates a stationary/asleep/off-grid human.

**Interpreting a `location-freshness` alert (2026-07-15 playbook):**
- debug `"Last recorded location data is N seconds old"` ⇒ fetch worked, data genuinely stale ⇒ **client-side**, check server anyway then tell lucas42. Distinguish sub-causes via mosquitto: `Client cheetah closed its connection` = clean deliberate close (phone off/killed/battery) ≠ the 06-29 duplicate-session flap (which spams `already connected, closing old connection` every ~126s).
- debug `"Failed to fetch last recorded location data from the recorder"` ⇒ the `except` branch fired ⇒ recorder unreachable. **You will find NO explanatory log line** — see [[pattern-locations-info-server-stdout-swallowed]] (lucos_locations#103).
- Fast timeline anchor: recorder `/api/0/last` returns `tst` + `isotst` — use it to convert mosquitto's unix-ts log lines to real times.
- **Do NOT blame the 300ms recorder-fetch timeout.** Measured 2026-07-15 from inside otfrontend: p50 **5.4ms**, max 40.5ms (cold connect), payload 18,188 bytes ⇒ ~55x headroom. Raising it would only hide real signal. (Same lesson as arachne#735.)
