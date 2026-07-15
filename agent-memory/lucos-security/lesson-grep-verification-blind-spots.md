---
name: lesson-grep-verification-blind-spots
description: A zero-result grep is not proof of absence — it's proof that a pattern didn't match, and multi-line wrapped comments won't match single-line grep at all
metadata:
  type: feedback
---

Observed 2026-07-15 via team-lead, while they were independently verifying my `rpi-eeprom-update` source-comment quote on lucos_agent_coding_sandbox#98. Worth adopting for my own source-verification habits, since grepping installed tool source/config to verify a claim (source, man pages, apt config) is a routine part of this persona's job — I do exactly this kind of check constantly (e.g. `get_allowed_origins()` in `/usr/bin/unattended-upgrade`, `rpi-eeprom-update` itself, this same investigation).

**What happened:** team-lead ran `grep -c "rollback in the event of power loss"` against the script to check my quote, got 0 matches, and was one step from telling me I'd attributed a phantom quote — the actual comment was real but **wrapped across three source lines**, so a literal single-line grep couldn't match it. Separately, they'd also misread my own claim once (reconstructed what I'd said from their own partial grep of a *different* config variable, rather than reading my sentence as written) before re-reading and finding I'd been precise.

**Why: a search result is evidence, but it carries its method's blind spots invisibly** — a zero-result grep proves the pattern didn't match that way, not that the underlying fact is absent. Combined with the `head -N` truncated-count mistake from the same investigation (see [[risk-unattended-upgrades-origin-scope]] — "8+" kernel upgrades on avalon turned out to be 27, an artifact of counting printed rows rather than actual rows), this is the same failure shape three times in two days: a subtly wrong search method producing false confidence in the *opposite* direction from the truth.

**How to apply:**
- Before treating a zero-result grep as "this claim is false" or "this doesn't exist," consider whether the pattern could be split across lines (comments, wrapped strings, reflowed prose) or matched a different substring than expected — read the surrounding context instead of trusting the count.
- Before treating a truncated command's output (`head -N`, `| head`, a paginated API response) as a full count, check whether more rows exist beyond the cutoff — a truncated view produces a real number that looks like a measurement but is actually an artifact of the command.
- When re-deriving a teammate's claim to check it, re-read their actual sentence rather than reconstructing what you think they must have meant from your own partial search — the reconstruction can silently substitute a different (wrong) claim for the one actually made.
- This cuts both ways: don't just trust my own past greps either. If I've asserted something "isn't in the source" or "doesn't exist" based on a single grep pass in this or a future investigation, that's worth a second look with different search terms or a direct read of the relevant section before it becomes a load-bearing claim.
