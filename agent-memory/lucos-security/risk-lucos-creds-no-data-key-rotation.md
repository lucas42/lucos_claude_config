---
name: risk-lucos-creds-no-data-key-rotation
description: lucos_creds has no mechanism to rotate its own master AES data_key — deleting it orphans every stored credential rather than rotating anything. Surfaced by the avalon disk-failure incident (lucas42/lucos#294/#296), 2026-09-15.
metadata:
  type: project
---

**Standing architectural gap, independent of any specific incident:** `lucos_creds`'s server (`server/src/storage.go`, `keys.go`) has two secrets that follow the same "generate on first boot if the file is absent" pattern (`getCreateBlockCipher` / `getCreateSshSigner`), but they are NOT equally rotatable:

- **`server_key`** (`/var/lib/creds_store/server_key`, the SSH host identity for `creds.l42.eu:2202`) — free to rotate. It authenticates the server to connecting clients only; it doesn't encrypt any stored data. Omit it from a restore/redeploy and the server mints a fresh one; clients just need a `known_hosts` update.
- **`data_key`** (`/var/lib/creds_store/data_key`, AES-256-GCM key encrypting every stored credential's `EncryptedValue` in the sqlite store) — **there is no rotation/migration tooling anywhere in the repo.** Deleting the file does not rotate the key; the server generates a fresh one and every existing encrypted row becomes permanently undecryptable (no decrypt-old/re-encrypt-new path exists). A real rotation requires new migration code that has never been written.

**How this surfaced:** avalon's disk failed (lucas42/lucos#294) and left custody unencrypted for OVH's disk swap (lucas42/lucos#296). The architect framed "restore the old creds keys vs. mint fresh ones" as one decision; I read the source before answering and found it's actually two decisions with very different costs. My assessment (posted https://github.com/lucas42/lucos/issues/296#issuecomment-5673068021): rotate `server_key` (free), treat `data_key` as a consciously-accepted risk for this restore, and file a proper follow-up to build the rotation tooling as standing debt — not something to build under incident pressure.

**How to apply:** any time a `lucos_creds`-adjacent decision talks about "rotating the creds keys" as a single action, check which of the two this actually means — the cost difference is the whole ballgame. If a follow-up issue to build `data_key` rotation tooling gets filed, link it here. Until then, assume `data_key` cannot be rotated without first building that tooling.
