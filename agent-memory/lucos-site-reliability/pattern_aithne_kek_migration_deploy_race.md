---
name: pattern-aithne-kek-migration-deploy-race
description: aithne SIGNING_KEK breaking-migration deploy race — recovery gotchas, the dev-creds secret-handoff pattern, and the orb health-gate-but-no-rollback fact
metadata:
  type: project
---

2026-06-30 ~46-min estate-wide auth outage. lucos_aithne#260 (v2.0.0) changed `SIGNING_KEK` derivation raw-bytes→`sha256(value)` — a breaking on-disk migration needing a one-time `--migrate-kek` BEFORE the new image serves. lucos auto-deploys on merge, so it deployed first → couldn't decrypt the raw-wrapped signing key → crash-loop. Full report: `lucos/docs/incidents/2026-06-30-aithne-kek-migration-deploy-race.md`.

**Why:** the deploy-vs-migration race is structural (breaking on-disk migration + auto-deploy-on-merge). Architect's sharper framing: it was operator-dependent ONLY because the release bundled a fresh-KEK *value* rotation with the *format* change; the format change alone was dual-readable and could have self-migrated. Decouple value-rotation (online `--rekey` after new code serves) from format change.

**How to apply — `--migrate-kek` / KEK-op recovery gotchas (all bit me; tracked for fixing in lucos_aithne#262):**
- Image is `FROM scratch`, **no entrypoint** → invoke `/lucos_aithne --migrate-kek`, NOT bare `--migrate-kek` (bare → exec-not-found exit 127).
- `main()` runs `getEnvRequired("PORT")` **before** subcommand dispatch → maintenance subcommands need `PORT` set even though unused.
- creds `.env` **quotes every value**; the SCP read preserves quotes, the deploy **strips** them. Feed migrate-kek the **UNQUOTED** value (byte-exact match to container runtime). Off-by-quote = migrate-kek **exit 0 then startup crash** (silent — sha256("…46…")≠sha256("…44…")). Proof quotes-stripped: dev `SIGNING_KEK` 34 chars quoted but container env held 32.
- `docker start` of a stopped container **reuses its OLD baked-in env** → would crash again. Must **REDEPLOY** (fresh CI pipeline; deploy fetches creds) to inject the new `SIGNING_KEK` — I can't read prod creds to build an .env by hand.
- migrate-kek decrypts with raw-bytes(OLD), re-encrypts `sha256(NEW)`. `--rekey` is sha256 both sides (the tool for all FUTURE rotations).
- Verify recovery: `/_info` db+signing_key+signing_key_age, and JWKS `kid` UNCHANGED (key preserved, not regenerated). Passkey login is human-only (lucas42).

**Secret handoff when agent needs a prod secret it can't read/write** ([[pattern_contacts_403_for_unrecognised_key]] world: agent can't read OR write prod creds): lucas42 writes the value to BOTH prod (`SIGNING_KEK`) AND a dev temp key (`SIGNING_KEK_MIGRATE_HANDOFF`); agent reads the dev key (dev creds ARE agent-readable), uses it, then clears the temp key (`ssh -p2202 creds.l42.eu 'lucos_aithne/development/SIGNING_KEK_MIGRATE_HANDOFF='`). Keeps the prod secret out of the chat channel. Container stopped → no ordering race between his creds write and the migrate. creds ssh-exec syntax = `<system>/<env>/<KEY>=<value>`.

**Deploy orb behaviour (lucos_deploy_orb `src/commands/deploy.yml`):** DOES health-gate — `docker compose up -d --wait --wait-timeout 180`, 3 attempts, restarts created/unhealthy between tries — and **fails the CI job** on persistent unhealthy. But **NO rollback**: on failure it `exit 1`s and leaves the broken container under `restart: always` to crash-loop. So *a crash-loop after a deploy usually means the CI deploy job failed but didn't revert.* Architect #261 option = add rollback-to-previous-image (safe only if the migration is forward+backward-compatible, expand/contract — design discipline makes rollback safe).

**Open follow-ups:** lucos_aithne#261 (ordering gate; migration ADR pending lucas42's direction — I file+assign architect when it settles), lucos_aithne#262 (clearer undecryptable-key error vs "database may be corrupt", drop PORT for subcommands, fix migrate-kek/rekey docs incl. stale `lucos_aithne_web` names), lucos#260 (UX auth-unavailable messaging).
