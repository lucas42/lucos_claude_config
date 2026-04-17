---
name: Ask about tag/version churn rate before recommending snapshot-based mirrors
description: Before recommending a curated-store architecture (GHCR mirror, pinned registry, snapshot cache), ask about the tag-update cadence — Dependabot makes snapshot approaches break
type: feedback
---

Before recommending a mirror/snapshot/curated-store architecture (GHCR mirror, pinned internal registry, any "we pre-fetch the set of images we use" design), always ask about the tag-change cadence in the estate.

**Why:** In 2026-04-17 analysis of lucos_deploy_orb#106, I recommended a GHCR-based approach (either ARG rollout or orb `--build-context`) and explicitly treated the GHCR mirror's ongoing ops cost as near-zero. That was only true in a quiescent estate. The lucos estate has active Dependabot bumping base image tags regularly, which turns a curated mirror into a "chase Dependabot forever" maintenance burden — every bump to a new tag that isn't in the mirror is a 404 and a broken build. A pull-through cache (transparent proxy, fetch on demand, cache after first request) doesn't have this problem.

**How to apply:** When assessing any architecture that involves pre-populating a store with a specific set of artifact versions, explicitly ask:
- What rate of new versions/tags/artifacts will this store need to track?
- Is there an automated upgrade mechanism (Dependabot, Renovate, scheduled rebuilds) that will continuously propose new versions?
- If yes, does the architecture handle on-demand fetching for unseen versions, or does it require maintenance work per new version?

If the answer is "continuous churn + requires maintenance per version", prefer a proxy/transparent-cache architecture over a curated snapshot. The ongoing cost of a running service is usually less than the ongoing cost of keeping a curated list in sync with a moving target.

More broadly: when comparing options, frame trade-offs as "ops cost *in the real dynamic environment*", not "static setup cost in a steady state". An estate with automated dependency tools is dynamic by design.
