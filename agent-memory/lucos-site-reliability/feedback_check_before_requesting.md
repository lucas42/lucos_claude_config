---
name: Test an endpoint before filing a feature request
description: Don't file issues requesting functionality without first checking whether it already exists
type: feedback
---

**Rule:** Before filing a GitHub issue requesting a new API endpoint, flag, CLI option, etc., check that it doesn't already exist. For an HTTP API, the cheapest check is `curl -X <METHOD> <URL>` — a `405 Method Not Allowed` or `404 Not Found` tells you it's missing; a `204`, `200`, etc. tells you it's there. For a CLI, check `--help` / `man`. For a library, grep the source.

**Why:** Filed lucas42/lucos_schedule_tracker#57 on 2026-04-19 requesting a `DELETE /api/jobs/{name}` endpoint to clean up stale schedule entries. The endpoint already existed (as `DELETE /schedule/{system}`) — shipped in PR #56 merged 2026-04-18, the day before. Triaging agents, reviewers, and the dispatcher all had to spend time on a duplicate request before anyone ran the one-line `curl` that would have answered the question. Closed as `completed` with apologies.

**How to apply:**
- During ops checks, when you identify "X is missing, needs new endpoint/flag", run the one-line probe before opening the issue — even if the probe seems silly.
- When investigating a system and you see a feature you'd expect to exist: `ls ~/sandboxes/<repo>/src/` or grep for keywords before concluding it's missing.
- If you do file a request and later find the feature existed, the closing comment should be self-critical and explicit ("I missed it when filing") — makes the failure traceable and discourages the same mistake from recurring.
