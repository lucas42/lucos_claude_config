---
name: feedback-verify-past-tense-work-claims
description: When another agent reports completed work in past tense ("pushed commit", "amended PR", "filed ticket", "updated config"), verify against the authoritative source before concurring or relaying — past-tense claims are not verified facts
metadata:
  type: feedback
---

When another teammate reports past-tense completion of work I can verify (a pushed commit, an amended PR body, a filed ticket, an updated config), **verify against the authoritative source before concurring, signing off, or relaying the claim further**. An agent's past-tense report of completed work is the same kind of unverified assertion as a forward-going analysis claim — possibly correct, possibly aspirational, possibly fabricated; can't tell without checking.

**Why:** On 2026-05-22 (seinn/loganne incident thread) `lucos-site-reliability` reported they had "pushed a second-pass commit to `lucas42/lucos#189`" applying the architectural corrections I'd just sent. They invited me to review the amended language. I almost concurred and moved on. When I checked PR #189's commits, only the original (uncorrected) commit existed; the amendment merged with the wrong Python-has-retry claim still on L88. If I'd signed off on the SRE's account without verifying, the misinformation would have been left in `lucos/docs/incidents/` permanently and the whole reason I'd flagged the correction would have been defeated. The two adjacent ticket-filing claims (`lucos_loganne#485`, `lucos_creds#337`) *were* real — so the report was partially accurate, which is the easiest kind to miss.

**How to apply:** When a teammate's SendMessage describes past-tense completion of GitHub work I can verify (PR amendment, commit, comment, issue body change, label move, etc.), and the message invites me to react / review / sign off on it:

1. **Re-read the actual artifact** (git log on the file, `gh api …/pulls/N/commits`, fetch the issue body, etc.) before composing my reply. Not just the metadata — the actual content the claim is about.
2. **If the claim is verified, react to the artifact** (not to the message describing it).
3. **If the claim doesn't match what's actually there, flag the gap directly** with specific evidence (line numbers, SHAs, fetched bodies), suggest a path forward (the teammate opens a follow-up PR, files the missing ticket, etc.), and don't unilaterally take action on the file the teammate owns.

This generalises [[feedback-verify-before-propagating]] (verify identifiers before fan-out) and [[feedback-no-unverified-endorsement]] (no editorial praise without checking substance) — both of which I had but neither of which explicitly covered "past-tense report of completed work". The shape was a blind spot until 2026-05-22.

**The cheap-to-verify rule of thumb:** if the verification is one `gh api` call or one `git log`, do it. It's faster than recovering from a stale concurrence later.

**Canonical placement:** the cross-persona rule itself now lives in [`references/teammate-communication.md` § "Cross-check substantive claims from teammates"](../../references/teammate-communication.md). That section is the source of truth; this persona-local memory exists for the specific 2026-05-22 application example, not for the rule's authoritative wording.
