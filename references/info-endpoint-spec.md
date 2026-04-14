# The `/_info` Endpoint

Every lucos HTTP service must expose a `/_info` endpoint with no authentication. It is consumed by `lucos_monitoring` (health tracking) and `lucos_root` (homepage). The full specification is in [`docs/info-endpoint-spec.md`](https://github.com/lucas42/lucos/blob/main/docs/info-endpoint-spec.md) in the `lucos` repo.

Fields are divided into three tiers:

- **Tier 1 (required):** `system`, `checks`, `metrics` -- must always be present. `checks` and `metrics` may be empty `{}` but must not be omitted.
- **Tier 2 (recommended):** `ci`, `title` -- strongly encouraged; consumers handle their absence gracefully.
- **Tier 3 (frontend only):** `icon`, `show_on_homepage`, `network_only`, `start_url` -- only relevant for services with a web UI. API-only services should omit these.

## Quick reference

| Field | Type | Tier | Description |
|---|---|---|---|
| `system` | string | 1 | System name from `SYSTEM` env var |
| `checks` | object | 1 | Health checks: each value has `ok` (bool), `techDetail` (string), optional `debug` (string), optional `dependsOn` (system ID string — suppresses alerts when that system is being deployed) |
| `metrics` | object | 1 | Metrics: each value has `value` (number), `techDetail` (string) |
| `ci` | object | 2 | CI metadata, e.g. `{"circle": "gh/lucas42/<repo_name>"}` |
| `title` | string | 2 | Human-readable name (falls back to `system` if absent) |
| `icon` | string | 3 | Path to the service icon |
| `show_on_homepage` | bool | 3 | Whether to show on the homepage (default `false`) |
| `network_only` | bool | 3 | Whether a network connection is required (default `true`) |
| `start_url` | string | 3 | URL path to the UI entry point (default `"/"`) |

## Example (frontend service)

```json
{
  "system": "lucos_example",
  "checks": {
    "db-reachable": {
      "ok": true,
      "techDetail": "Checks whether a connection to PostgreSQL can be established"
    }
  },
  "metrics": {
    "photo-count": {
      "value": 42318,
      "techDetail": "Total number of photos stored"
    }
  },
  "ci": {
    "circle": "gh/lucas42/lucos_example"
  },
  "title": "Example",
  "icon": "/icon",
  "show_on_homepage": true,
  "network_only": true,
  "start_url": "/"
}
```

## Implementation notes

- `/_info` checks must never propagate exceptions as 500s — monitoring distinguishes 500 (API broken) from `ok:false` (dependency unhealthy)
- `lucos_monitoring` fetches `/_info` with a hard 1-second timeout. Health check timeouts inside `/_info` handlers must be well under 1 second (0.5s is a safe ceiling) or the whole endpoint times out and the service appears fully down
- When removing a service from docker-compose, also remove its `/_info` health check — stale checks cause monitoring alerts after the container disappears
