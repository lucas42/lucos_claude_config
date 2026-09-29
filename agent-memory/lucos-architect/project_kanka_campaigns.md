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

**2026-09-29 decisions (lucas42 on #309):** self-host, aim for next week, BookStack fallback; name `lucos_campaigns`; double login accepted. **Premium gating = `campaigns.boost_count`** (boosted >0, premium >=4; only kanka.io billing sets it). Checked on develop c700f46: relations ✅ (graph view gated), attributes + LOCAL attribute templates ✅, calendar/timeline ✅; **rendered stat-block sheets ❌** (marketplace plugins need boosted + APP_MARKETPLACE_URL; campaign CSS also boosted-only). Asked lucas42 if key/value attributes suffice before filing build tickets (comment 5880375063). Advised against flipping boost_count.

**2026-09-29 later:** lucas42 chose stat-block CSS option 2, deferred; build is go. Repo `lucas42/lucos_campaigns` NOT yet created (lucas42 creates repos, not Apps). Filed lucas42/lucos_auth_scopes#32 (`campaigns:use`, critical path: aithne+creds rebuild). ADR-0001 draft + 7 ticket bodies in the session scratchpad (lost after the session — regenerate from this note if needed). Design: build from tag 3.15 into serversideup/php:8.4-fpm-nginx-v4.5.1; app+MariaDB+Meilisearch+oauth2-proxy; NO Redis/worker/scheduler (sync queue; the Kernel schedule is kanka.io billing); /api gated too, migration runs inside compose network; route domain only after gate works. avalon x86_64, ~3GB free.

**Tickets filed 2026-09-29:** lucos_campaigns #1 ADR (architect), #2 scaffold/deploy (sysadmin), #3 migration (developer), #4 /_info, #5 release tracking, #6 stat-block CSS; lucos_worlds#94 Kaidoho view-only; lucos_auth_scopes#32 scope. Critical path #1→#2(+#32)→#3. Repo private and empty; the ADR PR needs a README bootstrap on main first. ADR draft deferred-work already carries these numbers.

**ADR-0001 MERGED 2026-09-29** (PR lucos_campaigns#7, 73dd062; approvals from lucas42, security and code-reviewer on e27e9aa; I merged manually on coordinator direction because the repo has no workflows, same as the worlds#1 precedent). Security added: migration uses a migration-only compose override, an ungated /api server block on an unpublished port with a project-private network, removed by redeploy; auth_request at server level; upstream-lockfile CVE blindness named as largest residual risk. /_info (SRE design, #4) + /favicon.ico are the only gate exemptions. #2 body now carries the full security AC list. Next on the critical path: #2 (sysadmin).
