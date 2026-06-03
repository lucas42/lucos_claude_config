---
name: robustness-gaps-block
description: Exception-path resource leaks and correctness-hardening gaps must block the PR, not become approval notes — "unlikely in practice" is not a valid downgrade qualifier
metadata:
  type: feedback
---

Concrete robustness / correctness-hardening gaps must be REQUEST_CHANGES, even when the triggering scenario is unlikely in practice.

**Why:** Approved lucos_backups #292 with a non-blocking note that `closeConnection()` would skip `gateway.close()` if `connection.close()` raised. The fix was one line (`try/finally`). It became follow-up PR #293 — more overhead than just blocking #292 in the first place. Lucas42: "I would've preferred they consider robustness comments like these as blocking for their reviews, rather than needing to deal with follow-up issues later."

**How to apply:** When a gap is concrete (specific, named) and fixable without outside input (one-liner, no design discussion needed), request changes regardless of how improbable the failure scenario is. Probability is irrelevant to the block/note decision. Exception-path resource leaks, partial cleanup on error, and missing guards all qualify. Reserve approvals-with-notes for genuinely subjective style calls or things that require architectural input.
