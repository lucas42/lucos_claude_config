---
name: feedback_check_no_open_questions_claim
description: don't label a fix "no open questions"/"straightforward bugfix" without checking whether it's actually a behaviour change in disguise, or a privilege gap unresolvable without checking already-readable alternatives first
metadata:
  type: feedback
---

Two related corrections from the same session (`lucos_agent_coding_sandbox#98`/`#99`, 2026-07-14), both caught by team-lead or by re-checking my own work before filing:

1. **"Restore X" implies X once held — verify that before calling the fix a no-decision bugfix.** I called "restore the security-only unattended-upgrades restriction" a straightforward bugfix with no open questions, and lucos-security converged on the same framing independently. Team-lead caught it: by my own concatenation finding, the restriction had *never* taken effect since deployment, so "restoring" it is enacting a behaviour for the first time — a live change to production that would increase manual patching burden, cutting against the ticket's own purpose. Two agents independently re-verifying the same underlying *mechanism* fact doesn't catch a shared blind spot in how the *fix* is characterised — solid evidence for a claim doesn't automatically mean the claim's stakes were assessed correctly.

2. **Before concluding a verification gap needs a new privilege grant, check for an already-readable alternate source.** I was about to file an issue proposing `adm`/`systemd-journal` group access to check whether `unattended-upgrades` was succeeding, on the assumption that `journalctl` (blocked) was the only path. `/var/log/apt/history.log` was world-readable the whole time and answered the question directly. Don't stop at "the obvious tool is gated" — check whether the underlying question has a different, already-accessible evidence source before recommending any privilege expansion.

**Why:** both are instances of the same failure — treating a confirmed *fact* as if it settles the *framing* or *scope* around it, without a second pass asking "does this fact actually mean what I think it means for what happens next."

**How to apply:** before writing "no open questions," "straightforward," or "needs a new grant" in an issue, ask explicitly: (a) does the fix change current behaviour, or restore behaviour that was actually in effect? (b) is there a cheaper/already-available way to answer the motivating question before proposing new access? Do this even when a peer (human or agent) has independently verified the same underlying fact — their verification covers the fact, not necessarily your characterisation of it.
