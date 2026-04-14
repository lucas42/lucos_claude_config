---
name: lucos_arachne triplestore health check history
description: The triplestore check in lucos_arachne /_info was deliberately removed in #104 due to Fuseki unreliability causing noisy alerts
type: project
---

The `checkTriplestore()` health check in `explore/src/server/index.js` was intentionally removed in lucos_arachne#104 because Fuseki is unreliable and causes constant noisy/flapping alerts in monitoring.

**Do not approve re-adding a triplestore health check** to `/_info` without confirming the alerting context. lucos_monitoring#74 (configurable consecutive-failure thresholds) has now landed (closed 2026-04-14), which mitigates alert fatigue — but the underlying Fuseki reliability concern remains.

**Why:** Approved the re-addition in #218 without knowing this history; it was immediately reverted in #219.

**How to apply:** If a PR adds `checkTriplestore()` or any equivalent triplestore availability probe to `/_info`, flag this and reference #104. Note: Docker Compose `depends_on: condition: service_healthy` for triplestore is NOT the same thing and is safe to approve — it controls startup ordering only, not `/_info` reporting.
