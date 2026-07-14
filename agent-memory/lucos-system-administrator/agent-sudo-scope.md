---
name: agent-sudo-scope
description: lucos-agent's sudo grant differs per host (apt-list-only on xwing/salvare, none at all on avalon) — OS/package upgrades always need lucas42
metadata:
  type: project
---

`lucos-agent`'s sudo grant is near-zero everywhere but **not identical across hosts** — verified per host via `sudo -n -l`, 2026-07-14, lucos_agent_coding_sandbox#95:
- **xwing, salvare**: `NOPASSWD: /usr/bin/apt list --upgradable` only.
- **avalon**: no sudo grant at all — `sudo -n -l` returns "a password is required" there too, same as every other invocation. (Plain `apt list --upgradable` works without sudo on avalon since it never needed root; that's why this gap wasn't obvious.)

Either way, every other `sudo` command — `apt upgrade`, a reboot, anything — prompts for an interactive password no agent has.

**Correction (2026-07-14, same day, caught by team-lead re-probing):** an earlier version of this note and of `references/ssh-production.md` wrongly generalised xwing/salvare's specific grant to avalon as "verified on all three" without having actually captured avalon's `sudo -n -l` output separately — it had only been tested with `sudo -n true`, a different (blanket) check. Both docs are now corrected to state each host's actually-observed result. Lesson: a "verified on {hosts}" claim must be backed by captured output *per host*, not inferred from a sibling on the same estate-wide playbook — see the added guidance in `references/ssh-production.md`.

**Why:** deliberate least-privilege boundary. Auto-applying kernel/Docker-engine upgrades unattended, going wrong on a host that's expensive to recover, would be a real blast-radius risk.

**Correction #2 (2026-07-14, same day): "remote-only Pis with no agent-reachable console" above was a wrong, unverified inference — don't repeat this reasoning shape.** Per lucas42 (lucos_agent_coding_sandbox#98): xwing and salvare are physically accessible; avalon is not. So the two Pi hosts are the *recoverable* ones and avalon — which has been auto-installing Debian kernels via `unattended-upgrade` since April 2024 with no carve-out — is the one with no physical recovery path. "Remote-only Pi → no console" sounded plausible and was never checked. Physical accessibility, hardware topology, and hosting arrangement are a distinct class of fact from command-output claims: there's no SSH probe that answers them, so they must be sourced from lucas42 directly or written down as explicitly unknown — see the added rule in `references/ssh-production.md`.

**How to apply:** any issue asking an agent to actually *apply* OS/package updates or reboot a host is structurally blocked — not a "shouldn't", a "can't". Don't attempt the privileged command and hit the password prompt as a surprise. Investigate, document a runbook (host order, expected downtime, verification steps), and hand it to lucas42 rather than trying to execute. This is now documented in `references/ssh-production.md` and `agents/sysadmin-ops-checks.md` Check 3, so future ops-check runs shouldn't route this class of work as agent-`Ready` again — if a future triage still does, correct it (per [[feedback_verify_permission_claims]]-style verification, not assumption).

Secondary finding from the same investigation: `unattended-upgrades` is running on all three hosts but its `Origins-Pattern` only matches `origin=Debian` — Docker's own apt repo (`download.docker.com`) and the Raspberry Pi Foundation's repo (`archive.raspberrypi.com`) both fall outside it, which is why Docker-stack packages (all hosts) and kernel/`libc6` (xwing, salvare) accumulate as a manual backlog even though vanilla Debian-origin packages are auto-patched. Widening the Origins-Pattern would itself need root, so it's the same blocked-on-lucas42 situation, not a separately fixable bug.
