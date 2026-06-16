---
name: lucos-creds-quoted-values
description: lucos_creds stores non-PEM values with surrounding double-quotes — bash source strips them but direct file reads preserve them
metadata:
  type: feedback
---

Values in `.env` files from lucos_creds are stored with surrounding double-quotes
(e.g. `LUCOS_ARCHITECT_AITHNE_CLIENT_SECRET="a44d32fb-766a-4440-9dbb-13982a77435b"`).

**Why:** This is the lucos_creds storage format for string values.

**How to apply:**
- When `source`d via bash (`set -a; source .env; set +a`), bash strips the quotes and the env var is a clean value. Subprocesses reading from `os.environ` get the clean unquoted value. ✓
- When reading the file directly with Python (`open(.env)`) or `cut -d= -f2-`, the quotes are preserved and the value length is 2 chars longer than expected. If you see `length: 38` where a UUID v4 should be `36`, quotes are the culprit.
- Workaround for direct file reading: strip leading/trailing `"` — `v.strip().strip('"')`.

Confirmed during lucos_agent#67 (2026-06-16): `LUCOS_ARCHITECT_AITHNE_CLIENT_SECRET` stored as `"<uuid>"`, caused `invalid_client` when extracted with Python `line.partition('=')[2]` directly, but worked fine when read from `os.environ` after `source`.
