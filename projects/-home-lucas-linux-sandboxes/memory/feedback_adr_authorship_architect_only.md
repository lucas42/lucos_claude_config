---
name: feedback_adr_authorship_architect_only
description: "When a decision needs both an ADR and an implementation PR, scope ADR-authorship explicitly to the architect so the implementer doesn't also write one"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bbf332f2-a3a1-44cf-9478-3ce93c92883c
---

When dispatching implementation of a decided design AND commissioning the ADR that records it, make ADR authorship **explicitly architect-only**. Do NOT embed "capture in the ADR" / "record in the ADR" scope language in the *implementation* ticket in a way the implementer reads as "write the ADR" — that spawns a duplicate ADR file (divergent content) and a merge collision.

**Why:** 2026-07-08, lucos_worlds — #26 (implementation, sysadmin) and #27 (ADR, architect, dispatched separately + lucas42-approved) both added `docs/adr/0002-*.md`. The code-reviewer caught the collision; resolved by #27 carrying the ADR and #28 dropping its ADR file to stay pure-implementation.

**How to apply:** in the implementation ticket, reference the ADR as "recorded separately by the architect (see #NN)" rather than instructing the implementer to write/capture it. Commission the ADR to the architect in its own message. One decision → one ADR author (architect). Relates to [[feedback_dispatch_url_only]].
