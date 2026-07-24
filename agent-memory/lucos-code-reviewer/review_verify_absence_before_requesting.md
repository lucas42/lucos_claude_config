---
name: review-verify-absence-before-requesting
description: Before REQUEST_CHANGES for something specific being missing (a guard, a null check, a CSS rule), verify its absence in the raw file/full JS source — not just the diff, which can be stale or incomplete.
metadata:
  type: feedback
---

The GitHub PR files API can serve stale diff data that omits lines actually present in the commit. Verify with `curl -s "https://raw.githubusercontent.com/lucas42/{repo}/{sha}/{file}" | grep -A N "function"`.

Confirmed failure: lucos_notes PR #355 — diff omitted a `typeof path !== 'string'` guard already present in the file; would have been a false REQUEST_CHANGES.

**Shadow DOM / web components: check the full JS, not just the CSS.** See [[feedback-js-component-css-inspection]] — CSS (e.g. `mainStyle`) absence does not mean the fix is absent; it may live in a lifecycle/event handler (`dropdown_open`, etc.). Grep the full JS source before filing. Confirmed false positive: lucos_search_component#175 — filed a CSS-missing issue after reading only `mainStyle`; the real fix was `isInMultiColumnLayout()` switching to `position: fixed` at runtime in a JS listener. Closed as duplicate of #171 (also: search the repo's issues before filing a suspected-gap follow-up — a fix that "isn't where expected" may already be tracked in the issue that motivated the release).
