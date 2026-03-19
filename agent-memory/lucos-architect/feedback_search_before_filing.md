---
name: Search for existing issues before filing new ones
description: During incident follow-ups, search relevant repos for existing issues before filing — multiple agents may be working the same thread
type: feedback
---

Always search for existing issues on relevant repos before filing new ones, especially during incident follow-ups where multiple agents are active simultaneously.

**Why:** During the 2026-03-19 incident follow-up, I filed lucas42/lucos#55 (deploy PORT validation) on the wrong repo (lucos instead of lucos_deploy_orb), and two other agents had already filed the same issue on the correct repo. This created duplicate work and noise.

**How to apply:** Before filing any issue that stems from an incident or cross-cutting concern: (1) identify the correct repo for the change (e.g. deploy orb changes go on lucos_deploy_orb, not lucos), (2) search that repo for recently filed issues with similar titles or labels, (3) only file if no existing issue covers the concern. During incidents, assume other agents are also filing follow-ups.
