---
name: feedback-convention-scope-failure-mode
description: When speccing a detector convention for a specific failure mode, don't bundle hygiene rules that don't relate to that failure mode
metadata:
  type: feedback
---

Convention scope should match the failure mode the convention exists to catch.

The `env_var_passthrough` convention (lucos_repos#387) was created to catch one specific failure mode: a process reads `os.environ["X"]` and gets an empty string because X wasn't declared in compose. My original spec also excluded hardcoded `KEY=value` entries from the "declared" set on hygiene grounds — discouraging hardcoding instead of routing through lucos_creds. lucas42 corrected this during the migration walk: hardcoded values can't have the empty-string failure mode, so they shouldn't count as drift findings. 9 of 19 dry-run failures were Case 2 (hardcoded `KEY=value`) and dropped after the amendment.

**Why:** bundling hygiene into a failure-mode-targeted convention creates false positives and dilutes the original intent. The bundled rule punishes services for an unrelated concern, eroding trust in the detector's signal. If hardcoding-instead-of-creds is genuinely worth enforcing, it deserves to stand on its own merits as a separate convention — not ride in on the back of a different one.

**How to apply:** when speccing any detector / convention / audit rule:

1. State the specific failure mode it catches in one sentence.
2. For each rule, check: does this rule fire iff the failure mode is present? If a rule fires when the failure mode is absent, it's scope creep — pull it out and either drop it or make it a separate convention.
3. Cross-check against the audit-finding-handling principle: every finding should map to a clear remediation that prevents the named failure. If the remediation is "be tidier" rather than "prevent X from happening", it's hygiene, not safety.

Related: [[feedback_apply_frame_review_to_own_reasoning]] — when contradicting evidence (here: dry-run results showing 9 false positives in 19) shows up, re-trace the original reasoning rather than defend the spec.
