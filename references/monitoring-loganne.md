# Monitoring Status API & Loganne

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
      "healthy": true,
      "checks": {
        "fetch-info": {
          "ok": true,
          "techDetail": "Fetches /_info"
        }
      },
      "metrics": {}
    }
  },
  "summary": {
    "total_systems": 1,
    "healthy": 1,
    "erroring": 0,
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
| `healthy` | bool | `true` if all checks pass, `false` if any check is failing. Neither true nor false if status is unknown |
| `checks` | object | Health checks for this system, keyed by check name. Each check has `ok` (bool or the string `"unknown"`), `techDetail` (string), and optionally `debug` (string with error details when `ok` is false) |
| `metrics` | object | Metrics for this system, as reported by its `/_info` endpoint |

**Summary:**

| Field | Type | Description |
|---|---|---|
| `total_systems` | number | Total number of monitored systems |
| `healthy` | number | Count of systems where all checks pass |
| `erroring` | number | Count of systems with at least one failing check |
| `unknown` | number | Count of systems whose status could not be determined |

---

## Loganne

Loganne is the central event logging service for lucos. It provides a chronological feed of system events — deployments, data changes, and other notable activity across all lucos services. Useful for understanding what has changed recently, especially when investigating incidents.

**Note:** Loganne is in-memory (no persistent storage). For long-term records, also leave a durable record (e.g. GitHub comment) when logging maintenance events.

### Reading events

```
GET https://loganne.l42.eu/events
```

Requires Bearer token authentication using the `KEY_LUCOS_LOGANNE` env var from `~/sandboxes/lucos_agent/.env`.

```bash
source ~/sandboxes/lucos_agent/.env && curl -s -H "Authorization: Bearer $KEY_LUCOS_LOGANNE" "https://loganne.l42.eu/events"
```

Returns a JSON array of recent events across the lucos ecosystem (deploys, service activity, etc.).

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

### When to write Loganne events

**Planned maintenance**: Post a Loganne event before performing planned maintenance (reboots, migrations, etc.) so other agents (especially `lucos-site-reliability`) can distinguish planned downtime from incidents. Post the GitHub comment first (GitHub is up), then Loganne when the host recovers.

Loganne event format for maintenance:
```json
{ "source": "lucos_agent", "type": "plannedMaintenance", "humanReadable": "avalon rebooted to clear swap", "url": "https://github.com/lucas42/..." }
```
