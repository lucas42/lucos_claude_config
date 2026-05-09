---
name: When a fix doesn't take after a redeploy, ask whether deploy reads live state or a snapshot
description: Some deploys read configuration from out-of-band snapshots; live changes don't propagate until the snapshot is refreshed
type: feedback
---

When a fix to live state ("I corrected the value in lucos_creds / consul / etc.") does not propagate after a redeploy, do not jump to "the fix didn't take" or "the user re-stored it wrong." First ask: *"does the deploy actually read this value from the live store, or from a snapshot?"*

**Why:** Bit me 2026-05-09 in the lucos_creds CRLF incident. lucas42 had correctly fixed the SSH keys in `lucos_creds` storage; the redeploy still wrote the old corrupted bytes because the deploy orb decoded a stale `LUCOS_DEPLOY_ENV_BASE64` snapshot from CircleCI (set 2026-04-10, never refreshed). My intermediate diagnosis said "lucas42's re-store didn't take" — confidently wrong. The right diagnostic question would have caught the snapshot indirection in seconds.

**How to apply:**

1. When `service A` reads its config from `service B`, the deploy may or may not bypass `service B`. Bypasses exist for good reasons (avoiding circular dependencies, supporting offline deploys, sandboxes). Always check `.circleci/config.yml`, deploy-orb usage, and any `*_DEPLOY_*` / `*_SNAPSHOT*` / `*_ENV_BASE64` project env vars before assuming the live path is the only path.
2. The lucos_creds-specific reference is in `reference_lucos_creds_self_deploy.md`. When investigating lucos_creds, check `LUCOS_DEPLOY_ENV_BASE64` first.
3. Generalise to other services: any time a service stores credentials/config that could create a circular deploy dependency, the deploy *probably* has a snapshot path. Worth a one-line grep.
