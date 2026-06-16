---
name: reference-aithne-agent-principal-model
description: Where aithne agent credentials live + which adoption steps need lucas42 (for the lucos_authentication→aithne migration)
metadata: 
  node_type: memory
  type: reference
  originSessionId: 627351b7-afde-4c02-b300-6bd37dd4f6c4
---

How a service adopts an **aithne agent principal** (machine/agent auth via OAuth2 client-credentials → agent-class JWT → JWKS verify). Surfaced during the lucos_arachne canary ([[project_v3_migration]] sibling work; tracking lucas42/lucos_aithne#12).

**Credential home — agent-operating creds are DEV, not prod.** A principal's key to authenticate *itself* to lucos services (the `client_secret` for its aithne machine key) lives in **lucos_agent's `development` environment** in lucos_creds, and is **agent-writable** (the developer provisions it). Do NOT assume "agent credential → production → lucas42 sets it." The lucos_creds environment is keyed by the *consuming system+environment*; agents only have a dev environment, so even calling a *production* target, their key lives in lucos_agent/development. Pin down system+environment before stating who writes a credential — that's what determines write access (dev = agent-writable; prod = lucas42-only per the creds model).

**Two prod aithne-admin actions DO need lucas42 at cutover (zero creds-writes):**
1. Mint the machine key — `POST /admin/machine-keys` (returns one-time `client_secret`).
2. Grant the agent the scope its target endpoint checks — `/admin/grants` (new agents are **default-deny**, so the key alone won't authorise).

Both are gated by the `aithne:admin` scope, **HTTP-only — no CLI/host-exec bypass** (aithne's only binary subcommands are `--healthcheck` and `--bootstrap-invite`). On **production** aithne, `aithne:admin` is lucas42's (bootstrap admin, human-gated default-deny), so the developer cannot self-provision a prod machine key. Build agent-principal migrations so cutover is a clean copy-paste handoff for lucas42 (exact calls + payloads + the dev creds key).

**JWT contract (canonical home lucas42/lucos_aithne#5):** claim `principal_class` (agent value `"agent"`); granted-scope claim is `scopes` (plural); `aud` is a **fixed `"l42.eu"`** for all principals — validate `aud == "l42.eu"`, NOT the service's own origin.
