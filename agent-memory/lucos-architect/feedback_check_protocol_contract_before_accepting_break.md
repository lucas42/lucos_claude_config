---
name: check-protocol-contract-before-accepting-break
description: When a shared-lib breaking change causes an outage, check the underlying server/protocol contract before accepting the break was necessary — and remember internal shared-lib pins are estate-wide unbounded
metadata:
  type: feedback
---

When a shared client library ships a breaking change and it causes an estate outage, do **not** default to "migrate all consumers." First ask whether the break was *necessary* by reading the underlying server/protocol contract.

**Why:** 2026-06-06 loganne incident. `lucos_loganne_pythonclient` v2.0.0 made `level` a **mandatory positional** arg and crashed the arachne prod ingestor (lucas42/lucos_arachne#608) + broke photos CI. But the *server* (lucas42/lucos_loganne ADR-0001, Accepted) makes `level` **optional, default `routine`** — "No emitter changes are required for correctness." The client had made mandatory what the protocol deliberately left optional, reversing an accepted ADR with no ADR of its own. A one-line client fix (level optional + reorder after `url` + DeprecationWarning, filed as lucas42/lucos_loganne_pythonclient#48) un-breaks the whole estate with **zero** consumer changes — far better than a 6-repo migration scramble.

**How to apply:**
- A client wrapper making a param mandatory when the server treats it as optional-with-default is a *gratuitous* break — recommend aligning the client to the protocol, not migrating callers. Additive-then-deprecate (default + DeprecationWarning, tighten in a later major) preserves the "nudge emitters" intent without breaking anyone.
- Watch the positional-slot trap: inserting a new required positional ahead of an existing optional one (here `level` took `url`'s slot 3) silently corrupts positional callers. Reorder new optional params to the end.
- **Systemic pin finding:** *every* internal-shared-lib dependency in the estate uses an unbounded constraint (`*`, bare name, `>=X` no cap). The same landmine sits under all `lucos-schedule-tracker-pythonclient = ">=2.0.x"` consumers. Durable fix = major-cap convention + lucos_repos audit (lucas42/lucos#219 ADR-0011, lucas42/lucos_repos#409). See also [[feedback_breaking_change_when_callers_must_change_anyway]].
