---
name: correlation-is-not-confirmed
description: Don't label a correlation as "confirmed evidence" of a root cause without server-side data that distinguishes between competing hypotheses
metadata:
  type: feedback
---

**Rule:** When reporting an investigation, do not describe a correlation as "confirmed evidence" of a particular root cause unless I have data that actually distinguishes that cause from other plausible candidates. "X is the most-named entity in the failure list" is a weak claim; "X's own logs show it was the bottleneck" is a strong claim. Don't use the strong-claim language to describe the weak-claim evidence.

**Why:** lucas42 pulled me up on this on 2026-05-20. I had described `lucos_media_weightings` as "the receiver I have confirmed evidence on" because it appeared in 9 of 13 failed webhook deliveries from loganne in the 17:19:23–17:21:00Z 2026-05-19 incident. What I actually had:

- Loganne-side failure counts pointing at media-weighting 9 times
- Media-weighting's own access log showing **no app-level errors**, plus 3 successful POSTs *during* the failure window and a flood of successful POSTs immediately after
- Access log format with **no response status codes, no response times** — so no way to see whether media-weighting was responding slowly, refusing connections at TCP, or genuinely healthy throughout

That set is *consistent with* media-weighting being the bottleneck. It is *also consistent with* loganne-side socket exhaustion, an nginx-ingress blip, a docker bridge glitch, or a TLS handshake stall. The data doesn't distinguish between them.

Labelling that "confirmed" overclaims, biases the proposed fix (you suggest queueing on media-weighting when the actual cause might be elsewhere), and wastes the team's attention. lucas42 specifically asked me to walk this back before filing a remediation ticket — and was right to.

**How to apply:**

- Before writing "confirmed", "established", "verified", "definitely", or similar in a finding summary, ask: *would a different root cause produce the same observation?* If yes, downgrade the language. Say "correlated with", "most-named in", "consistent with X but also Y and Z".
- For incidents where the data is correlational, the right next-action is often "add the diagnostic instrumentation that would distinguish" rather than "ship the fix the correlation suggests". Yesterday this turned into `lucas42/lucos_media_weightings#230` (response-time + status-code logging) before any queueing change.
- Distinct from [[no-attribution-overclaim]] (which is about putting my framing on top of others' narrower observations). This rule is about labelling my *own* circumstantial evidence as decisive.
- Related to [[diagnose-through-to-root-cause]]: that rule says don't stop early on root-cause investigation when the next step is more diagnostics I can do. This rule is the inverse — don't *claim* root cause when I haven't actually closed it out. Both rules together: keep digging when I can, but be honest about whether I've reached bottom or not.
