---
name: risk-lucos-creds-no-data-key-rotation
description: lucos_creds has no mechanism to rotate its own master AES data_key (orphans every credential instead), AND its data_key is currently readable via world-readable lucos_backups archives (lucos_backups#418, Critical).
metadata:
  type: project
---

**Standing architectural gap, independent of any specific incident:** `lucos_creds`'s server (`server/src/storage.go`, `keys.go`) has two secrets that follow the same "generate on first boot if the file is absent" pattern (`getCreateBlockCipher` / `getCreateSshSigner`), but they are NOT equally rotatable:

- **`server_key`** (`/var/lib/creds_store/server_key`, the SSH host identity for `creds.l42.eu:2202`) — free to rotate. It authenticates the server to connecting clients only; it doesn't encrypt any stored data. Omit it from a restore/redeploy and the server mints a fresh one; clients just need a `known_hosts` update.
- **`data_key`** (`/var/lib/creds_store/data_key`, AES-256-GCM key encrypting every stored credential's `EncryptedValue` in the sqlite store) — **there is no rotation/migration tooling anywhere in the repo.** Deleting the file does not rotate the key; the server generates a fresh one and every existing encrypted row becomes permanently undecryptable (no decrypt-old/re-encrypt-new path exists). A real rotation requires new migration code that has never been written.

**How this surfaced:** avalon's disk failed (lucas42/lucos#294) and left custody unencrypted for OVH's disk swap (lucas42/lucos#296). The architect framed "restore the old creds keys vs. mint fresh ones" as one decision; I read the source before answering and found it's actually two decisions with very different costs. My assessment (posted https://github.com/lucas42/lucos/issues/296#issuecomment-5673068021): rotate `server_key` (free), treat `data_key` as a consciously-accepted risk for this restore, and file a proper follow-up to build the rotation tooling as standing debt — not something to build under incident pressure.

**How to apply:** any time a `lucos_creds`-adjacent decision talks about "rotating the creds keys" as a single action, check which of the two this actually means — the cost difference is the whole ballgame. Tracked as lucas42/lucos_creds#565.

**Related, more urgent finding (2026-09-18):** the rotation gap above is about *capability*; separately, the `data_key` + `creds.sqlite` co-location is **currently readable today**, rotation notwithstanding. Routine daily/monthly `lucos_backups` volume archives are created world-readable (644, no `umask`/`chmod` in `Volume.archiveLocally()`) — confirmed directly on xwing (`lucos-agent` could read `lucos_creds_store.*.tar.gz` without owner/group access, archives dated back to 2026-01-06). Since `data_key` sits in the same volume as `creds.sqlite`, every such backup is self-decrypting: no privilege escalation needed, just a plain file read. Filed as lucas42/lucos_backups#418 (Critical). This is a distinct, more directly exploitable vector than the docker-group root-equivalence tracked in lucas42/lucos_agent_coding_sandbox#102 — no escalation required at all here.
