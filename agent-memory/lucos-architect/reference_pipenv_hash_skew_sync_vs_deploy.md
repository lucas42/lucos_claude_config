---
name: pipenv-hash-skew-sync-vs-deploy
description: pipenv 2026.4.0 PEP 503-canonicalises package names before computing Pipfile _meta.hash, so Dependabot's older vendored pipenv and ours disagree; `pipenv sync` gives every --deploy guarantee except freshness, without reading the field
metadata:
  type: reference
---

**pipenv `2026.4.0` began PEP 503-canonicalising package names (lowercase, `_`/`.` → `-`) before computing `_meta.hash.sha256`.** Dependabot's vendored pipenv is on the pre-`2026.4.0` side. Both compute "correct" hashes of the same unchanged `Pipfile`; `--deploy` compares them literally and aborts.

**Predictive rule (verified 3/3 and 5/5 across the 8 live pipenv repos, 2026-08-26):** a repo is exposed **iff its `Pipfile` names at least one package non-canonically** — uppercase letters or underscores (`PyJWT`, `lucos_loganne_pythonclient`). All-lowercase-hyphenated Pipfiles hash identically under both generations.

**Why this matters beyond the hash:** `pipenv install` re-locks and re-resolves the whole graph from the registry on *any* hash mismatch, exit 0, no warning. So a skew-caused mismatch is indistinguishable from drift at build time — it caused the 15h24m `lucos_backups` outage (lucas42/lucos_backups#390). "Skew, not drift" names the cause; it does **not** mean the locks are fine.

**`pipenv sync` vs `pipenv install --deploy` — measured, not read off docs:**

| Guarantee | `--deploy` | `sync` |
|---|---|---|
| Installs exactly the locked versions, never re-resolves | yes | yes |
| Verifies artifacts against the lock's `hashes` (pip hash-checking mode) | yes | **yes** |
| Fails loudly with no lockfile | yes | yes (exit 1) |
| Enforces `[requires] python_version` | yes | yes (exit 1) |
| Asserts lock derives from current Pipfile (`_meta.hash`) | yes | **no** |
| Immune to the checksum skew | no | yes |

Two consequences that keep catching people:
- **The lock already carries artifact hashes and pipenv already enforces them.** So "generate `requirements.txt --require-hashes` for cryptographic pinning" buys nothing over `sync` — it only removes pipenv from the image, at the cost of a derived artefact Dependabot doesn't maintain (bump lands in the lock, requirements.txt stays stale, CI green, bump silently a no-op).
- **`sync`'s only loss is freshness:** a `Pipfile` edited without re-locking silently installs the old set. Partly self-announcing (ImportError) if the test stage runs against the installed env; a raised version *floor* passes silently. The proper fix is a constraint check (does the locked set satisfy the Pipfile?), not a metadata proxy.

Never hang a hard build gate on a checksum whose definition is owned by two third parties that must agree — it has failed once and nothing prevents a third normalisation change. See [[frozen-install-build-integrity]].
