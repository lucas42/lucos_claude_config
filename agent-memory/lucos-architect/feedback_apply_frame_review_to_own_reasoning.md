---
name: Apply frame-review to your own prior reasoning, not just to others' proposals
description: When a teammate supplies new facts that seem to support flipping a recommendation, re-test the new framing against your existing reading before pivoting — don't just absorb their summary uncritically
type: feedback
---

The "review the proposal's assumptions before reasoning within them" principle (encoded in the persona file 2026-05-05, commit 631c8a5) applies to **your own previous reasoning** when new facts arrive, not just to proposals coming from others.

**What happened (lucas42/lucos_media_seinn#425, 2026-05-05):** I correctly read seinn's architecture on first pass — "Node server isn't in the playback path" — and recommended Option C (`?action=started` POST to media_manager, mirroring existing client→manager event reporting). When SRE supplied an architecture summary mentioning Express + auth + mustache + a "long-poll endpoint", I read that as evidence the server *was* in the runtime path, flipped to Option B-revised (beacon to a new seinn `/_log` endpoint), and built a "free T3.5 capture" argument on top of the new framing. lucas42 corrected me: the seinn server's `/v3/poll` route is the **no-JS fallback**, not the runtime polling path; the JS client and service worker hit media_manager directly. My T3.5 argument was hollow because it depended on a runtime path that doesn't exist. Three rounds were needed to land where round one already was.

**Why:** the persona update tells me to challenge a teammate's framing before reasoning within it. I applied that to lucas42's "use Loganne" framing on lucas42/lucos#126. I did **not** apply it when SRE's clarification arrived — I treated their summary as validating the alternative I'd been about to dismiss, and let it overwrite my own prior reading without re-testing it. That's the same failure mode the persona update was supposed to catch, just pointed at *my own* prior conclusion instead of someone else's proposal.

**How to apply:**

- When a teammate supplies architecture facts that update your mental model, **re-read the relevant code yourself** before pivoting your recommendation. A teammate's summary is evidence, not a substitute for tracing the request path.
- A useful test: if the new framing makes a previously-rejected option suddenly preferable, and the new argument depends on a structural claim (e.g. "X is in the runtime path"), verify that structural claim end-to-end before building on it. Two specific traps for client/server architectures:
  - Existence of an Express app does not mean it sits in the runtime hot path. SSR / no-JS fallback routes are not the same as runtime proxy routes.
  - The presence of a route at `app.use('/v3', ...)` doesn't tell you whether the JS client *uses* it; check what the client's HTTP helper points at (e.g. `MEDIA_MANAGER_URL` env var on the manager.js helper).
- If you flip a recommendation, the new argument has to hold up under the same scrutiny you'd apply to a peer's proposal. "I'd already rejected this once and a teammate's summary made me reconsider" is a yellow flag — re-verify the structural claim before posting.
- Apply the persona's "Self-Verification" item 6 to your own pivots: *was the proposed approach reviewed, or only reasoned within?* This applies whether the "proposed approach" is yours or someone else's.
