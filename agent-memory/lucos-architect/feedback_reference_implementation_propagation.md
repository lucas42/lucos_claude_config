---
name: A "reference implementation" defect propagates with confidence amplification
description: When an issue body or design says "follow X as a reference implementation", a copy-and-tweak approach treats X as already-reviewed. If X has a defect, every subsequent copy compounds the confidence rather than catching the bug.
type: feedback
---

A defect in a reference implementation is the worst kind of defect, because each subsequent copy is a confidence-multiplier rather than a fresh review. The implementer of copy #2 trusts that the reviewer of copy #1 already validated the design; the implementer of copy #3 trusts both. By the time the bug surfaces, three production services share it.

**Why:** Estate-confirmed in 2026-04-29: `lucos_eolas#213` named `lucos_contacts#669` as its reference implementation, both shipped with identical `settings_collectstatic.py` defects (omitted `django.contrib.admin` from `INSTALLED_APPS`), both broke the same way ~6.5 hours after a routine volume cleanup. The defect propagated unchallenged because "the contacts version works in production" was treated as proof of correctness.

**How to apply:**

1. When triaging an issue that says "see X as a reference implementation" or "copy the approach from Y":
   - Push back if the reference is not yet reviewed by an architect.
   - Ask whether the reference has been verified to be correct rather than just "currently in production."
   - Flag in triage that the implementer should not just copy but should review the reference and call out any concerns.
2. When reviewing PRs that follow this pattern:
   - The fact that "this matches the existing X" is **not** sufficient justification on its own.
   - Specifically check whether the parts being copied have any silent-failure modes (e.g. a static-asset pipeline that succeeds with empty output, a config schema that ignores unknown keys).
3. When writing an issue body that points at a reference implementation:
   - Don't write "copy from X" — write "verify X is correct, then apply the same pattern."
   - If X has been audited, say so explicitly, naming the audit.
4. Architectural takeaway worth raising estate-wide: any time a pattern is going to be replicated to ≥2 services, the first instance deserves architectural sign-off, not just code review. Code review optimises for "does this PR do what it says"; architectural review optimises for "is what it says the right thing to do."

This is not unique to lucos but it bites hard in a small estate where the same pair of services (eolas, contacts) keep appearing together as reference-and-copy.
