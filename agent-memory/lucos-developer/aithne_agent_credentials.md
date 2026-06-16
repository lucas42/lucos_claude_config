---
name: aithne-agent-credentials
description: Per-agent aithne principal model and env-var naming convention for machine keys
metadata:
  type: project
---

## Per-agent aithne principals — never a shared identity

Each agent persona gets its own aithne principal. Slug = the personas.json slug (e.g. `lucos-architect`, `lucos-developer`). ADR-0001 §4 + §6 mandate this — a shared fleet identity collapses per-principal audit and scope.

**Why** A shared `lucos_agent` principal looked tempting (mirrors the old shared `KEY_LUCOS_ARACHNE`), but the old shared key is exactly the pre-aithne limitation we're migrating away from.

## Env-var naming convention

Machine key secrets live in `lucos_agent/development` in lucos_creds, mirroring the PEM layout:

| What | Var name |
|------|----------|
| `lucos-architect` secret | `LUCOS_ARCHITECT_AITHNE_CLIENT_SECRET` |
| `lucos-developer` secret | `LUCOS_DEVELOPER_AITHNE_CLIENT_SECRET` |
| `lucos-ux` secret | `LUCOS_UX_AITHNE_CLIENT_SECRET` |
| (general pattern) | `LUCOS_<PERSONA_UPPER>_AITHNE_CLIENT_SECRET` |

The `client_id` is the slug itself (`lucos-architect`) — **no separate `AITHNE_CLIENT_ID` var**; the persona knows its own slug.

## How to apply

When provisioning a machine key for any persona to call an aithne-gated service:
1. Slug = persona's personas.json slug
2. Secret var = `LUCOS_<PERSONA>_AITHNE_CLIENT_SECRET` in `lucos_agent/development`
3. Never use a shared slug like `lucos_agent` — that's the old shared-key anti-pattern

See [[aithne_agent_principal_model]] for the broader aithne agent model.
