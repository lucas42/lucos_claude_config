---
name: route-registration-order-for-auth-exemption
description: lucas42 prefers exempting public routes (/_info, static) via registration order before the auth middleware, not an in-middleware path allow-list
metadata:
  type: feedback
---

When documenting or designing how a service exempts public routes (`/_info`, static
resources, login) from session-auth, **prefer route-registration order** — declare the
public routes *before* the auth middleware is added to the chain, so the middleware never
sees them and holds zero per-path knowledge. Recommend this as the default; treat an
in-middleware `request.path == "/_info"` allow-list as a *fallback* only for frameworks
that wrap the whole app in one middleware with no per-route exemption (ASGI/Python — why
arachne's `mcp/server.py` does it that way).

**Why:** lucas42's review on lucos_aithne PR #187 (2026-06-23). An in-middleware allow-list
duplicates the app's routing knowledge: every change to the set of public paths must be
mirrored in the middleware in lock-step, and forgetting is a security hazard (a route
silently left unauthenticated, or a public route that starts demanding auth). Registration
order keeps the "is this public?" decision in one place — the route table. Reference impl:
`lucos_notes` `src/server/index.js` (`/_info` + `express.static` registered before
`app.use(auth)`).

**How to apply:** in any auth-middleware / route-exemption design or contract doc, lead with
registration-order as canonical and explain the duplication/drift hazard; only present the
in-middleware path check as a constrained fallback, flagged as needing to be kept in sync.
Don't frame the two as equal options (my original #157 draft did, picking the in-middleware
check as "canonical" — lucas42 flipped it). Related: [[reference_info_endpoint_network_only]].
