---
name: /_info network_only is NOT access control
description: The network_only field in /_info is a frontend offline-capability hint, not a security/access-control attribute
type: reference
---

`network_only` in `/_info` is a **Tier-3 frontend-only hint** meaning "the service requires a network connection to work" (i.e. it is not a PWA / does not work offline). Default is `true`. It exists so the homepage (lucos_root) can show users which services work offline.

**It has nothing to do with authentication, access control, or network-level isolation.** A service with `network_only: true` is not declaring that it's "internal-only" or "behind a firewall" — that would be a deployment-topology concern, not an app-level one.

**Why this matters:** it is very easy to read `network_only: true` as "only accessible on the internal network" and use it to justify skipping auth. That reasoning is wrong. If a lucos service has no auth, the real security boundary is whatever routing/firewall topology the deployment provides — not anything the app declares in `/_info`.

**How to apply:** when reasoning about whether a service is safe to expose an unauthenticated endpoint on, never cite `network_only: true` as the justification. Cite the actual deployment topology (e.g. "only reachable via internal routing on avalon"), or cite consistency with existing unauthenticated endpoints on the same service, or acknowledge the auth question as out of scope. The `/_info` spec lives at `~/.claude/references/info-endpoint-spec.md` — consult it before referring to any `/_info` field in a design argument.

**Where this bit me:** lucas42/lucos_schedule_tracker#9 design comment, 2026-04-18. Initial draft argued `network_only: true` was the service's security boundary; lucas42 flagged the mistake. Comment edited to correct the reasoning.
