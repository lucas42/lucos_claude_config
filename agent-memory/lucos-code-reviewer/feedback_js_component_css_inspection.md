---
name: feedback-js-component-css-inspection
description: When concluding a visual fix is missing in a shadow-DOM component, check JS event handlers — not just CSS. CSS-only inspection missed a JS-based column-overflow fix in lucos_search_component.
metadata:
  type: feedback
---

When reviewing a shadow DOM web component for a missing visual behaviour (e.g. dropdown overflow, focus ring, scroll clamping), **do not conclude the fix is absent based on CSS alone**. The actual fix may live in a JS event handler, a MutationObserver, or a lifecycle callback.

**Why:** Filed lucos_search_component#175 (shadow DOM column-overflow CSS missing from `mainStyle`) as a false positive. The real fix was `isInMultiColumnLayout()` in a `dropdown_open` listener that switches `.ts-dropdown-content` to `position: fixed` at runtime. Reading `mainStyle` CSS and seeing no column-overflow rules was looking at the wrong code path entirely. Issue closed as duplicate of #171 (2026-05-27).

**How to apply:** Before filing an issue or requesting changes because a CSS fix is absent from a shadow-DOM component, grep for the symptom keyword (e.g. "column", "overflow", "fixed", "position") across the full JS source — not just the style block. Confirm the fix is genuinely absent before raising it.
