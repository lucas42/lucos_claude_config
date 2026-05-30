---
name: copy-error-retry-guidance
description: Error messages should explicitly signal retry/no-retry intent, not just describe what went wrong
metadata:
  type: feedback
---

When writing error copy for failures that have a clear retry/no-retry answer, make that explicit in the message — don't leave the user guessing whether refreshing will help.

- **"Our bug" errors** (e.g. we sent a request the API correctly rejected → manager 500): add "Retrying is unlikely to help." Without this, users will retry the same failing action indefinitely.
- **Transient downstream errors** (e.g. service unreachable → manager 502): add "Try again in a moment." or equivalent. The retry instruction is the useful part.

**Why:** Established during lucos_media_metadata_manager #311/#316 review. "Something went wrong saving this change." without retry guidance is technically accurate but leaves the user in limbo. The retry signal is what the message is *for*.

**How to apply:** Any error message on a lucos UI that has a known persistence characteristic (permanent until fixed vs. transient) should include an explicit retry or no-retry line. Keep it short — one sentence appended to the main message is enough.

Also: human-readable error prose belongs in `<p>`, not `<pre>`. Reserve `<pre>` for technical detail (raw API reasons, stack fragments). If both are present, split them into separate elements — prose in `<p>`, technical in `<pre>` below it.
