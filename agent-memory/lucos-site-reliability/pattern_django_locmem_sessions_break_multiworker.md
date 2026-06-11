---
name: pattern-django-locmem-sessions-break-multiworker
description: Django cache-backed sessions on LocMemCache silently break (CSRF + login loops) the moment gunicorn runs >1 worker
metadata:
  type: project
---

Django `SESSION_ENGINE = django.contrib.sessions.backends.cache` + `LocMemCache` stores sessions in **per-process memory**. Harmless with `--workers 1` (one shared store); the moment gunicorn runs **≥2 workers**, each worker has its own session store and nginx has no session affinity → ~50% of follow-up requests hit a worker that never saw the session.

**Twin symptoms, one cause:** (1) `/accounts/login` **redirect loop** — login() writes session to worker A, redirect lands on worker B, `@login_required` bounces back to auth; the **same auth token loops** in the access log. (2) **CSRF** `Forbidden (CSRF token from POST incorrect.)` on POST — form GET rendered by one worker, POST lands on the other. `/_info` stays GREEN (its check is a worker-agnostic DB lookup) so monitoring never catches it.

**Why:** Verb. First hit lucos_contacts 2026-06-10 (lucos_contacts#733). Latent since the 2024 cache-session switch (commit 7259082, fixing DB session bloat); activated by PR #724 (`--workers 1`→`2`, deployed 2026-05-28, commit 13b0dde) mirroring lucos_eolas's worker bump.

**Fix lever:** one-liner in startup.sh `--workers 1 --threads 8` (threads share process memory → LocMem coherent; same 8 concurrent in-flight). Alt: shared `DatabaseCache` via existing Postgres (needs `createcachetable` + MAX_ENTRIES cap) if multi-process wanted. Reject Redis/Memcached container — too much infra for login sessions.

**How to apply:** when ANY Django service in the estate bumps gunicorn workers, grep its settings.py for `SESSION_ENGINE.*cache` + `LocMemCache` FIRST — that combo + multiworker = this bug. lucos_eolas is SAFE (default DB-backed sessions, shared via Postgres) — the distinguisher is whether sessions live in a per-process cache.
