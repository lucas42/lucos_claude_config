---
name: pattern-locations-silent-data-gap
description: lucos_locations (OwnTracks) silently stops recording when the phone stops publishing; /_info only checks TLS so a data stall stays green
metadata:
  type: pattern
---

**lucos_locations = OwnTracks** on avalon: phone app → MQTT/TLS :8883 → `lucos_locations_mosquitto` → `lucos_locations_otrecorder` (stores in `store` vol) → `lucos_locations_otfrontend` (map + `/_info` + proxies recorder HTTP API). Recorder HTTP API on :8083.

**⚠️ 2026-08-19 SUPERSEDES the 2026-07-31 correction. The "2 of 3 alerts were FALSE POSITIVES" finding was itself produced by an invalid method — do not repeat it.** `/_info` exposes `location-freshness` + metric `location-data-age-seconds`; threshold `LOCATION_FRESHNESS_THRESHOLD_SECONDS = 30*60*60` (30h) in `otfrontend/info_server.py`; fail-closed; computed as `now - max(tst)` over `GET otrecorder:8083/api/0/last` (timeout 0.3s).

**`created_at` and `tst` in `/store/rec/<user>/<device>/YYYY-MM.rec` are BOTH client clocks.** `created_at` is stamped by the OwnTracks app when it builds the message, NOT by the recorder on receipt. The phone queues while disconnected and flushes on reconnect, so both fields run straight through an outage. Proof: in the window 2026-08-07T17:10:05Z → 2026-08-08T23:45:34Z, four independent receipt-side sources showed the recorder received nothing, yet `2026-08.rec` holds **29 records with `created_at`** and **37 with `tst`** inside it, both stopping the second the client reconnected. So any "true age" derived from `.rec` is meaningless for freshness. Posted as a correction on lucas42/lucos_locations#105 (2026-08-19).

**Receipt-side sources (the only ones that answer "when did we learn this?"):** `/store/monitor` (`<epoch> <topic>`, rewritten per received message); mtime of the `.rec` and of `/store/last/<user>/<device>/<user>-<device>.json`; `lucos_locations_mosquitto` connection log (bounded by container `StartedAt` — check it before trusting a negative).

**Current alert ledger:** confirmed TRUE — 2026-07-26, 2026-08-08 (client stopped 08-07 17:10 → reconnect 08-08 23:45, cleared by lucas42 restarting OwnTracks); probable TRUE — 2026-08-13 (implied frozen reference 2026-08-12T15:23:35Z matches a real fix to the second). Confirmed FALSE: **none**. 2026-07-15 and 2026-07-28 are *unsupported* (method invalid) and un-re-verifiable — July receipt-side artefacts are gone.

**Separate, still-open design flaw:** `tst` only advances on a NEW fix, while the client republishes its last known fix on a timer — across 2,552 records in `2026-08.rec`, `created_at - tst` has median 1s but p90 3h05m, p95 5h19m, max 14h31m, and 515 (20%) exceed 10 min. So `max(tst)` ages while messages flow. Whether that is a false positive depends on what the check should mean (receipt liveness vs. fix freshness) — that is design point 2 on #105, still lucas42's call. Cannot be resolved from `.rec` alone (both timestamps client-side); #103 (unbuffer stdout) is the enabler.

**A distinct, unambiguous noise source:** `debug` = `Failed to fetch last recorded location data from the recorder` — the otfrontend→otrecorder call losing a race. 6 occurrences 2026-07-26→2026-08-17, **every one exactly one poll (60s) long**. No `failThreshold` declared ⇒ defaults to 1 ⇒ each one pages. Filed lucas42/lucos_locations#111 (add `failThreshold: 2`).

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
- debug `"Last recorded location data is N seconds old"` ⇒ **DO NOT conclude "client-side" — and DO NOT verify against `.rec` timestamps, they are client clocks (see above). Use the receipt-side sources.** For context on what was recorded:
  ```bash
  ssh avalon.s.l42.eu "docker exec lucos_locations_otrecorder sh -c 'grep location /store/rec/lucas/viper/YYYY-MM.rec'"
  ```
  ⛔ **`created_at` is NOT a receive time** — that was my error, and it is what invalidated the "2 of 3 false" finding. The leading `.rec` column is the fix `tst`; `created_at` is stamped by the phone when it BUILDS the message. Both are client clocks, so a backlog flushed on reconnect looks like live ingestion whichever of them you read. Use this file for *what was recorded*, never for *when we learned it*.
- Judge client-vs-server ONLY from the receipt-side sources listed above (`/store/monitor`, `.rec`/`last` mtimes, mosquitto connection log). Then distinguish sub-causes via mosquitto: `Client cheetah closed its connection` = clean deliberate close (phone off/killed/battery) ≠ the 06-29 duplicate-session flap (which spams `already connected, closing old connection` every ~126s).
- **`tst` ≠ ingestion health, and there is NO per-record ingestion clock.** `tst` is the phone's fix clock and legitimately stalls when the human is stationary. ⛔ `isorcv` is **not** a receive time despite the name: measured 2026-08-19 over all **2,552** August records from `/api/0/locations?user=lucas&device=viper&from=<date>&to=<date>&limit=3000&sort=desc`, `isorcv == isotst` in **2,552 of 2,552** (zero exceptions), while `created_at != isorcv` in 1,353 (53%). So the recorder exposes no readable per-message receipt timestamp at all — which is precisely why lucos_locations#103 (unbuffer `info_server.py` stdout) is the enabler for any real diagnosis here.
- debug `"Failed to fetch last recorded location data from the recorder"` ⇒ the `except` branch fired ⇒ recorder unreachable. **You will find NO explanatory log line** — see [[pattern-locations-info-server-stdout-swallowed]] (lucos_locations#103).
- Fast timeline anchor: recorder `/api/0/last` returns `tst` + `isotst` — use it to convert mosquitto's unix-ts log lines to real times.
- **Do NOT blame the 300ms recorder-fetch timeout.** Measured 2026-07-15 from inside otfrontend: p50 **5.4ms**, max 40.5ms (cold connect), payload 18,188 bytes ⇒ ~55x headroom. Raising it would only hide real signal. (Same lesson as arachne#735.)
