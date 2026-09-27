---
name: lucos-media-seinn-test-tag-stored-xss-fp
description: js/stored-xss false positive on lucos_media_seinn tests/web-components.js — document.createElement(tag) fed from local dir listing, not external input
metadata:
  type: reference
---

CodeQL `js/stored-xss` fired on `tests/web-components.js:82` (`lucos_media_seinn`), flagging `document.createElement(tag)` as a stored-XSS sink. `tag` comes from `fs.readdirSync()` of the repo's own `src/client/components` directory (test-only file, CodeQL classifies it `test`), filtered by a strict custom-element-name regex before use. No external/attacker-controlled data reaches this sink — only someone with repo commit access could influence it, at which point this line isn't the meaningful control.

Dismissed as false positive 2026-09-27, tracked/closed via lucas42/lucos_media_seinn#636 (`not_planned`).

This is a **different** false-positive pattern from [[lucos-aithne-oidc-url-redirect-fp]]-style `isSafeRedirectPath` recurrences in this same repo (different rule: `js/server-side-unvalidated-url-redirection` vs `js/stored-xss`, different file: `v3.js` vs `tests/web-components.js`). If this exact alert re-fires on `tests/web-components.js` after an AST shift, the same reasoning applies — check the source is still local-dir-listing-only before re-dismissing.
