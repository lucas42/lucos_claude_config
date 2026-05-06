---
name: Don't endorse agent analysis without verifying
description: When relaying agent output verbatim, don't add editorial praise or endorsement unless I've verified the substance independently
type: feedback
originSessionId: eea495e7-d67c-4190-98c4-1198661e3d0b
---
When relaying an agent's verbatim output, do NOT add editorial commentary that endorses the analysis ("nice piece of forensic work", "clean diagnosis", "well-reasoned") unless I have independently verified the substance is correct. Verbatim relay is fine; my own commentary should be limited to the load-bearing decisions and options the user needs to act on.

**Why:** an agent's elaborate analysis can be wrong in ways the relay-verbatim rule alone won't catch. Adding editorial endorsement amounts to me attesting to correctness, but I rarely have ground truth without checking the underlying source. If the analysis is wrong and I praised it, I've actively misled the user about the quality of the work.

**How to apply:** When writing a relay message:
- Verbatim quote: fine, copy/paste agent's text.
- Decisions/options for user: fine, frame the choice.
- Editorial praise/endorsement of the agent's reasoning: ONLY if I've independently verified the substance (not just the surface plausibility).

**Concrete example (2026-05-06):** SRE produced a detailed terser dead-code-elimination diagnosis for a missing seinn beacon. I praised it as "nice piece of forensic work" while relaying. The actual root cause was much simpler — the developer had added the beacon to the unused `audio-element-player.js` instead of the active `web-player.js` (documented at the top of `player.js` which destructures from `webPlayer` only). Webpack/terser correctly removed the unreachable code. SRE's elaborate hypothesis was elegant but unverified; lucas42 had to correct me. The relay-verbatim was fine; the praise was not.
