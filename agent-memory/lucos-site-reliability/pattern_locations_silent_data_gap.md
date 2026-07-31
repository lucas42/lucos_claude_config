---
name: pattern-locations-silent-data-gap
description: lucos_locations (OwnTracks) silently stops recording when the phone stops publishing; /_info only checks TLS so a data stall stays green
metadata:
  type: pattern
---

**lucos_locations = OwnTracks** on avalon: phone app → MQTT/TLS :8883 → `lucos_locations_mosquitto` → `lucos_locations_otrecorder` (stores in `store` vol) → `lucos_locations_otfrontend` (map + `/_info` + proxies recorder HTTP API). Recorder HTTP API on :8083.

**⚠️ 2026-07-31 CORRECTION — `location-freshness` EXISTS but is NOT TRUSTWORTHY. Do not treat its alerts as evidence of anything until lucos_locations#105 is fixed.** `/_info` exposes `location-freshness` + metric `location-data-age-seconds`; threshold `LOCATION_FRESHNESS_THRESHOLD_SECONDS = 30*60*60` (30h) in `otfrontend/info_server.py`; fail-closed. **But 2 of its 3 alerts to date were FALSE POSITIVES**, proven against the recorder's own store:

| alert | reported age | TRUE age (from `.rec` `created_at`) | verdict |
|---|---|---|---|
| 07-15 19:01:59Z | 30.0h | **47 min** | ❌ false |
| 07-26 20:33:12Z | 30.0h | **30.0h** | ✅ real (one genuine 32.4h stationary spell) |
| 07-28 04:57:28Z | 30.0h → 49.1h | **3h29m** (18 more fixes arrived live during the alert) | ❌ false |

Signature: `max(tst)` pins to one value and then just tracks wall-clock while fresh data flows in underneath. Mechanism NOT established (`/api/0/last` serves the recorder's `last` cache, a different path from `.rec`; undiagnosable until #103 unbuffers stdout). Filed **lucos_locations#105**.

**I built a completely false narrative on this for four consecutive ops runs** (07-15/19/23/27/31): "recurring worsening client-side phone gaps, 31h → 18h → 1min → 32h → 49h". None of that is real. July's actual gap distribution for `lucas/viper` is 6–23h (ordinary overnight/idle) with exactly ONE >30h gap. See [[feedback_verify_check_claim_against_underlying_store]].

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

**Interpreting a `location-freshness` alert (revised 2026-07-31 — the 07-15 playbook's first line was WRONG):**
- debug `"Last recorded location data is N seconds old"` ⇒ **DO NOT conclude "client-side". First verify the claim against the recorder store**, which is the only source of truth:
  ```bash
  ssh avalon.s.l42.eu "docker exec lucos_locations_otrecorder sh -c 'grep location /store/rec/lucas/viper/YYYY-MM.rec'"
  ```
  Parse each record's **`created_at`** (recorder receive time), NOT the leading `.rec` column — that column is the fix `tst`, so a backlog flushed on reconnect looks like live ingestion if you read it. Compare the newest `created_at` *before the alert instant* against the reported age. Twice out of three they disagreed by 26+ hours.
- Only if the store agrees is it client-side. Then distinguish sub-causes via mosquitto: `Client cheetah closed its connection` = clean deliberate close (phone off/killed/battery) ≠ the 06-29 duplicate-session flap (which spams `already connected, closing old connection` every ~126s).
- **`tst` ≠ ingestion health.** `tst` is the phone's fix clock and legitimately stalls when the human is stationary — the one *real* alert (07-26) was a stationary spell, not a failure. `created_at`/`isorcv` is the ingestion clock. `/api/0/locations?user=lucas&device=viper&from=<date>&limit=1&sort=desc` returns both (verified working 2026-07-31).
- debug `"Failed to fetch last recorded location data from the recorder"` ⇒ the `except` branch fired ⇒ recorder unreachable. **You will find NO explanatory log line** — see [[pattern-locations-info-server-stdout-swallowed]] (lucos_locations#103).
- Fast timeline anchor: recorder `/api/0/last` returns `tst` + `isotst` — use it to convert mosquitto's unix-ts log lines to real times.
- **Do NOT blame the 300ms recorder-fetch timeout.** Measured 2026-07-15 from inside otfrontend: p50 **5.4ms**, max 40.5ms (cold connect), payload 18,188 bytes ⇒ ~55x headroom. Raising it would only hide real signal. (Same lesson as arachne#735.)
