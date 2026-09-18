---
name: feedback-cross-reference-coupled-tickets
description: When two tickets turn out to be coupled, post the cross-reference on both tickets immediately — not just in memory
metadata:
  type: feedback
---

When I notice two open tickets are substantively coupled (same underlying resource, same design surface, one is the remediation path for the other), post the cross-reference as a comment on both tickets right away — don't just note the link in my own memory and move on.

**Why:** I cross-linked lucas42/lucos_creds#565 (no `data_key` rotation tooling) and lucas42/lucos_backups#418 (world-readable backups exposing `data_key`) in my memory the same morning both were live, before anyone asked. team-lead independently reconstructed the same connection later that day, checked whether it had been recorded, and found it only existed in my memory — not on either ticket. The instinct to notice the coupling was right; the gap was that memory is session context I carry forward, while the tickets are what the next reader (a teammate, lucas42, a future session of mine that hasn't loaded this memory file) actually reads. A link that only exists in one agent's memory might as well not exist for anyone else, and even for me it's easy to let it go stale.

**How to apply:** the moment I recognize "these two are the same underlying problem" or "fixing A changes what B has to assume," post a short cross-reference comment on both tickets before doing anything else with the finding — same turn if possible, definitely before ending the session. The memory note can (and should) still exist for my own continuity, but it should point at the tickets as the source of truth, not substitute for posting there.
