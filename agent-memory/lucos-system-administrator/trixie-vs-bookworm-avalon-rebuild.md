---
name: trixie-vs-bookworm-avalon-rebuild
description: Debian trixie (13) vs bookworm (12) facts checked for the 2026-09 avalon rebuild — Docker install, DSA removal, sudo-rs, no other sshd/sudoers/fstab changes
metadata:
  type: reference
---

Checked when avalon's 2026-09-14 disk-failure rebuild landed on trixie instead of the bookworm the runbook assumed (lucas42/lucos#296). Verified via WebFetch/WebSearch against current docs, not from training-data memory (cutoff predates trixie's release).

- **Docker Engine install**: `docs.docker.com/engine/install/debian/` explicitly lists trixie 13 as supported (alongside bookworm). No change needed to a bookworm-era install runbook.
- **OpenSSH 10.x (trixie) removes DSA support outright**, not just deprecates it — trixie release notes confirm. Reinforces (doesn't require changing) any existing "don't restore the DSA host key" instruction.
- **`sudo`/`visudo` unaffected.** Trixie also packages `sudo-rs` (Rust reimplementation) alongside it, but the traditional `sudo` remains the default; `sudo-rs`'s binaries are separately named (`sudo-rs`, `visudo-rs`) to avoid conflict. No syntax change to existing sudoers workflows.
- **No sshd_config directive changes, no swapfile/fstab syntax changes, no `daemon.json` schema changes** — all distro-version-independent.
- **Account UID/GID stability across a rebuild**: NOT guaranteed and doesn't need to be — see [[deploy-orb-creds-l42-eu-dual-dependency]]'s sibling finding (checked separately): no lucos service ties container identity to a host account's numeric UID via a compose `user:` directive. Plain `adduser` (matching lucas42's own habitual workflow) is sufficient; don't hand-pin UIDs/GIDs to match a rescued `/etc/passwd`.
- **OVH/Kimsufi trixie template**: confirmed uses cloud-init the same way bookworm's did (verified live post-rebuild: `hostnamectl`/accounts/sudoers/sshd_config all landed as expected without manual netplan/cloud-init intervention).
