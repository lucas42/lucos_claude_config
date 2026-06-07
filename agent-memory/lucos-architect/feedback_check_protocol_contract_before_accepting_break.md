---
name: check-protocol-contract-before-accepting-break
description: Shared-lib breaking-change incidents — don't assume a break is gratuitous; the real systemic fix is consumer tests exercising the REAL library interface, not version caps
metadata:
  type: feedback
---

When a shared client library ships a breaking change that causes an estate outage, do **not** jump to "migrate all consumers" or "make the client backward-compatible again." Diagnose the actual systemic gap first — and check the decision-maker's intent before calling a break "gratuitous."

**Why (2026-06-06 loganne incident, with lucas42's correction):** `lucos_loganne_pythonclient` v2.0.0 made `level` a mandatory positional arg and crashed the arachne prod ingestor (lucas42/lucos_arachne#608, fixed by #609) + reddened photos CI. My first read was "gratuitous break — the server (lucas42/lucos_loganne ADR-0001) makes `level` optional, so revert the client (filed #48) and add version caps (lucos_repos#409, lucos#219)." **lucas42 corrected all of that:**
- Making `level` mandatory in the client *major* is **deliberate and legitimate** — using the library's SemVer major as the breaking-change channel while the server stays permissive is a clean split ("v1 needs no level, v2 does"); versioning the server would've been real work for little gain. → #48 closed.
- **Caps are the wrong tool:** not every major is breaking for a given consumer, so a cap forces pointless hand-bumps. → #409 closed.
- **The real failure is a testing gap:** consumers mock the library, so signature drift is invisible, CI stays green, dependabot merges, prod breaks.

**How to apply (the durable lesson):**
- Before framing a break as a mistake, ask the owner about intent — a strict-client/permissive-server split is a valid design choice, not a bug.
- The systemic fix for "dependency bump broke prod but CI was green" is **consumer tests that exercise the real shared-lib interface**, ranked: (1) **real library against a stubbed HTTP transport** (`requests-mock`/`responses`) — catches arity *and* value breaks; (2) a **library-provided spec'd fixture/fake** that runs the real validation — most robust and the only realistically auditable option (lucos_repos can check consumers import it); (3) **autospec mocks** as a floor — catches missing-required-arg but NOT value breaks (e.g. a positional call binding `url` into a `level` slot passes autospec but fails the real `VALID_LEVELS` check).
- Residual gap caps and tests both miss: a consumer with **no** emit-path test at all (e.g. a cron script). The fix there is to *add* a real-interface test, not just de-mock an existing one.
- **Common MISimplementation to watch for:** "ADR-0011 test" does NOT mean "run the consumer's whole script against the real services." ADR-0011 (lucos) mandates the *real client* against a *stubbed* transport — no real network call. A consumer that points its test at real (or test-instance) endpoints has drifted from the ADR and needlessly drags in side effects + infra. **dns config-sync did exactly this** (lucos_dns#99 wired it against real endpoints; #100 flagged it wrote to prod observability). Reconciled 2026-06-07: rebuild as real-client/stubbed-transport → no real calls, **no `lucos_dns/test` creds env needed at all**, and the ADR-0002 "dependency needs its own test env" cascade does NOT trigger. The phrase "real-transport test" is a misnomer — the transport is stubbed, the *library* is real.
- Estate fact: this same mock-hides-drift risk applies to every internally-versioned shared client (schedule_tracker, media_api, contacts, etc.), not just loganne. See also [[feedback_breaking_change_when_callers_must_change_anyway]], [[feedback_check_originating_decision_before_forking]], [[reference_creds_test_environments]].
