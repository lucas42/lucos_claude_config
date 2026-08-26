---
name: pipenv-hash-algorithm-skew
description: pipenv changed its Pipfile-hash algorithm between 2026.2.2 and 2026.4.0; Dependabot's vendored pipenv is on the old side, so every lock it writes fails `pipenv install --deploy` against a newer pinned pipenv. Looks exactly like lockfile drift and is not.
metadata:
  type: project
---

**`Pipfile.lock`'s `_meta.hash.sha256` is a pure function of `Pipfile` — and pipenv changed that function between `2026.2.2` and `2026.4.0`.**

Measured 2026-08-26 against `lucos_backups/src/Pipfile`, unmodified, one file, six interpreters:

| pipenv | hash |
|---|---|
| 2026.2.1, 2026.2.2 | `15e6bab1…` ← what Dependabot writes |
| 2026.4.0, 2026.6.2, 2026.7.1, 2026.8.0 | `9319c363…` ← what our pinned image expects |

The disagreement is **algorithmic and content-independent**: add `idna = "*"` to `[packages]` and the two generations return `674533b2…` vs `4fbb021a…` — still two answers for one file. So "pin the dependency directly in `Pipfile` so Dependabot's diff touches it too" does **not** fix it.

**Why:** Dependabot's vendored pipenv predates 2026.4.0. Any repo whose Dockerfile runs `pipenv install --deploy` with a newer pinned pipenv will reject every Dependabot-authored lockfile, deterministically — the hash is a function of a file that did not change, so `@dependabot recreate` and CI re-runs reproduce it byte-for-byte. Confirmed on lucas42/lucos_backups#403 (blocked lucas42/lucos_backups#399 then #401, same `idna` 3.18→3.19 bump, identical hash pair).

**How to apply:**

1. **Do not read a `_meta.hash` mismatch as lockfile drift.** Classify it first: compute the Pipfile's hash under an old pipenv (≤2026.2.2) and a new one (≥2026.4.0). Three buckets — matches-new, matches-old, matches-neither. Only **matches-neither** is real drift.
2. Estate classification, 2026-08-26 (8 live repos with `pipenv install` in a Dockerfile): 6 matches-new (backups, media_weightings, media_import, contacts_googlesync_import, creds/configy_sync, arachne/ingestor), **2 matches-old — `lucos_contacts` (`app/Pipfile`), `lucos_eolas` (`app/Pipfile`)**, and **0 matches-neither**. That reproduces the architect's 08-17 "3 mismatched / 5 in sync" exactly (backups since fixed by lucas42/lucos_backups#394) and shows the whole estate finding was version skew, never drift.
3. ⚠️**Scope the claim.** "The `_meta.hash` mismatch is version skew" is a statement about that metadata field only. It does **not** establish that each lock's resolved package set satisfies its Pipfile constraints — a different measurement, and arguably the one the convention actually wants.
4. **Blocker for lucas42/lucos_repos#488** (estate-wide `--deploy` rollout): rolling it out does two things, not one — it enforces the lockfile *and* stops Dependabot landing any Python update in those repos. On `lucos_contacts`/`lucos_eolas` it reds CI on the first build, before any bump.

**API gotcha:** pipenv **2026.8.0 renamed the method** — `project.pipfile.calculate_hash()`, not `project.calculate_pipfile_hash()`. My first 2026.8.0 probe returned blank because of the `AttributeError`, which reads exactly like "disagrees with everything". Empty output is unknown, not data — see [[feedback_treat_empty_tool_output_as_unknown]].

Related: [[pattern_baseimage_bump_runtime_break]] (the other family of "auto-merged dependency change breaks somewhere the build didn't look").
