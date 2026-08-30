---
name: creds-vs-configy-namespaces
description: lucos_creds "system" (a principal) and lucos_configy "system" (a deployed unit) are different concepts — why creds must never gate writes on configy membership, and the three-registry audit that proves it
metadata:
  type: reference
---

# `lucos_creds` "system" ≠ `lucos_configy` "system"

Settled on lucas42/lucos_creds#473 (2026-08-06, [comment](https://github.com/lucas42/lucos_creds/issues/473#issuecomment-5207850597)). Complements [[creds-configy-sync]] (which covers the *value* sync) — this one is about the *namespace* relationship.

- **configy `system`** = a deployed unit: domain, `http_port`, hosts.
- **creds `system`** = a **principal**: something that holds credentials and can be authenticated.

Large overlap, but **not identity, and divergence runs both ways** — so **never gate a creds write (or delete) on configy membership.**

## Always audit against all THREE configy registries

`config/systems.yaml` + `config/components.yaml` + `config/scripts.yaml`. Diffing against `systems.yaml` alone produces a false "absent from configy" set. Verified 2026-08-06 (`ls` on the store, `comm` against `origin/main` keys; `development` only — no agent key reads production):

- 11 dev creds systems absent from `systems.yaml`, of which **4 are in the other two registries**: `lucos_agent`, `lucos_contacts_fb_import`, `lucos_contacts_gphotos_import` (scripts), `lucos_search_component` (components).
- **5 absent from all three, all legitimate**: `external_calendar` (third-party inbound consumer — holds only `KEY_LUCOS_CONTACTS`), `local_testing`, `lucos_test`, `test_app` (test identities, client keys only), `lucos_scheduled_scripts`.
- Reverse direction: `lucos_deploy_orb`, `lucos_photos_android` are configy systems with **no** dev credentials.

**Snapshot has since drifted (2026-08-30):** `lucos_contacts_fb_import` was decommissioned (lucas42/lucos#271) — removed from `scripts.yaml` and its dev credential deleted — so the counts above no longer hold. Left as the dated 2026-08-06 figures deliberately: per the warning below, re-derive by parsing rather than adjusting a remembered total by hand. The point the example makes is unaffected — `gphotos_import` and `search_component` still show that a `systems.yaml`-only diff produces a false "absent from configy" set.

Both `lucos_creds` ADR-0005 (PR #472) and #473's body state a "seven systems absent from configy" list that is wrong on both counts. **Re-derive by parsing; never quote that list.**

## The precedent chain (cite these, don't re-argue them)

- **`lucos_creds` ADR-0001** (Accepted 2026-06-04, audit #333) already decided this for *deletion*. Rejects "key off `systems.yaml` membership alone" as *"this is the dangerous design"*, and rejects an exemption allowlist as *"a maintenance burden that would silently rot"*. Both rejections transfer verbatim to a write gate.
- **lucas42's constraint** (on #470, implemented in ADR-0005 §6): a configy outage must not prevent linked credentials being created, read, deleted or rotated. Validation reads creds' own DB, never calls configy. A write-time gate is that coupling one step wider — and you need the credential store most during an incident.

## Design pattern: gate on **novelty**, not on membership

The dangerous operation is not "writing to a system configy doesn't know about" — it is **silently creating a namespace**. The store knows whether a `system`/`environment` pair exists; it just doesn't treat crossing that line as significant. Gating on novelty catches the *plausible* typo (`lucos_photo`) that shape validation can't, needs no external dependency, has no exemption set to rot, and applies symmetrically to the environment field (ADR-0002's open environment namespace carries the same hazard). It doesn't close the namespace — any name stays permitted, it just stops being **silent**. Raised as lucas42/lucos_creds#507 (ADR-shaped: changes the SSH exec write protocol + needs a UI affordance + touches ADR-0002).

Generalise: when tempted to gate writes on membership of another system's registry, first ask whether the two registries name the same *kind* of thing. Usually the real invariant is local (shape, or novelty), and the membership check is a coarse proxy that both over- and under-fires.

## Two mechanism facts worth keeping

- **Identifier shape is unvalidated at the store; the rule already exists at the UI.** `assertSafeIdentifier` (`ui/src/index.js`) enforces `^[a-zA-Z0-9_-]+$` on system/environment/key, but only on UI write paths. `storage.go` validates only the *key* (`normaliseCredentialKey`). All 48 legitimate dev systems pass the rule; only `set lucos_notes` / `write lucos_notes` fail — so moving it to the store is a no-migration change.
- **A malformed system name poisons a *third party's* `.env`.** `KEY_<SERVERSYSTEM>` is upper-cased into an env var *name*, and `generateEnvFile` escapes only `=`. A link to `set lucos_notes` emits `KEY_SET LUCOS_NOTES="…"` into the **client's** `.env` — unparseable, failing at deploy, far from the write that caused it. Instance of [[feedback_new_validation_makes_existing_rows_unwritable]]'s sibling concern: also **exempt the delete paths** from any new shape rule, or pre-existing malformed rows become undeletable.

See also [[creds-test-environments]] (ADR-0002 open environment namespace), [[creds-origin-envvars]], [[reconcile-empty-source-guard]].
