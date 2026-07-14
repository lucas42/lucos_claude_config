---
name: pattern-ratelimit-maxwait-ceiling-reds-background-jobs
description: lucos_repos discards GitHub's Retry-After above a 5m ceiling calibrated for live paths — the 6h background sweep inherited it and reds; #462 already fixed the identical bug for the dry-run path
metadata:
  type: project
---

**`lucos_repos` audit sweep redding with `sweep incomplete: N convention check(s) skipped due to API errors` = we were TOLD when to retry and threw it away.**

`conventions/ratelimit_transport.go` parses GitHub's `Retry-After` (secondary/abuse limit) and `X-RateLimit-Reset` (primary points limit), then:

```go
const rateLimitMaxWait = 5 * time.Minute
...
if wait > maxWait { return nil, fmt.Errorf("GitHub rate limit exceeded; wait %s exceeds %s max wait: ...") }
```

That 5m ceiling is calibrated for **live request-serving paths**. The scheduled sweep silently inherited it despite being a background job on a 6h ticker with **no caller blocked on it** — and `TriggerSweep()` refuses to start a concurrent sweep, so a sweep that sleeps is harmless.

**The precedent is already in-repo: #462 fixed this exact bug for the sibling dry-run path** (`src/cmd_audit.go`):

```go
const auditDryRunMaxWaitDefault = 30 * time.Minute
const auditDryRunMaxWaitEnvVar = "AUDIT_DRYRUN_MAX_WAIT"
rateLimitTransport.MaxWait = dryRunMaxWait    // main pass
retryRateLimit.MaxWait = dryRunMaxWait        // retry-tail
```

Its own comment names "**the production sweep**" as one of the shared-quota consumers — then leaves that sweep on the 5m default. Primary-quota reset measured at **20-25 min**, hence 30m. Pinned fix for #465 (2026-07-14) = apply the same treatment to `src/audit.go`. `src/ratelimit.go` carries a *separate* 5m const for the issue-filing path — don't conflate; changing the `conventions` const would hit live paths, so set `MaxWait` on the sweep's own transports instead.

**Gotchas verified 2026-07-14:**
- `auditRetryTailDelay = 30 * time.Second` — the retry-tail is **useless against a rate-limit window** (30s later you're still limited). Don't credit it as a resilience layer for this failure mode; it only helps non-rate-limit transients.
- `skippedCount` does **NOT classify the error** (`if result.Err != nil` at `src/audit.go:381,420`) — a revoked token, dead network, and a rate-limit window all produce the identical `sweep incomplete` message. So any blanket "tolerate incompleteness" rule tolerates genuine breakage too. Raising `MaxWait` avoids this trap entirely: non-rate-limit 403s pass through `RateLimitTransport` unchanged and red at full speed.
- `RateLimitTransport` returns `(nil, err)` for rate limits (transport-level), and passes **non-rate-limit 403s through unchanged** so permission errors are handled normally.
- The rich `rateLimitDiagnostic()` (body + Retry-After + X-RateLimit-* headers, added by #433) goes to `slog.Warn` **only** — it does NOT reach the schedule-tracker message (that's just the skip count). So it dies with the container's log buffer. Grab it live or lose it — see [[pattern-container-restart-log-buffer-artifact]].

**Diagnostic order:** persisted Loganne `failingChecks[].debug` gives the skip count and its easing curve (54→10→0 = a rate-limit window easing). For *why*, you need the container logs' `Retry-After` values — check `StartedAt` first, they're usually gone.

See also [[pattern-lucos-repos-deploy-triggers-sweep]] (the ticker is anchored to container start — no clock slots), [[pattern-repos-audit-dryrun-secondary-ratelimit]].
