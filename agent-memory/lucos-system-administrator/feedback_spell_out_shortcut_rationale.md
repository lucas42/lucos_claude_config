---
name: feedback_spell_out_shortcut_rationale
description: When a ticket proposes matching an existing code shortcut/precedent, state the categorical reason it fits — don't just say "least invasive" and match the shape
metadata:
  type: feedback
---

lucos_router#104 (2026-08-09): proposed hardcoding 5 personal-redirect domains in `fetch-domainsets.sh`, following the existing `tfluke.uk`/`nas.l42.eu` precedent, phrased in the ticket body as "the one real implementation-shape decision... pick whatever's least invasive." lucas42 read that as possibly ungrounded ("or are we just vibing it big time?") and the ticket got pulled from Ready back to Needs Analysis, re-owned to `lucos-architect`, even though the underlying technical judgement turned out to be right.

**What would have prevented the re-routing**: stating explicitly in the original body *why* the precedent applies — that `lucos_configy/systems.yaml` only models real lucos-owned deployed systems (`domain`+`http_port`+`hosts`, i.e. a container answering on a port), and these redirect-only domains categorically don't fit that shape (no container, no port, nothing to register) — rather than just noting "there's a precedent, do the same thing." A precedent cited without the reason it applies reads as pattern-matching, not as an argument. Checking git blame on the precedent-setting commit (it turned out to be lucas42's own commit, `2a53ca8`) would have made the citation load-bearing instead of just decorative.

**How to apply**: whenever a ticket proposes reusing an existing shortcut/special-case rather than the "proper" data-modeled path, spell out the categorical reason the shortcut applies (what structural property the new case shares with the precedent, and what property is genuinely missing that would let it use the normal path) — not just "there's prior art, matching it." Cheap to add, and it's the difference between an implementer's judgement call and something that reads as skipped triage. See [[lucos-router-mechanism]] for the underlying facts about `lucos_router`/`lucos_configy`'s domain model.
