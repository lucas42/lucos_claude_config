---
name: risk-npm-lockfile-version-drift
description: When adding an npm override to fix a transitive-dependency CVE, a fresh `npm install` on a repo's older lockfileVersion:2 file silently bumps it to v3 unless forced — inflating the diff with unrelated format churn.
metadata:
  type: project
---

Fixing tfluke#61 (js-yaml CVE-2026-84375, transitive via supertap/tap-xunit) needed a new `package.json` override. Two gotchas hit in sequence:

1. **Incremental `npm install` on top of an existing lockfile does NOT re-resolve already-resolved transitive packages to satisfy a newly-added override.** A `rm -rf node_modules package-lock.json` (full regen) is required before the override actually takes effect — an in-place `npm install` left the vulnerable nested version untouched even with the override present in `package.json`.

2. **A full regen on npm 10.x defaults to `lockfileVersion: 3`**, which drops the legacy `dependencies` tree that `lockfileVersion: 2` keeps for npm-v6 back-compat. If the repo's committed lockfile is v2 (tfluke's was, likely last touched by an older npm/Dependabot run), a plain regen produces a ~2500-line diff that's pure format noise, not the actual fix. Use `npm install --lockfile-version=2` to force the regen to keep the existing format and produce a diff that's just the version bumps.

**How to apply:** any time a security fix for a lucos JS/TS repo needs a `package.json` override for a transitive dependency: (a) always do a full `rm -rf node_modules package-lock.json && npm install`, never an incremental install, to confirm the override actually resolved (check the specific nested `node_modules/.../package.json` version afterwards — don't just trust `npm audit`'s exit code); (b) check the current committed lockfile's `lockfileVersion` first and pass `--lockfile-version=<N>` to match it, so the diff stays scoped to the actual dependency change. Worth checking whether other lucos JS repos are still on v2 — if the estate is mixed, this will recur.

See [[risk-build-time-dependency-reresolution]] for a related but distinct npm/PyPI risk (build-time re-resolution bypassing Dependabot review entirely) — this note is about a *tooling* gotcha in fixing an already-known alert, not a review-bypass risk.
