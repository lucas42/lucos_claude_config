---
name: feedback-verify-root-cause-by-reproduction
description: An incident root cause is not established until reproduced or shown by direct evidence the failing request took that path — a plausible recent-change mechanism is a lead, not a cause
metadata:
  type: feedback
---

**A root cause is UNVERIFIED until you've either reproduced the failure through the hypothesised path, or have direct evidence (a log/stack frame from the *actual* failing request) that it took that path. A plausible, well-reasoned mechanism — especially one built on "a recent change touched this area" — is a lead to test, not a cause to publish.**

**Why:** 2026-05-29 lucos_media_metadata_api save-502 (track 22829). I published a composer/producer-eolas-resolution root cause across **three** report PRs (lucos#202/#203/#204), built entirely from "the #274 migration added a synchronous eolas call to that save path." It was never reproduced. The real cause was unrelated and latent: an **Album selected in the unscoped `about` field** → API origin-validation 400 → API logs nothing → manager renders a hardcoded 502. lucas42 had to tell me what actually happened; a 15-minute controlled repro (which I'd *declined earlier as unnecessary*) then nailed it.

**Red flags I rationalised past (any one = stop and treat cause as UNCONFIRMED):**
- The blamed thing **wasn't on the affected record** — track 22829 had no composer/producer tag at all. (A tag the item doesn't have can't be what failed.)
- The diagnosis **hinged on an unconfirmed assumption about what the user was doing** ("he must have set a composer/producer") — never confirmed. He'd set `about`.
- **Timing didn't fit** — fast 502 vs a hypothesised slow synchronous call — and I explained the mismatch away instead of treating it as disproof.
- **A controlled repro was available and I declined it** ("fix helps regardless / mutating test data is heavier than reasoning") — declining the one step that would confirm, then shipping the unconfirmed cause anyway, is the trap.
- Cause inferred **chiefly from recency** of a related change.

**How to apply:** before writing a mechanism as *the* cause: reproduce it (coordinate with team-lead on production-touching repro — it's the right tool, not an over-step; throwaway record, delete after), or cite direct evidence the failing request hit that path. If you can't verify before the report must ship, label the mechanism a **leading hypothesis (not confirmed)**, state what verification is outstanding, and keep Resolution UNRESOLVED. "Symptom fingerprint" counts as evidence when a symptom is *uniquely* produced by one code path (here: a 502 page whose body says "status code 400" is uniquely `displayError(502, …getMessage())` with getMessage()="…400"). Codified in `references/incident-reporting.md` § "Verify the root cause actually caused *this* failure". See also [[feedback_correlation_is_not_confirmed]] (correlation ≠ confirmed) — this is its incident-report sibling.
