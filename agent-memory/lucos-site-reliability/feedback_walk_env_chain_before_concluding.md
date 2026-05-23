---
name: feedback-walk-env-chain-before-concluding
description: When a container env var is empty, walk the four-link chain (lucos_creds → .env → docker-compose.yml → container) before concluding which link is the gap. Don't jump from link 4 empty straight to link 1 missing.
metadata:
  type: feedback
---

When `docker exec printenv VAR` (link 4) returns empty in production, **walk the chain in order** (compose passthrough first, then .env, then lucos_creds) before concluding which link is the gap. Do not skip from "link 4 empty" to "lucos_creds missing the value" — those are not adjacent.

**Why:** The most common cause of an empty link 4 is actually link 3 (variable not in `docker-compose.yml`'s `environment:` block), not link 1. Misrouting to lucas42 with a "needs production cred written" ask when the actual fix is a one-line PR to `docker-compose.yml` wastes a creds-write ask and routes the work to the wrong person. lucas42 corrected me on this on 2026-05-23 (lucos_loganne#490): the fix was a missing docker-compose.yml `environment:` entry for `KEY_LUCOS_MEDIA_METADATA_API` — the value WAS in lucos_creds. The structural startup guard (`validateWebhooksConfig()`) had already shipped, so the deploy succeeded, but link 3 was broken — the var never reached the container.

**How to apply:** Whenever I report a missing-env-var diagnosis, my report must include explicit confirmation of links 2 and 3 (not just link 4 empty) before naming link 1 as the gap. Cross-reference [[pattern-three-stage-env-var-wiring]] which is the live checklist. The new "Investigating missing env vars in a container" section in `agents/sre-operational-defaults.md` was rewritten to make the four-link chain unmissable — read it before composing the diagnosis report, not after.

**Diagnostic sequence (from the updated operational defaults):**

1. Container env (link 4): confirm via `ssh <host> "docker exec <name> sh -c 'echo \${VAR_NAME:+set} \${#VAR_NAME}'"`.
2. Compose passthrough (link 3): `grep VAR_NAME ~/sandboxes/<service>/docker-compose.yml`. **If the var is not listed under `environment:`, this is the gap — stop here.**
3. .env at deploy time (link 2): inferable from CI build logs.
4. lucos_creds (link 1): conclude only when 2 and 3 are verified present.
