---
name: review-detection-code-coverage
description: When reviewing detection/monitoring code, check whether counters cover both success AND failure paths — not just the happy path
metadata:
  type: feedback
---

When reviewing detection or monitoring code (banners, alert counters, health checks), always ask: **does this metric fire on both success and failure paths?**

**Why:** The seinn cache-eviction TypeError burst (2026-05-22 incident) exposed a gap in the banner detector from lucos_media_seinn PR #460. The detector counted only *successful* evictions; a `.catch(err => console.error(...))` silently swallowed failures without incrementing the counter. Result: the inverse failure mode (evictions failing, not succeeding too aggressively) was completely invisible to the detector.

**How to apply:**
- When you see a `.catch()` that only logs (no counter increment, no state update), flag it as a potential coverage gap.
- For any counter that gates an alert or banner, read where the counter is incremented. If it's only inside the success path, ask whether the failure path needs its own counter.
- The question to ask explicitly during review: "Is this metric covering both success and failure paths?"

**Related:** [[review_js_async_mutex]] — same seinn service; recurring asymmetry pattern.
