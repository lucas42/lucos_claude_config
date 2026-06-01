---
name: machine-principal-sessions
description: Auth design for lucos#132 — non-human principals (lucos_root service, trusted LLM agents) should be session-capable, not a separate bearer scheme
metadata:
  type: project
---

# Machine-principal sessions (lucas42/lucos#132 auth design)

Design agreed with lucas42 2026-06-01 while framing how lucos_root#135 (live homepage dashboard) depends on the new auth service (lucas42/lucos#132). Tickets are Ideation — this is forward design, not yet built.

**Decision:** the new auth service should let a **non-human principal** (a service like lucos_root, or a trusted LLM agent) obtain a session **non-interactively** (pre-shared key, not a passkey ceremony), and backends validate that session **identically to a human session** (same `/data`-style lookup, resolving to a service-account contact ID).

**Why:** the alternative — a parallel bearer scheme — forces **dual authentication** on every backend (each grows a second auth path), because the estate's existing SSE / web-component endpoints are all built around the human session. Making machine principals session-capable means backends need **zero auth change**: lucos_root presents the session as a cookie (it's a server-side client, can set any header) and consumes existing human-session SSE feeds unchanged. Separate *acquisition* (non-interactive) from *presentation* (ordinary session) — the earlier wish-list discussion conflated them.

**Unification:** "lucos_root reads estate data as a service" and "trusted LLM agent authenticates" are the same requirement — a non-human principal needs a session. Solve once.

**Critical caveat — unify authN, NOT authZ:** a machine session validates like a human session but must NOT *be able to do* everything a human can. Any backend gating a sensitive action on "is there a valid session?" (not on contact ID) would start accepting machine principals. Two guard rails, decided in #132 not per-backend: (1) machine sessions scoped least-privilege; (2) session-validation response distinguishes principal class (human / lucos_root / agent) via contact ID or principal-type claim, for per-backend differentiation + clean audit.

**Lifecycle:** the non-interactive acquisition key mints sessions → crown-jewel secret → lucos_creds, per-env, rotatable. Larger blast radius than a normal service key (reinforces least-privilege scoping).

**How to apply:** when #132 is designed/implemented, hold the line that the machine path yields a *session*, not a bearer scheme, and that authZ stays separate from authN. This is what makes lucos_root#135 cheap (no backend touches its auth). See also [[reference_service_worker_ui_as_system_component]] for the dashboard-compositor shape.
