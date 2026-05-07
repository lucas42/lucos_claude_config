---
name: Re-scan all stranded webhooks before declaring cleanup done
description: When clearing a Loganne webhook-error-rate alert after a deploy-time bug, fresh-scan all failed events and verify the monitoring alert clears — don't retry only what your diagnosis snapshot saw.
type: feedback
---

# Rule

After deploying a fix for a code path that was generating webhook failures, **don't retry only the failed events you saw during diagnosis** — re-scan Loganne fresh, retry every event still in `webhooks.status === 'failure'`, and verify the monitoring alert actually clears before reporting done.

**Why:** While the buggy code was still live in production, *more* events of the same failure mode were almost certainly accumulating. Your diagnosis snapshot only captured the failed events present at one moment. By the time the fix is merged and deployed (often 30+ minutes later), there may be additional stranded events that didn't exist when you wrote up the issue. Loganne retries failed webhooks only once and then leaves them — so any failure not retried explicitly stays stranded indefinitely.

**How to apply:** When asked to clear a `webhook-error-rate` alert after a fix has shipped:

1. **Re-fetch** `/events?limit=500` and filter on `webhooks.status === 'failure'` (or any individual hook with `status: 'failure'`). Don't reuse the UUID list from your diagnosis comment.
2. **Retry every one** via `POST /events/{uuid}/retry-webhooks` (or the bulk endpoint, mind the 60s cooldown).
3. **Verify** loganne's own `/_info` now reports `webhook-error-rate: ok=true`.
4. **Poll** `monitoring.l42.eu/api/status` until the public alert clears (lucos_monitoring's poll interval is 60s, so usually within 1–2 minutes).
5. **Only then** report cleanup done.

If you retry only the events from your diagnosis snapshot, the monitoring alert may stay red — and that should be your cue to re-scan, not to wait or assume "delayed propagation".

**Caught 2026-05-07** during cleanup of lucas42/lucos_media_manager#249. PR #246 had been live for ~58 minutes (14:40Z deploy → 15:38Z fix-deploy). Two trackUpdated events failed during that window: one at 14:58Z (which I cited in the issue) and one at 15:17Z (which I missed). I retried only the first, and the alert didn't clear. Re-scan revealed the second; retried that too; alert cleared on the next monitoring poll. The 15:17Z event would have stayed stranded indefinitely if the monitoring alert hadn't been the trigger to look again.
