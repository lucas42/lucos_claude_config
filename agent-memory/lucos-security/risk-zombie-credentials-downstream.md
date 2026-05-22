---
name: risk-zombie-credentials-downstream
description: Risk pattern — removing a service from CLIENT_KEYS does not revoke its pre-registered credentials in downstream keystores (typesense, etc.)
metadata:
  type: project
---

When a service is decommissioned and its keys are removed from `lucos_creds` / `CLIENT_KEYS`, **any downstream service that pre-registered those keys in its own keystore retains them indefinitely** until the consumer is restarted or the keys are explicitly purged.

Surfaced in the lucos_arachne incident (2026-05-21): `lucos_comhra` was decommissioned months prior but its typesense API keys (`:production` and `:development`) remained registered in the typesense keystore until a restart during the hotfix for lucas42/lucos_arachne#556. Keys were not actively used, values not exposed, but they existed unnecessarily.

**Why:** CLIENT_KEYS removal stops new deployments from receiving the credential, but a running consumer that already registered the key doesn't know to revoke it.

**How to apply:** The archival checklist (`docs/repo-archival.md` in `lucos`) should require an explicit credential revocation step for any downstream service that pre-registers keys (not just "remove from lucos_creds"). Currently coordinating with lucos-site-reliability before filing the issue (2026-05-21).

Known affected systems: typesense (lucos_arachne). Investigate whether other downstream datastores have the same pattern.

[[risk-pattern-decommission-checklist]]
