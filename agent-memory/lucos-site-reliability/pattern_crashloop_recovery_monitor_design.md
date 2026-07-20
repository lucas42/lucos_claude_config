---
name: pattern-crashloop-recovery-monitor-design
description: When building a Monitor watch for a crash-looping container to recover, bucket states and exclude the restart counter — or the fast loop self-DOSes the monitor and it gets auto-stopped, silently losing the watch
metadata:
  type: reference
---

**Context:** waiting for a crash-looping container to recover (e.g. after a fix lands), using a `Monitor` that polls `docker inspect` every 60s and emits on state change.

**The trap:** a fast crash loop cycles through many transient states per minute. Two things will make the monitor emit an event on nearly every poll, which trips the "too many events → auto-stopped" backstop and **silently loses your recovery watch** — the real failure, far worse than the noise:

1. **A monotonically-increasing counter in the change-detection key.** `RestartCount` ticks every loop iteration, so `key="$status|$health|$rc"` changes every poll → event per restart forever. Put the counter in the *payload* for context, never in the *key*.

2. **Tracking transient intermediate states verbatim.** Docker briefly marks a crash-looping container `running` with `health=starting` at the top of each restart, before the process exits. So the raw state flip-flops `restarting|unhealthy` ↔ `running|starting` and emits a pair each cycle. **`running` ≠ recovered** — a container past neither guard nor healthcheck can show `running` for a heartbeat.

**The fix — bucket every raw state into 3 meaningful classes, emit only on bucket change:**
- `down` = restarting, running|starting, running|unhealthy, exited, created (collapse ALL not-recovered states here)
- `up` = running AND health in {healthy, nohealth}
- `probe-fail` = ssh/inspect failed (report as its own state — silence there is indistinguishable from success)

Then require `up` across **3 consecutive polls** before declaring recovery (a `stable` counter reset by any non-`up` poll). Genuine recovery reaches `running|healthy` and holds; the momentary crash-loop `running` never survives 3 polls. You lose visibility of the recovery *onset* (the first `starting`), but you only act on *sustained* recovery anyway, so that's fine.

**Verify before acting on a promising event:** when the monitor (or a manual check) shows a state that *looks* like recovery, confirm the root cause is actually fixed (re-measure the key shape / re-fetch the thing that was broken) before firing the remediation. On 2026-07-20 a `running|starting` event on configy_sync looked like recovery; the key was still 36-char truncated and it was just the crash-loop artifact (restart #956).

**Grounding:** lucas42/lucos_creds#474, configy_sync crash-looped ~1140+ times over ~4h waiting on a credential write; monitor rebuilt twice before landing on the bucketed design. Related: [[feedback-healthcheck-depth-varies]], [[feedback-monitor-over-bg-bash-for-waits]], [[feedback-treat-empty-tool-output-as-unknown]].
