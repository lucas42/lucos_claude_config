---
name: Sample webhook error distribution before bulk-retrying
description: Before triggering POST /events/retry-webhooks, sample the errorMessage distribution across stranded events — initial transient-looking errors (504, Gateway Time-out) often mask permanent data-quality failures
type: feedback
---

Before calling `POST /events/retry-webhooks` (or per-UUID retries) on stranded loganne events, **always sample the distribution of `e.webhooks.errorMessage` across the failure set first**. Don't assume transient-looking errors (504, Gateway Time-out) mean the failures are load-related and will succeed on retry.

```python
from collections import Counter
errs = Counter()
for e in events:
    if isinstance(e, dict) and e.get('webhooks',{}).get('status') == 'failure':
        errs[e['webhooks'].get('errorMessage','')[:120]] += 1
for em, n in errs.most_common(): print(f'  [{n:3d}] {em}')
```

**Why:** On 2026-05-07 lucas42 ran `load_language_families` on eolas. Loganne ended up with 115 stranded webhooks. I saw 42 had "Gateway Time-out" and assumed they were burst-overload that would clear on calm retry. Per-UUID retries with 1s spacing showed: ALL 42 converted to permanent validator failures (`Source RDF does not include a label for <X>` — arachne#371 validator). The 504s were just `id.loc.gov` being slow under burst, masking that the URL was structurally wrong (eolas's `LanguageFamily.get_absolute_url()` returns the external LoC URI, so arachne was fetching LoC's RDF instead of eolas's). 0 of 113 stranded events were recoverable without a structural fix.

**How to apply:** Whenever the loganne `webhook-error-rate` alert fires:

1. Fetch `/events?limit=500` with the loganne API key.
2. Build the error-message Counter from `e.webhooks.errorMessage` across all `status: failure` events.
3. Look at the top 3-5 distinct messages. If you see *any* permanent-looking error (validator failures, 4xx with structured bodies, "Source RDF does not include..."), file an issue first — do not trigger bulk retry.
4. If the distribution is genuinely all transient (502/503/504/network errors, no permanent ones mixed in), then bulk retry is appropriate. But still pace it (per-UUID with 1s delays) if the receiver was the original bottleneck — the bulk endpoint hits all subscribers in parallel and will re-create the original burst.

**Calibration cue:** distinct error messages = distinct root causes. A single error string repeated 100 times is one bug; 5 different error strings is 5 (or more) different things going wrong, and bulk retry will only help with the genuinely-transient subset.
