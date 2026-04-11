---
name: Auth fail-open/fail-closed question unresolved
description: The question of whether lucos_media_metadata_manager fails open or closed when auth.l42.eu is unreachable was never explicitly verified — should be addressed when auth service work happens
type: project
originSessionId: 9777c034-07fc-4b8e-9216-8d1573f7ea53
---
When working on the authentication service or any service that depends on auth.l42.eu, verify and document whether each service fails-open or fails-closed when auth.l42.eu is unreachable or returns unexpected responses.

**Why:** lucos_media_metadata_manager#215 raised this as a potential P0 security issue (if fail-open, unauthenticated access is possible when auth is degraded). The issue was closed because it was out of scope for the immediate monitoring request, but the underlying question was never answered.

**How to apply:** When auth service work is in scope, add "verify fail-open/fail-closed behaviour" to the checklist for any service touching auth. If fail-open is discovered, raise a separate security issue immediately.
