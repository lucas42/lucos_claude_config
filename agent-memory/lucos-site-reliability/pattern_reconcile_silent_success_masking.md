---
name: pattern-reconcile-silent-success-masking
description: media_metadata_api reconcile_tag_names reports schedule_tracker success on total eolas-fetch failure → green monitoring, zero work; eolas bulk endpoint at the 30s-timeout cliff post-migration
metadata:
  type: project
---

**`reconcile_tag_names` silently no-ops while monitoring stays green.** The daily/startup job fetches canonical names from eolas's bulk endpoint `/metadata/all/data/` via `fetchEolasNames` (`api/eolas.go`, 30s client timeout). Post-migration that endpoint sits at ~22–27s and intermittently tips >30s (no streaming — `time_starttransfer ≈ time_total`, so the "awaiting headers" timeout is effectively a deadline on the whole response). On timeout it resolves 0 names. **But `reconcileTagNamesWithFetchers` returns nil on best-effort fetch failure, so `reconcileTagNames` reports `success` to schedule_tracker regardless** (`api/reconcile.go:36`) → the `reconcile_tag_names` check stays green and the failure is invisible.

**Why it's load-bearing:** #278 (closed 2026-05-30) made the composer/producer save path best-effort (`BestEffortURIToName`) — saves store the eolas URI with an empty name and *defer* name population to this reconcile job. So when reconcile no-ops, eolas-backed tag names never backfill (composer/producer/memory/offence/theme_tune/soundtrack), user-visible as nameless tags in the manager UI and arachne export. Never self-heals.

**Why monitoring misses it twice:** (1) the silent-success masking above; (2) `uri-integrity` only checks URI *presence*, not name presence — URIs are set, only `tag.value` (the name) is empty.

**History / disposition:** eolas#283 (closed 2026-05-29) accepted the bulk-endpoint slowness as intended for async arachne ingestion (lucas42: do NOT optimise it) and left reconcile on it under "option (i), revisit only if staleness alerts keep firing." That trigger can never fire because of the silent success. The pre-decided fix (lucas42 in #283) is **option (ii): a batch-names endpoint on eolas (`POST /metadata/names`)** + switch reconcile to use it; plus a media_api observability guard (don't report success when requested>0 & resolved=0). Raised as lucos_media_metadata_api#302 (2026-05-31).

**Reusable lesson:** a best-effort batch job that reports `success` to schedule_tracker even when its core fetch resolved nothing is a silent monitoring blindspot. When auditing scheduled-job health, check the job's *output* (resolved/updated counts in logs), not just its green check. See also [[feedback_healthcheck_depth_varies]].

**Diagnostic commands** (avalon, read-only): `ssh avalon.s.l42.eu "docker logs --since 48h lucos_media_metadata_api 2>&1 | grep reconcileTagNames"` for `resolved=0`; time the endpoint from inside the container with its own creds: `docker exec lucos_media_metadata_api sh -c 'curl -s -o /dev/null -w "%{time_total}s %{http_code}\n" -H "Authorization: Bearer $KEY_LUCOS_EOLAS" "$EOLAS_ORIGIN/metadata/all/data/"'`.
