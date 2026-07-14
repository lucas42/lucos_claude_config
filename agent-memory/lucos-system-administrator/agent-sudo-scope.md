---
name: agent-sudo-scope
description: lucos-agent's sudoers grant is apt-list-only on all production hosts — OS/package upgrades always need lucas42
metadata:
  type: project
---

`lucos-agent`'s sudoers entry on avalon, xwing, and salvare is `NOPASSWD: /usr/bin/apt list --upgradable` only (confirmed via `sudo -n -l`, 2026-07-14, lucos_agent_coding_sandbox#95). Every other `sudo` command — `apt upgrade`, a reboot, anything — prompts for an interactive password no agent has.

**Why:** deliberate least-privilege boundary. Auto-applying kernel/Docker-engine upgrades unattended on remote-only Pis with no agent-reachable console would be a real blast-radius risk.

**How to apply:** any issue asking an agent to actually *apply* OS/package updates or reboot a host is structurally blocked — not a "shouldn't", a "can't". Don't attempt the privileged command and hit the password prompt as a surprise. Investigate, document a runbook (host order, expected downtime, verification steps), and hand it to lucas42 rather than trying to execute. This is now documented in `references/ssh-production.md` and `agents/sysadmin-ops-checks.md` Check 3, so future ops-check runs shouldn't route this class of work as agent-`Ready` again — if a future triage still does, correct it (per [[feedback_verify_permission_claims]]-style verification, not assumption).

Secondary finding from the same investigation: `unattended-upgrades` is running on all three hosts but its `Origins-Pattern` only matches `origin=Debian` — Docker's own apt repo (`download.docker.com`) and the Raspberry Pi Foundation's repo (`archive.raspberrypi.com`) both fall outside it, which is why Docker-stack packages (all hosts) and kernel/`libc6` (xwing, salvare) accumulate as a manual backlog even though vanilla Debian-origin packages are auto-patched. Widening the Origins-Pattern would itself need root, so it's the same blocked-on-lucas42 situation, not a separately fixable bug.
