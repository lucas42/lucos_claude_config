---
name: review-read-full-function-error-handling
description: Before flagging missing error handling near changed lines, read the FULL function from the actual file — unchanged guard lines outside the diff context window can already cover the case.
metadata:
  type: feedback
---

If new code manipulates DOM/state inside async or cancellable operations, fetch the full surrounding function to check existing guards before raising a concern — the diff view's context window can hide a relevant `if` a few lines outside it.

Confirmed failure: lucos_media_metadata_manager PR #191 — raised a false REQUEST_CHANGES about a missing `AbortError` check; the check already existed at line 294 of the unchanged code, invisible in the diff.
