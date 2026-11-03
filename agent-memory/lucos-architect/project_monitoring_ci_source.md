---
name: monitoring-ci-source
description: lucos_monitoring#320 design — replace CircleCI API polling (PAT, ≤1yr expiry, UI-only creation) with GitHub commit statuses via one GraphQL query + dedicated read-only GitHub App
metadata:
  type: project
---

2026-11-03: proposed on lucas42/lucos_monitoring#320 (awaiting lucas42's pick). Option A = read `ci/circleci:*` commit statuses on main HEAD via one GraphQL query/min (cost 1 pt), auth via dedicated GitHub App (Metadata+Commit statuses read). B = keep CircleCI token + jitter + 401 alert. C = webhooks (rejected).

Measured CircleCI limits (headers, not published): 300/s global (`x-ratelimit-limit`, reset 1), 50/s on `/pipeline/:id/workflow` route. Monitoring: ~316 req/60s cycle, but 56 in-step loops → ~52-request workflow bursts just over 50/s. Anonymous workflow endpoint returns 404 "Pipeline run not found."

**Why:** lucas42 refuses manual rotation; CircleCI PATs must expire ≤1yr and can only be created in the UI. GitHub App PEMs don't expire, installation tokens self-rotate.

**How to apply:** if A is chosen, file impl ticket(s) with lucos-security's conditions (comment 6617528452): dedicated App, explicit minimal perms on mint, prod-only key, fail loud (no quiet green on mint/JWT failure), keep PEM/token out of state and crash dumps, JWT exp ≤10min, PEM newline formatting. App creation routed to lucas42. Mapping rules: stale PENDING → unknown; config present but no contexts → unknown; no .circleci/config.yml → exempt. Ties to #302 and #313.
