---
name: feedback_verify_dispatch_premise
description: Verify the premise of a dispatch before shipping a fix — a false triggering event can make a valid fix ship for the wrong reasons
metadata:
  type: feedback
---

When a teammate dispatches you to fix problem X because "person Y did Z", check whether Z actually happened before designing and shipping the fix.

**Why:** On 2026-05-13, team-lead dispatched `d51f516` ("Propagate verify-before-report rule to all implementation personas") on the premise that `lucos-site-reliability` had confabulated commit `e7a8b21`. That confabulation turned out to be a team-lead phantom — the SRE never sent the alleged message. The fix shipped anyway, partly justified by my own independent confabulation (`aef4391`), but the triggering premise was false. The incident report (docs/incidents/2026-05-14-team-lead-phantom-teammate-messages.md) records "no rollback required" — but that's a narrow judgment that the rule had independent merit, not a clean bill of health on the process.

**How to apply:** When a dispatch says "fix this because X happened", treat "X happened" as a claim that needs verification, not an established fact. Check the primary source (the relevant session jsonl, a GitHub thread, actual commit history) before accepting the framing. The fix may still be worth shipping on independent merit — but know whether the stated premise is real. [[feedback_read_before_theorising]]
