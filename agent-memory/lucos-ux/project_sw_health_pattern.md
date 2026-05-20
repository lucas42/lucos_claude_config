---
name: project_sw_health_pattern
description: SW-backed UIs (seinn) can degrade silently — estate UX pattern for surfacing SW health to users
metadata:
  type: project
---

Service-worker-backed pages in the lucos estate can degrade for reasons the page itself cannot directly observe (cache thrash, quota eviction, quota reduction). The seinn cache-thrash incident (2026-05-19/20) is the first concrete example: music silently stopped playing for 15–30 minutes with no on-screen indication.

**Why:** SW degradation bypasses normal page error handling. The audio element fails, seinn reports the track as errored, media-manager skips to the next track — and this cycle repeats silently. The user has no idea anything is wrong until they notice the music stopped.

**How to apply:** When implementing or reviewing SW-backed UI work:
- Any degraded-SW condition visible from the page should surface a visible, accessible indicator — not just log to console.
- Prefer guided recovery (show banner + "Reload" button, user triggers reload) over silent auto-recovery (user still doesn't know what happened) or silent failure.
- `role="alert"` or ARIA live region is required so screen readers announce degradation without the user having to discover the banner.
- Recovery actions (Reload, Dismiss) must be keyboard-reachable.

The `deviceSwitch` affordance in media-manager was the actual workaround for both seinn incidents — players that lack a comparable escape hatch would have left the user with no exit. Worth noting in UX reviews of media-player components.

The broader "ambient SW health" pattern (a reusable way for any SW-backed page to surface degradation) is not yet a filed issue — not enough instances to justify abstracting. Revisit if it appears in more than one SW-backed page.

Related follow-up: `lucas42/lucos_media_seinn#457` (detect cache-thrash and surface to user — UX work, assigned to lucos-ux).
