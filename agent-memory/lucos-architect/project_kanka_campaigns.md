---
name: project-kanka-campaigns
description: Self-hosted Kanka system for DMing Kaidoho (lucos#309) — plan, verified Kanka self-host facts, decisions pending
metadata:
  type: project
---

2026-09-28: lucas42 wants Kanka (self-hosted) to DM the **Kaidoho** campaign (starts w/c 2026-10-05); Arcadia stays in lucos_worlds; nothing deleted from worlds (duplicate until confident). Plan + 4 decisions filed as **lucas42/lucos#309**.

**Verified against owlchester/kanka source (release 3.15):** upstream's docker is DEV-ONLY ("Do not use… on the web", no prod image); self-host lacks premium features + FontAwesome PRO; no generic OIDC (Socialite FB/Google/Twitter only) → sidecar oauth2-proxy pattern (lucos_locations already has ES256 config) + `APP_REGISTRATION_ENABLED=false`; LICENSE = bare Commons Clause, no base licence (NOASSERTION); MinIO upstream-admitted abandoned → use local `public` disk (unverified e2e); Thumbor optional (disabled when key empty; its image amd64-only); step-through-every-tag upgrades; REST API covers characters/locations/notes/posts/entity_types → scripted migration works vs kanka.io or self-host.

**Why it differs from July's rejection (worlds ADR-0001):** requirement changed player→DM; auth objection answered by sidecar; licence + upkeep objections stand (upkeep worse).

**How to apply:** new repo's ADR-0001 once lucas42 picks name (suggested `lucos_campaigns`); then file ADR/scaffold/auth/backups/migration tickets there + worlds ticket to set Kaidoho book view-only post-cutover. Recommended session 1 NOT depend on self-host (kanka.io free-tier trial or BookStack).
