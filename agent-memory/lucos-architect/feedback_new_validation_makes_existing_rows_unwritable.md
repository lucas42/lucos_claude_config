---
name: new-validation-makes-existing-rows-unwritable
description: A new write-time precondition applies to UPDATES of existing rows, not just creation — check whether it makes pre-existing non-conforming records unmodifiable, especially where the update is an incident-response action
metadata:
  type: feedback
---

When designing a **new validation rule on a write path**, do not reason about it only as "this blocks bad *new* records". Ask: **what pre-existing records now fail it, and what operation on them does this forbid?**

**Why:** creds ADR-0005 (2026-07-19) added "refuse a linked credential whose server system has no origin". I framed and defended it as a guard on creation. Tracing the code showed `updateLinkedCredential` is the single entry point for create, rotate *and* re-scope (`REPLACE INTO`, one call site), and ADR-0003 makes a scope change a re-issuance — so the rule would have made any pre-existing non-conforming link **unrotatable**. Key rotation is an incident-response action, so the failure would arrive mid-incident. Neither I nor the code reviewer caught it on the first pass; it surfaced only when lucos-security pushed on an adjacent verification gap I had labelled and moved past.

**How to apply:**
1. **Find the write path's call sites.** If create and update share one function (common with `REPLACE INTO`/upsert), the new check fires on both. One `grep` for call sites settles it.
2. **Ask what the update operation *means* operationally.** "Rotate a credential", "re-scope a grant", "re-run a migration" are not routine edits — they are often what someone does under pressure. A validation that blocks them fails at the worst time.
3. **Then choose deliberately between:**
   - **Audit-first** — verify the non-conforming set is empty (or fix it), then enable unconditionally. Keeps the rule simple. Preferred when the set is likely empty.
   - **Grandfather** — apply only to genuinely new records, exempting re-writes of existing ones. Avoids the hazard, at the cost of a permanently more complex rule and records that silently never conform.
4. **If the audit can't be run with your access, the audit is a *prerequisite*, not a follow-up.** Say so, and name who can run it. Don't let "we'll confirm later" carry a rule whose failure mode is an outage.

**Watch the tempting-but-weak argument:** "development evidence suggests the set is empty, so we can skip the production safeguard." That is using the visible half to justify not checking the half you can't see — the exact reasoning most of these designs exist to discourage. It may still be the right call, but flag it as the trade-off it is rather than as a finding.

Related: [[creds-origin-envvars]], [[feedback_flag_day_verification_gate]], [[feedback_detector_inverse_failure_mode]]
