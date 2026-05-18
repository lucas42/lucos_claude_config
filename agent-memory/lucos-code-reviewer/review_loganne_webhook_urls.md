---
name: review-loganne-webhook-urls
description: When reviewing PRs that add URLs to Loganne subscriber arrays, verify the hostname against the live /_info endpoint before approving
metadata:
  type: feedback
---

When a PR adds a URL to `src/webhooks-config.json` (or any Loganne webhook subscriber config), **verify the hostname resolves to the correct service** before approving.

**Why:** lucos_loganne PR #467 initially approved `https://media-metadata.l42.eu/webhooks` — which is `lucos_media_metadata_manager`, not `lucos_media_metadata_api`. The correct hostname is `media-api.l42.eu`. lucas42 caught it; required a second review round.

**How to apply:** For any new subscriber URL in a Loganne config PR, run:

```bash
curl -sf "https://{hostname}/_info" | jq '{system}'
```

Confirm the returned `system` matches what the PR claims the URL points to. Five seconds; prevents a wrong-service wiring that would silently deliver events nowhere useful.
