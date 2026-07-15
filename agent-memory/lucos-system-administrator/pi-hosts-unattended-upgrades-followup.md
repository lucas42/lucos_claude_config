---
name: pi-hosts-unattended-upgrades-followup
description: lucos_agent_coding_sandbox#98 tiering decision + the two implementation issues (#100, #101) filed from it, 2026-07-15
metadata:
  type: project
---

Follow-up to [[pi-hosts-unattended-upgrades]]. #98 (all four decisions settled 2026-07-15) spawned two implementation issues I filed and own (`pi-hosts/setup-unattended-upgrades.sh`):

- **lucas42/lucos_agent_coding_sandbox#100** — extend origin coverage to Docker (all 3 hosts) + Raspberry Pi Foundation (xwing/salvare only), `Package-Blacklist` stays empty, `Automatic-Reboot` stays false. Key gotcha for whoever implements: use `Origins-Pattern` with **origin-only** matching (`"origin=Docker"` / `"origin=Raspberry Pi Foundation"`) — a `${CODENAME}`-templated entry (mirroring the existing `Allowed-Origins` colon syntax) works for Docker by coincidence (its `a=` field equals the codename on every host checked) but silently fails for RPi Foundation, whose `a=` field is `stable`/`oldstable`, not the codename. Verified via `apt-cache policy` + reading `/usr/bin/unattended-upgrade`'s `match_whitelist_string` (comma-token AND, `fnmatch`, omitted tokens wildcard). avalon has **no** custom lucos apt config at all today — this issue is also avalon's first one (Docker-only, no RPi entry, not Pi hardware).
- **lucas42/lucos_agent_coding_sandbox#101** — stagger xwing/salvare's identical `apt-daily-upgrade.timer` (both stock `06:00 + RandomizedDelaySec=60m`) via a systemd override on one host (e.g. salvare → `12:00`), not by tuning `RandomizedDelaySec`. Justified with live evidence: both hosts' last runs were 28 seconds apart despite independent randomisation — proof the existing jitter doesn't produce real separation. Also corrected the "`Unattended-Upgrade::RandomSleep`" name floated during triage — no such config key exists in `unattended-upgrades`; the real mechanism is systemd's `RandomizedDelaySec`, already present and evidently insufficient alone.

**Why this file exists**: both issues required reading `/usr/bin/unattended-upgrade`'s source and cross-host `apt-cache policy` output to get the config syntax right before filing — don't re-derive this from scratch if picked up later; the `o=`/`a=`/`n=` table is in #100's body.

**How to apply**: when `/next` surfaces either issue, the design decisions are NOT open — #98 settled them. Only implementation-organisation choices (single script vs. host-conditional logic, which file) are left to the implementer.

**Board state (2026-07-15, per team-lead)**: #98 closed as the design record, both follow-ups linked from it. #100 = Ready/mine/**High** (inherited from #98 — it's the security-patching gap closure, since `libc6`/`openssl` on the Pi hosts are RPi-Foundation-built; positioned below lucos_photos#427 only). #101 = Ready/mine/Medium, independent of #100. Team-lead fixed a stray cross-reference in #101's body (it pointed at #98 where it meant #100 — the tiering issue, not the design record) — already corrected on the ticket, no action needed from me.
