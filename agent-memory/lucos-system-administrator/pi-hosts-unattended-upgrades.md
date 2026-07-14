---
name: pi-hosts-unattended-upgrades
description: lucos_agent_coding_sandbox/pi-hosts/ owns Pi host OS provisioning (unattended-upgrades, journald, sudoers); security-only restriction currently ineffective
metadata:
  type: project
---

`lucos_agent_coding_sandbox` isn't just Lima/agent-VM provisioning — it also has a `pi-hosts/` directory (`setup-unattended-upgrades.sh`, `setup-journald.sh`, README) that is the authoritative provisioning source for xwing/salvare host-level OS config, applied by `lucos_agent_coding_sandbox#22` (closing #21) on 2026-03-06. Any future issue about Pi host OS-level config (unattended-upgrades, journald, sudoers) belongs in this repo's `pi-hosts/`, not `lucos_firewall`, not a new repo, not `lucos`. Confirmed by diffing the script against live `/etc/apt/apt.conf.d/*` and `/etc/sudoers.d/*` on the hosts, not assumed.

**The "security-only" unattended-upgrades restriction on xwing/salvare (`51lucos-security-upgrades`, `Allowed-Origins: Debian:${CODENAME}-security`) is not actually effective as deployed** — found 2026-07-14 while investigating [[agent-sudo-scope]]'s follow-up, `lucos_agent_coding_sandbox#98`. `/usr/bin/unattended-upgrade`'s `get_allowed_origins()` concatenates `Allowed-Origins` entries with `Origins-Pattern` entries rather than letting one override the other. The stock `/etc/apt/apt.conf.d/50unattended-upgrades` file (still present, untouched, ships with the package) contributes an unrestricted `origin=Debian,codename=${distro_codename},label=Debian` pattern — i.e. all stable Debian packages, not just security ones. So routine Debian-origin packages are already being silently auto-upgraded on xwing and salvare, contrary to the #21/#22 design intent. avalon has no custom file at all and is fully on stock (unrestricted-Debian) behaviour.

**Origin labels confirmed via `Release` file inspection** (`grep '^Origin:\|^Label:' /var/lib/apt/lists/*Release`), not inferred from repo URLs: `deb.debian.org` → `Origin: Debian`; `download.docker.com` → `Origin: Docker`, `Label: Docker CE`; `archive.raspberrypi.com` → `Origin: Raspberry Pi Foundation`. None of `unattended-upgrades`' patterns (stock or custom) match Docker or RPi Foundation origins on any host, so those packages structurally never auto-upgrade — this is why #95's backlog exists.

**How to apply:** don't assume the documented intent of a provisioning script (security-only, in this case) matches its actual runtime effect — apt config keys can combine additively across files in ways that silently widen scope past what any single file states. Verify against the tool's actual source when the stakes are "what auto-applies unattended to production," same discipline as [[feedback_read_before_theorising]].
