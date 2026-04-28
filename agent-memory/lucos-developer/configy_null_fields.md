---
name: lucos_configy — null serialisation for optional fields
description: configy serialises absent optional fields as explicit null, not by omitting them — dict.get(key, default) won't fall back
type: feedback
---

When reading optional fields from a lucos_configy config object, **always use `dict.get(key) or default`**, not `dict.get(key, default)`.

**Why:** configy serialises absent optional fields as explicit `null` in the API response — it does NOT omit them. `dict.get(key, default)` only falls back when the key is *absent*; when the key is present with a `null` value, it returns `None`. This caused the 2026-04-28 incident: `backup_root` and `shell_flavour` were added as optional fields for Aurora NAS. Non-aurora hosts got `null` for both — the code used `get(key, default)` and so received `None`, causing `df -P None` to fail on every host. The overnight cron crashed silently with no Loganne event; detection took ~7 hours.

**How to apply:** Any time you read an optional field from a configy-sourced dict, use `config.get("field") or "default_value"` (or explicit `if value is None` guard). This applies in Python; check equivalent pattern in other languages. Note: local YAML testing won't catch this because YAML files omit absent fields entirely — only real configy API responses include explicit `null`.
