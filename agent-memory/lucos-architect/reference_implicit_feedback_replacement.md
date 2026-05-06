---
name: Don't remove implicit feedback signals without explicit replacements
description: When reviewing a proposal to remove a behaviour, check whether the behaviour is load-bearing as user feedback even if unintended. If yes, removal needs an explicit replacement first.
type: reference
---

A specific, recurring shape of architectural review failure: a system has an **unintended side-effect** that is serving as user feedback. Someone proposes "fixing" the side-effect for technical correctness. The fix is technically correct *and* makes the user experience worse, because the side-effect was load-bearing for UX even though no one designed it that way.

**Concrete instance (lucos_media_manager#237, closed `not_planned` 2026-05-06):**
- Bug: `setFetcher()` synchronously empties the playlist queue, then a background thread refills it. The empty window was originally feared to cause silence + monitoring flap.
- Proposed fix: atomic swap or sync first fetch, so the queue is never empty during a collection change.
- What the lucos#126 measurement actually showed: **the abrupt audio cutoff during the empty window was the only sub-second feedback the user got that their button press had registered**. Total wait T1→T4 was ~7.4s; the queue-empty contribution was ~480ms of that. Removing the cutoff would leave the user with no sub-second feedback during a 7.4s wait — perceived as the system not responding.
- Outcome: #237 closed not_planned. lucas42/lucos#127 (auditory icons) is the explicit replacement that would let #237 be reconsidered.

**The general principle:** before recommending the removal of a behaviour, ask "is anything — including unintended downstream effects — currently relying on this?" If a side-effect is acting as user feedback, an automated process, an alerting trigger, or any other implicit signal, the change needs an **explicit replacement** before it can land safely.

This is Chesterton's Fence's specific UX-architecture variant. The original ("don't remove a fence until you understand why it's there") talks about intentional structures whose purpose has been forgotten. This variant is about **unintentional** behaviours that have nonetheless become load-bearing — neither the original implementer nor the proposer realised the side-effect was carrying weight.

**How to apply:**
- When reviewing a proposal to remove or change a system behaviour (especially one framed as "fixing a bug" or "tidying up an artefact"): before approving, list what currently depends on the behaviour. Include implicit/accidental dependencies — UX feedback, monitoring signals, downstream consumers that grew up around the side-effect.
- If anything depends on it: either (a) keep the behaviour, (b) require an explicit replacement to land first or alongside, or (c) explicitly accept the regression and document why it's tolerable.
- The persona's "Self-Verification" question 2 ("considered failure modes, not just the happy path") catches *some* of this, but the framing here is sharper: failure modes are usually thought of as the new code breaking. The harder case is the new code *succeeding at its stated goal* and breaking something downstream that no one realised was there.
- Applies most often to: timing/feedback artefacts, error messages that became contractual, "harmless" side-effects in shared utilities, monitoring blips that operators learned to read as signals.

**A gentler test for triage:** if the original behaviour has been in production for a while and no one's complained, ask "what changed?" — if the answer is "we noticed it" rather than "it broke something for someone", proceed with extra care.
