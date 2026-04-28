---
name: configy null serialisation — absent fields become explicit null in API
description: lucos_configy serialises absent optional fields as explicit null in its JSON API, not by omitting them. dict.get(key, default) won't catch this — only get(key) or default will.
type: project
---

`lucos_configy` does **not** omit unset optional fields from its JSON responses. Instead it serialises them as explicit `null`. This means:

```python
# WRONG — only falls back when key is absent:
value = config.get("backup_root", "/srv/backups/")
# → returns None if backup_root is null in the API response

# CORRECT — falls back when key is absent OR null:
value = config.get("backup_root") or "/srv/backups/"
```

**Why:** When a field is defined in the configy schema but not set for a particular host/service, the API includes it as `{"backup_root": null}`. The `dict.get(key, default)` idiom only substitutes the default when the key is *absent* from the dict — a present-but-null value passes straight through.

**Why local testing won't catch it:** Local development reads the raw YAML files, where absent optional fields are simply omitted. The absent-key behaviour is correct with `dict.get(key, default)`. The explicit-null behaviour only appears when hitting the configy HTTP API, which is what production code does. This dev/prod parity gap is the root cause of the 2026-04-28 incident.

**Incident**: [lucos_backups#221](https://github.com/lucas42/lucos_backups/issues/221) — Aurora NAS integration added `backup_root` and `shell_flavour` as optional fields. Non-aurora hosts got `{"backup_root": null}` from configy. Code used `get("backup_root", "/srv/backups/")` → got `None` → `df -P None` failed → every host's tracking errored → overnight cron silently dropped → ~10h detection gap.

**Fix pattern**: Use `get(key) or default` for any optional configy field.

**How to apply**: Whenever reading optional fields from configy-sourced config dicts (hosts, volumes, services), use `get(key) or default`, not `get(key, default)`. Applies in Python — other languages have equivalent null-coalescing patterns.

**Follow-up tracking**: [lucos_backups#223](https://github.com/lucas42/lucos_backups/issues/223) — dev/prod parity test loading host config via configy HTTP API (not local YAML) to catch this class of bug in CI.
