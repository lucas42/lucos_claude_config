---
name: risk-unattended-upgrades-origin-scope
description: Production hosts (avalon/xwing/salvare) unattended-upgrades origin gaps and a live config drift bug — open decision pending lucas42, tracked on lucos_agent_coding_sandbox#98
metadata:
  type: project
---

## Status (as of 2026-07-14): open, awaiting lucas42's decision on lucos_agent_coding_sandbox#98

Investigation triggered by a secondary finding on lucos_agent_coding_sandbox#95 (pending OS/package backlog on avalon/xwing/salvare). lucas42 asked for lucos-security specifically. Full assessment posted: https://github.com/lucas42/lucos_agent_coding_sandbox/issues/98#issuecomment-4968445239

## Verified facts (directly observed via read-only SSH, not inferred)

- **avalon** is NOT Raspberry Pi hardware (x86_64, no `/proc/device-tree/model`, uses a local Debian mirror `mirror+file:/etc/apt/mirrors/debian.list`). No raspi packages exist there. Its only unattended-upgrades gap is Docker's origin (`download.docker.com`) — libc6 has zero backlog, confirming Debian-origin auto-patching works fine on this host.
- **xwing**: Raspberry Pi 3 Model B Plus, Debian 13 (trixie). No physical bootloader EEPROM (older model lacks it).
- **salvare**: Raspberry Pi 4 Model B, Debian 12 (bookworm) — already **oldstable** (one release behind xwing). Has a physical bootloader EEPROM.
- On xwing/salvare, `libc6`/`openssl` themselves are rebuilt and served by RPi Foundation (`archive.raspberrypi.com`, `+rptN`-suffixed versions via `apt-cache policy`), NOT vanilla Debian. So excluding that origin from unattended-upgrades excludes core security libraries too, not just kernel/firmware — the origin gap and the libc6/openssl backlog are the same problem on these two hosts.
- `download.docker.com` and `archive.raspberrypi.com` are both properly `Signed-By`-scoped (dedicated keyrings), not legacy apt-key global trust, on all hosts that use them.
- `daemon.json` has `live-restore: true` on all 3 hosts — Docker engine auto-upgrades won't kill running containers on daemon restart. Availability objection to auto-upgrading Docker packages is already handled.
- `Unattended-Upgrade::Automatic-Reboot` is `false` (default, not overridden) on all 3 hosts — a landed kernel package doesn't take effect until a reviewed reboot.
- **salvare has `rpi-eeprom-update.service` enabled** (`FIRMWARE_RELEASE_STATUS="default"`), with `rpi-eeprom` itself pending an apt bump at time of investigation. My understanding (not directly observed triggering) is this service reflashes the bootloader EEPROM automatically at next boot once the package updates — no confirmation step. A bad/interrupted flash is a physical-recovery scenario (jumper + second computer), not SSH-fixable. xwing has no EEPROM so doesn't share this exposure.

## Config drift bug (verified against actual source, not guessed) — [[policy-dev-prod-credential-containment]]-adjacent "silent scope broadening" pattern, worth checking for elsewhere

`51lucos-security-upgrades` (custom file, xwing/salvare only, from lucos_agent_coding_sandbox#21/#22) sets `Unattended-Upgrade::Allowed-Origins { "Debian:${codename}-security"; }` intending security-only auto-upgrades. But `/usr/bin/unattended-upgrade`'s `get_allowed_origins()` (verified by reading the actual installed source on xwing) calls `get_allowed_origins_legacy()` (parses `Allowed-Origins`) and then **appends** everything from `Origins-Pattern` on top — concatenation, not override. The stock `50unattended-upgrades` (present, unmodified, on all 3 hosts) has an unrestricted `origin=Debian,codename=${distro_codename},label=Debian` line. Net effect: **xwing and salvare have been auto-installing ALL routine (non-security) Debian-origin updates since the #21/#22 rollout, not just security patches — silent drift from the documented design intent, nobody consciously decided it.**

General lesson: when a custom `Allowed-Origins` restriction is layered on top of unattended-upgrades' stock config, check whether the stock `Origins-Pattern` file is also still active — it unions rather than gets overridden. Worth checking for on any other host that has a "security-only" unattended-upgrades customization.

## My recommendation (posted to #98, not yet actioned)

- Carve out `linux-image-*`, `linux-headers-*`, `linux-libc-dev`, `raspi-firmware`, `rpi-eeprom`, `firmware-*` into the existing (currently empty) `Package-Blacklist` stanza — don't auto-apply kernel/bootloader/firmware from RPi Foundation origin. Auto-apply the rest (where the libc6/openssl payoff is).
- Fix the security-only drift bug as its own finding/issue, not folded into the RPi Foundation decision — it's a bugfix restoring already-agreed behaviour, no new trust call needed.
- Docker's origin is lower-stakes (no bricking failure mode, live-restore mitigates) — fine to fold into the same tiering exercise.

## Open questions blocking implementation

1. Physical accessibility of xwing/salvare for hardware recovery if a kernel/EEPROM update goes bad — unknown, materially changes how conservative the carve-out needs to be.
2. Whether unattended-upgrades is actually succeeding on any of the 3 hosts today — **`lucos-agent` lacks `adm`/`systemd-journal` group membership on all 3 hosts, so `journalctl -u unattended-upgrades` / `apt-daily-upgrade.service` returns nothing and I can't distinguish "never ran" from "ran, I can't see it."** This is a standing limitation for any future investigation needing systemd journal visibility on production hosts — note it, don't re-discover it.
