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

**Sharpening — a success signal is NOT verification of a conclusion.** When an agent says something is "verified" by citing a *success signal* — an exit-0, a passing check, a `found=true`, a non-erroring command — that does not establish the downstream claim. The signal may be **unconditional**: it can succeed for every input, in which case it proves nothing. Before relaying such a claim as fact (or amplifying it), read the handler / mechanism to see what success actually means. Treat "verified via [the command worked]" as not-yet-verified until I've checked the success is *conditional on the thing being claimed*.

**Concrete example (2026-06-07):** both lucos-security and lucos-architect concluded a `lucos_contacts/test` environment "already exists" because an scp of `tests@…:lucos_contacts/test/.env` exited 0 (CircleCI build 4563), and I relayed it to lucas42 as "verified — you already have a test environment." But lucos_creds' `readFileByHandle` (`server/src/controller.go`) hardcodes `found = true` for *any* valid `system/environment/.env` (no not-found path) and auto-injects standard vars (SYSTEM/ENVIRONMENT) for any combo — so the scp exits 0 for *every* environment name. The success signal was unconditional; it proved nothing. lucas42 corrected the same misread twice in one exchange (first the security audit, then the architect's "corroboration") because I kept propagating the agents' "verified" without checking the mechanism. Should have read the handler before relaying.
