---
name: risk-unattended-upgrades-origin-scope
description: Production hosts (avalon/xwing/salvare) unattended-upgrades origin gaps — open decision pending lucas42, tracked on lucos_agent_coding_sandbox#98
metadata:
  type: project
---

## Status (as of 2026-07-14, updated after lucas42's first round of answers): open, awaiting remaining decisions on lucos_agent_coding_sandbox#98

**lucas42 has answered two of the original open questions — update priors accordingly:**
- **xwing and salvare ARE physically accessible; avalon is NOT.** This inverts the original risk-model assumption (conservatism was aimed at the "unreachable" Pi hosts, but they're the reachable ones — avalon, the unreachable one, isn't Pi hardware and takes no RPi-Foundation packages at all). Downgrades (doesn't eliminate) the kernel/firmware carve-out case generally, and specifically for salvare's EEPROM: worst case is now "on-site recovery job," not "host gone forever."
- **Security-only restriction will NOT be restored — the drift stays, deliberately, by choice.** "No need for security-only if it's been working well without." The follow-up issue both agents proposed for this is dead — do not file it.
- **Corroborating finding (team-lead, verified from `/var/log/apt/history.log`, world-readable, no privilege needed): avalon has auto-installed Debian kernels via unattended-upgrade since ~April 2024, 8+ upgrades, zero physical recovery path, no incidents reported.** Weak-but-real evidence that unattended kernel-class updates from a reputable vendor via mature tooling tend to work — but it's a Debian-kernel base rate, not RPi Foundation's, and "no incidents reported" isn't "confirmed no incidents."
- **Journal-visibility gap is resolved without any privilege grant**: `/var/log/apt/history.log` is world-readable on all 3 hosts and confirms `unattended-upgrades` is actively running and succeeding on all three (most recent runs 2026-07-12). The `adm`/`systemd-journal` limitation still stands for diagnosing *why* a silent systemd-level failure happened, but not for confirming the service runs at all. Follow-up filed narrowly as lucos_agent_coding_sandbox#99 for that residual gap.

**My answer on the EEPROM question specifically** (posted https://github.com/lucas42/lucos_agent_coding_sandbox/issues/98#issuecomment-4968772516): recommend keeping `rpi-eeprom` blacklisted even though salvare is accessible — not because it's unrecoverable (it isn't), but because EEPROM flash failure is a firmware-level failure needing the Pi Foundation's out-of-band recovery process (harder than a kernel rollback, which is fixable by pulling the SD card), the flash timing is unpredictable (lands at *whatever* reboot happens next), and the security-update urgency is lower than libc6/openssl. Framed as a proportionality call, not a hard line, given accessibility is confirmed — residual risk if lucas42 chooses to auto-apply anyway: occasional site visit with proper Pi recovery kit, at an unplanned time.

**Update 2026-07-15: lucas42 rejected the EEPROM carve-out and I revised the full tiering as a result.** He argued "awareness isn't review" — at this level of the stack nobody manually applying an update can actually judge whether it's safe, so the manual path only buys delay/batching, not safety, and he prefers small incremental auto-applies over a backlog. Decision 4 settled: `rpi-eeprom` auto-applies.

I ran that argument through the rest of the carve-out list rather than defend the original line, and **revised the recommendation to an empty `Package-Blacklist`** (posted https://github.com/lucas42/lucos_agent_coding_sandbox/issues/98#issuecomment-4977685674) — said plainly the original proposal was too broad:
- `raspi-firmware`: same review-value argument applies, AND its files live on the FAT `/boot/firmware` partition (software-level, SD-card-recoverable), not the EEPROM chip — groups with the kernel, not with `rpi-eeprom`. Move off blacklist.
- `linux-image-*`: same review-value argument, plus `Automatic-Reboot` staying `false` already gates "does it boot" behind a separate deliberate action regardless of how the package arrived — auto-applying the package removes no checkpoint. Recovery is SD-card-level, both Pi hosts now confirmed accessible. Checked estate-wide incident history (~50 reports in `lucos/docs/incidents/` + issue search) for any kernel-boot-failure, on any host, ever: **none found** — corroborates (not proves) the 27-upgrade avalon base rate. Move off blacklist.
- `linux-headers-*`/`linux-libc-dev`: never had a real risk premise — grouped in originally by name-pattern only, no boot-time role at all. Shouldn't have been on the list.
- `firmware-*` (WiFi/BT blobs): already the weakest case originally, unaffected by any of this.

**Net effect of the revised recommendation**: RPi Foundation + Docker origins auto-apply in full, no carve-outs. `Automatic-Reboot` staying `false` is the one mechanism still doing real safety work. Named one residual, orthogonal risk that survives the whole exchange: xwing/salvare share the same daily `apt-daily-upgrade.timer`, so a bad release could hit both in the same window — suggested staggering (e.g. `RandomSleep`) as a cheap, separable follow-up, not gating the tiering decision on it.

**Lesson for future tiering/carve-out recommendations**: when a "the human reviews it before applying" argument is used to justify a manual/deferred path, check whether that review actually happens in practice for this operator/context, not just whether it's theoretically possible. If it doesn't, the manual path is only buying delay and batching (a real cost), not safety — and the argument generalises to every package where the same is true, not just the one under discussion. Don't concede narrowly on the one item raised and leave the rest of a carve-out list standing on the same now-refuted premise.

**Update 2026-07-15 (same day): team-lead caught one overstatement and sharpened one risk — both checked, not just accepted.**

1. **Correction**: my "Automatic-Reboot applies uniformly regardless of tiering" line was wrong. It's a real checkpoint for `linux-image-*`/`raspi-firmware` (reboot-trigger risk identical whether the package arrived manually or unattended), but **not a checkpoint at all for `rpi-eeprom`** — `Automatic-Reboot` only governs whether unattended-upgrades itself schedules a reboot; `rpi-eeprom-update.service` runs on **every** boot regardless of cause, so the flash fires at whatever reboot happens next either way.

2. **`rpi-eeprom-update` has real power-loss protection on its default (SD-boot) mechanism — verified against the installed tool, not assumed.** Checked `/etc/default/rpi-eeprom-update` (only sets `FIRMWARE_RELEASE_STATUS`, no `RPI_EEPROM_USE_FLASHROM` override) plus the man page and script source on salvare directly. Two distinct update paths exist:
   - `RPI_EEPROM_USE_FLASHROM=1` (immediate SPI write) — NOT what's configured — carries the genuine "don't disconnect power" bricking risk, recoverable only via Raspberry Pi Imager's bootloader-restore feature.
   - **Default path (what salvare actually uses)**: stages `recovery.bin` + update image + SHA256 hash to the **boot partition** (ordinary filesystem write, safe to interrupt). Only at the *next* reboot does the Pi's ROM run `recovery.bin`, which does the actual flash and **only renames itself to `recovery.000` on success**. Tool's own comment: *"For SD boot (most common) this provides a rollback in the event of power loss."* An interrupted flash simply retries on the next boot from the same verified staged image rather than bricking.
   - Hedge: this is documentation/source-comment evidence, not an empirical power-loss test. Still meaningfully stronger than "presumably rare."
   - Also confirmed: xwing has no EEPROM at all (its own `rpi-eeprom-update` dry-run says so), so a "two-Pi correlated EEPROM corruption" scenario was never physically possible regardless of co-location/shared power.

**General lesson reinforced**: when a teammate flags something as explicitly unverified rather than asserting it, that's usually cheap to actually check (read the installed tool's source/man page) rather than answer from general/training knowledge — the concrete answer is almost always better than a hedge, and it was available here with one SSH session.

**Still open**: only lucas42's final sign-off remains. The correlated-apt-timing staggering suggestion stands on its own (unrelated to EEPROM); the EEPROM-specific power-loss follow-up has been dropped given the verified mechanism above.

## Original investigation (2026-07-14, before lucas42's answers)

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
