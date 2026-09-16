# Monitoring & Loganne

## Monitoring Status API

The lucos monitoring system exposes a machine-readable status endpoint for agents to check the health of all lucos services:

```
GET https://monitoring.l42.eu/api/status
```

No authentication required. Returns JSON.

### Response structure

```json
{
  "systems": {
    "example.l42.eu": {
      "name": "lucos_example",
      "status": "healthy",
      "checks": {
        "fetch-info": {
          "status": "healthy",
          "statusText": "healthy",
          "techDetail": "Fetches /_info",
          "link": "https://example.l42.eu/_info"
        }
      },
      "metrics": {}
    }
  },
  "summary": {
    "total_systems": 1,
    "healthy": 1,
    "failing": 0,
    "unknown": 0
  }
}
```

### Field reference

**Top level:**

| Field | Type | Description |
|---|---|---|
| `systems` | object | Per-system status, keyed by hostname |
| `summary` | object | Aggregate counts across all systems |

**Each system (keyed by hostname):**

| Field | Type | Description |
|---|---|---|
| `name` | string | The system name (e.g. `lucos_photos`). `"unknown"` if the system's `/_info` could not be fetched |
| `status` | string | `"healthy"` if all checks pass, `"failing"` if any check is failing; transitional values such as `"buffering"` and `"pending_verification"` also occur, so match on the value rather than assuming two |
| `checks` | object | Health checks for this system, keyed by check name. Each check has `status` and `statusText` (strings, same vocabulary as the system's), `techDetail` (string), and often `link` (string) |
| `metrics` | object | Metrics for this system, as reported by its `/_info` endpoint |

**Summary:**

| Field | Type | Description |
|---|---|---|
| `total_systems` | number | Total number of monitored systems |
| `healthy` | number | Count of systems where all checks pass |
| `failing` | number | Count of systems with at least one failing check |
| `unknown` | number | Count of systems whose status could not be determined |

**These are string statuses, not booleans.** A filter written against a `healthy` or `ok` boolean matches nothing and returns an empty result, which looks exactly like "no systems are failing". Treat an empty result from this endpoint as a reason to re-read one system's raw JSON before believing it.

---

## Loganne

Loganne is the central event logging service for lucos. It provides a chronological feed of system events — deployments, data changes, and other notable activity across all lucos services. Useful for understanding what has changed recently, especially when investigating incidents.

### Reading events

```
GET https://loganne.l42.eu/events
```

Requires Bearer token authentication using the `KEY_LUCOS_LOGANNE` env var from `~/sandboxes/lucos_agent/.env`.

```bash
source ~/sandboxes/lucos_agent/.env && curl -s -H "Authorization: Bearer $KEY_LUCOS_LOGANNE" "https://loganne.l42.eu/events"
```

Returns a JSON array of recent events across the lucos ecosystem (deploys, service activity, etc.), **newest first** — so the most recent event is the first element, not the last.

### Event payload shape

Each event's timestamp is `date` (ISO 8601, e.g. `2026-09-16T04:39:46.062Z`). There is no `dateTime` field; asking for one returns null for every event, which reads exactly like a feed carrying no timestamps. Every event also carries a `level` — `detail`, `routine`, `notable` or `headline`.

Events are mostly flat, with one exception worth knowing: `webhooks` is a nested object keyed by consumer, each holding a delivery `status` and an `attempts` array with per-attempt timestamps. That is the place to look when debugging whether an event actually reached its consumers.

**Whether a "before" state is published varies by event type — do not assume either way.** `lucos_media_metadata_api` calls `Loganne.post(action, humanReadable, storedTrack, existingTrack)` with both arguments, but only `storedTrack` appears in the published event, so a track diff needs the producing service or the preceding event. Other types do publish it: `collectionSwitch` from `lucos_media_manager` carries `previousName` and `previousSlug` alongside `name` and `slug`. Check a real payload of the type you care about before concluding the before-state isn't there.

Don't assume a field is present because the internal publisher signature takes it — check an actual event payload.

### Writing events

Use the `loganne-event` script in `~/sandboxes/lucos_agent/`:

```bash
~/sandboxes/lucos_agent/loganne-event <type> <humanReadable>
```

- `type` — event type string (e.g. `plannedMaintenance`, `hostRebooted`)
- `humanReadable` — plain English description of the event

No authentication required for writes. The `source` is hardcoded to `lucos_agent`.

```bash
~/sandboxes/lucos_agent/loganne-event plannedMaintenance "avalon rebooted to apply kernel update"
```

### Loganne as a communication channel

When performing planned maintenance (reboots, migrations, etc.), post a Loganne event so other agents (especially `lucos-site-reliability`) can distinguish planned downtime from incidents. Note: Loganne is in-memory, so also leave a durable record (e.g. GitHub comment) for long-term reference.
