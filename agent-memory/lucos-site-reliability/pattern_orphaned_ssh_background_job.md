---
name: pattern-orphaned-ssh-background-job
description: An agent's `ssh host "... & ..."` one-liner can orphan a bash process that spins at 100% CPU for months — nothing in lucos alerts on it
metadata:
  type: pattern
---

# Orphaned agent SSH background jobs burn CPU indefinitely, silently

Found 2026-08-08 on avalon: PID 985893, user `lucos-agent`, PPID 1, **108 days elapsed / 107 days of CPU time, pinned at 99.7%** — a quarter of a 4-core host, since 2026-04-22. Command was an agent diagnostic one-liner:

```
bash -c 'docker run --rm -v … & sleep 3 kill %1 2>/dev/null wait 2>/dev/null'
```

Note the missing `;`/newlines: `kill %1` and `wait` became *arguments to `sleep`*, so nothing ever reaped the background job. Its `docker` child was left `<defunct>`.

**Why nothing caught it for 108 days:** host CPU is not a lucos monitoring check; a runaway `bash` is not a container crash (so sysadmin crash detection misses it); load average sat at ~2.6/4 which looks unremarkable. It only surfaced because I ran `top` while chasing an unrelated latency problem. Killing it dropped 1-min load 2.60 → 1.21 immediately.

**How to catch it:** one command on every SSH visit —
`ps -eo pid,etimes,time,%cpu,args --sort=-%cpu | head -5`. Anything with `%cpu` near 100 and `etimes` in the millions is litter.

**Prevention** is now in `~/.claude/references/ssh-production.md` (§Connecting via SSH): never `&` inside an `ssh host "…"` one-liner; use foreground + `timeout N`, or separate `ssh` invocations.

Killing an orphan like this is safe minimal intervention (PPID 1, no terminal, output pipeline long gone) — but capture a monitoring baseline first and re-check after, per `agents/workflows/production-change-verification.md`.
