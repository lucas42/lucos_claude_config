---
name: csp-data-uri-img-src
description: CSS background-image data: URIs require img-src data: in CSP — style-src alone is not enough
metadata:
  type: project
---

CSS `background-image: url("data:...")` loads through `img-src` in CSP, not just `style-src`. A nonce-gated `<style>` block is allowed by `style-src 'nonce-...'`, but any `data:` URI images referenced inside that CSS are additionally checked against `img-src`.

If `img-src` only lists `'self'`, the background pattern renders silently as nothing — no console error in all browsers, no fallback.

**Fix:** add `data:` to `img-src`: `img-src 'self' data:`

**Why:** Discovered on lucos_aithne PR #88 (issue #78, 2026-06-12). The SVG tiled key-icon background pattern used data URIs in CSS; the existing `img-src 'self'` policy blocked them.

**How to apply:** Any time a lucos service uses CSS `background-image` with a data URI on a page that has a strict CSP (default-src 'none' or explicit img-src), check that `img-src` includes `data:`. Applies to `background-image`, `list-style-image`, `border-image`, and `content` image values in CSS.
