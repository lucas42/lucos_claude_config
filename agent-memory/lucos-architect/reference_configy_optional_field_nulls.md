---
name: configy serialises absent optional fields as explicit null
description: lucos_configy returns optional fields as JSON null when absent in the YAML, not by omitting the key — so `dict.get(key, default)` does NOT fall back to default
type: reference
---

# configy optional-field serialisation

When a host (or any record) in `lucos_configy`'s YAML does not set an optional field, the JSON `/api/...` response includes the key with an explicit `null` value, **not** an absent key.

This catches consumers out because the most natural Python idiom is wrong:

```python
# WRONG — only falls back when 'backup_root' key is absent
backup_root = config.get('backup_root', '/')

# RIGHT — falls back on null and missing alike
backup_root = config.get('backup_root') or '/'
```

In a typical configy response, `config.get('backup_root', '/')` returns `None`, which then propagates as a literal string `"None"` (or a real `None`) into shell commands, SQL, paths, etc.

## Why it matters

- Local YAML-only tests don't catch this — YAML files for non-affected hosts simply omit the field, so `dict.get(key, default)` *appears* to work.
- The bug only surfaces against the **live configy API**, which is the production path.
- Every consumer of configy is exposed to this in every language with similar idioms (`get`/`Optional`/etc.).

## Incident this came from

2026-04-28: `lucos_backups` Aurora NAS integration ([backups#219](https://github.com/lucas42/lucos_backups/pull/219)) added optional `backup_root` and `shell_flavour`. Consumer used `config.get('backup_root', '/')`. Every non-aurora host returned `None`, `df -P None` failed, every host's tracking errored, overnight cron crashed silently. Detection took ~7 hours because there was no Loganne event on cron failure.

Incident report: `lucos/docs/incidents/2026-04-28-backups-aurora-null-config-cron-failure.md`.

## Architectural follow-up to consider

- **Documentation gap in lucos_configy**: this contract should be documented in lucos_configy's README and CLAUDE.md. Consumers are expected to handle nulls but nothing tells them so.
- **Potential lint/convention**: `dict.get('...', literal)` against configy data is a smell, but detecting it reliably across the estate is hard — probably not worth a convention.
- **Cron-failure observability**: the silent-cron-crash leg of this incident is separate from the configy contract and is its own concern (sysadmin/SRE).

## Application

When reviewing or designing any consumer of configy that reads optional fields:
1. Use `get(key) or default`, not `get(key, default)`.
2. If the field is required, validate explicitly — null is a real possible value.
3. Test against the live configy API or a fixture that mirrors its serialisation, not just YAML files.
