---
name: c4-estate-model
description: lucos_repos ADR-0006 — generated C4 model of the estate from tangible data sources; source→edge-type mapping
metadata:
  type: project
---

C4 model of the lucOS estate, **generated from tangible data sources** (not hand-drawn). Decided in **lucos_repos ADR-0006** (Proposed; draft PR lucas42/lucos_repos#423, tracking lucas42/lucos_repos#422). lucas42 green-lit 2026-06-14; chose `lucos_repos` as the home over a new service / monitoring / standalone cron.

**Why:** estate at 41 systems; the inter-system dependency structure isn't written down anywhere whole. Hand-drawn diagrams rot — wanted an evergreen, data-derived model.

**Core design — no single source IS the graph; each captures a different edge type (typed by source):**
- Node set + deployment placement ← configy `systems.yaml`/`hosts.yaml` (static, canonical, never liveness-coupled)
- Container decomposition (C4 L2) ← per-repo `docker-compose.yml`
- Sync edges ← `/_info` `checks[].dependsOn` (live, self-declared)
- Async event edges ← loganne `webhooks-config.json` (consumer side only)
- Trust edges (+scope) ← creds `linkedCredentials` (live, directed; **phase 2**, needs a scoped creds read cred for repos)

Output: Structurizr DSL = model of record; Mermaid = GitHub-native connected-core view. Committed under `docs/c4/`; git history = architecture changelog. **Divergence between sources = audit finding**, routed via ADR-0004 issue machinery.

**Modelling rules worth remembering:** (1) loganne's own `dependsOn` on its consumers is the broker/alert-suppression relationship → model as async, NOT a sync edge (else double-counts loganne's fan-out). (2) async *producer* side is not derivable from any current source (loganne gives consumers only) — needs a new convention (systems declare emitted events); consumer-only until then.

**First-cut (2026-06-14):** 41 systems, 14 sync, 25 async, 3 divergences, 2 unreachable (dns/dns_secondary, no /_info). Divergences caught: `lucos_mail`→`lucos_mail_docs`, `tfluke`→`tfluke_app`, `lukeblaney_co_uk`→`lukeblaney.co.uk` (configy key vs /_info `system`).

**On sign-off:** mark ready, drive review loop (lucos-code-reviewer), file 5 follow-ups (Go impl, divergence→issue routing, phase-2 trust edges, async-producer convention, triage the 3 divergences).
