---
name: feedback-consolidation-rule-scope
description: The flat-or-shrink consolidation guidance targets duplicate/diluting rules — it does not require a wrong rule to stay short; replacing a misleading rule with a correct distinction may legitimately grow, and disposition guidance earns its place beside mechanical rules
metadata:
  type: feedback
---

**The "prefer consolidation over additive growth / aim for the section to stay flat or shrink" guidance in CLAUDE.md is aimed at N near-identical rules diluting each other. It does not mean a *wrong* rule must stay short.** When you replace an actively-misleading instruction with a correct distinction, growth is legitimate — don't trim past the point where the distinction survives.

**Why:** 2026-07-31. I corrected the `sre-ops-checks.md` root-cause rule, which had told me the alert `debug` string counted as verification — the exact artifact that was lying in lucos_locations#105. The fix had to split `debug` content by provenance (verbatim upstream text = evidence; a value our code computed = a claim), which is irreducibly two cases where there was one. Preamble went 532 → 643 words. I flagged the miss to team-lead and offered to cut. Their answer: **keep it as is.** "+110 words to stop the file pointing at the liar is a good trade… it exists to stop N near-identical rules diluting each other, not to force a wrong rule to stay short."

**Also validated — keep disposition guidance, not just mechanical rules.** I offered to cut the two "amplifiers" (repetition is not corroboration; exonerating conclusions need the most scrutiny) as the padding. Team-lead refused specifically because they are the half explaining *why the existing rule failed*: I hadn't ignored the rule, I'd followed it. "An agent who reads only the provenance rule still has the disposition that produced the failure." Mechanical fix + disposition fix are both load-bearing.

**How to apply:**

- Before invoking flat-or-shrink to trim your own instruction fix, ask which case you're in: **duplicating** an existing rule (trim hard, edit in place) or **correcting** one that was wrong (grow if the correction needs it).
- **Report the miss rather than padding the diff stats.** Explicitly praised. Say "I went +110 and here's why", and offer the specific candidate you'd cut — don't silently hit the number by gutting the substance.
- If that block ever does need trimming, team-lead named the cut order: **the concrete worked example first** (longest, most service-specific), *not* the amplifiers. But keep the scar tissue while you can — "a rule with the scar tissue attached survives better than an abstract one."
- Pair every feedback memory with the instruction edit. I saved the memory, made an unrelated instruction edit in the same pass, and let that scratch the itch — team-lead had to ask. Making *an* edit is not making *the* edit.

Related: [[feedback_verify_check_claim_against_underlying_store]], [[pattern_locations_silent_data_gap]].
